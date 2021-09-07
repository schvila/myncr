__all__ = [
    "POSConnectClient"
]

import json
import time
import requests
from typing import Union
from cfrpos.core.bdd_utils.logging_utils import get_ev_logger
from cfrpos.core.bdd_utils.errors import ProductError
from requests.api import head
from . pos_connect_response import POSConnectResponse
from cfrpos.core.pos.pos_product import POSProduct
from cfrpos.core.pos.ui_metadata import POSFrame

logger = get_ev_logger()


class POSConnectClient:
    def __init__(self, config: dict, version: int=2):
        self._address = config.get('address', '127.0.0.1')
        self._port = config.get('port', 8080)
        self.headers = {'Content-Type': 'application/json'}
        if version == 3:
            self._url = 'http://{}:{}/api/v3/'.format(self._address, self._port)
            self.headers.update({'PosConnect-Client': '/rpossco'})
            self.version = 3
        else:
            self._url = 'http://{}:{}/rpossco'.format(self._address, self._port)
            self.version = 2
        self._last_response = POSConnectResponse(0)
        self.last_stored_tran_number = None

    def _post(self, data: str, timeout: float, request_id = "", message_name = "") -> Union[requests.Request, None]:
        start = time.perf_counter()
        try:
            headers = self.headers | {'PosConnect-RequestId': request_id} if request_id != "" else self.headers
            response = requests.post(url=self._url + message_name, data=data, timeout=timeout, headers=headers)
            duration = time.perf_counter() - start
            if duration > 0.5:
                logger.debug("_post: Request '{0}' took '{1:.3f}' seconds.".format(self._url, duration))
            return response
        except requests.exceptions.ConnectionError as error:
            duration = time.perf_counter() - start
            logger.error("_post: Request '{0}' failed after '{1:.3f}' seconds with an error: {2}.".format(
                    self._url + message_name, duration, error))
            return None
        except requests.exceptions.ReadTimeout as error:
            duration = time.perf_counter() - start
            logger.error("_post: Request '{0}' timed out after '{1:.3f}' seconds with an error: {2}.".format(
                    self._url + message_name, duration, error))
            return None

    def send_formatted_message(self, formatted_message: str, timeout: float=30, request_id = "", message_name = "") -> POSConnectResponse:
        """
        Send a formatted message to the POS Connect server.
        :param formatted_message: Message as serialized JSON.
        :param timeout: Timeout of the request in seconds.
        :param message_name: Message name (e.g. Pos/GetState) required as part of URI for posconnect v3, otherwise empty.
        :return: Decoded response.
        """
        self._last_response = POSConnectResponse(0)

        raw_response = self._post(formatted_message if formatted_message is not None else '', timeout, request_id, message_name)
        if raw_response is None:
            raise ProductError('Cannot connect to POS Connect')

        response = POSConnectResponse(raw_response.status_code)
        if raw_response.status_code == 200:
            content = None
            try:
                content = raw_response.json()
            except json.decoder.JSONDecodeError as e:
                raise ProductError('Decoding response as JSON failed with an error "{}" on content |{}|.'.format(
                        e, raw_response.text))

            assert self._validate_response_format(content, self.version)

            if self.version == 2:
                response.message = content[0]
                response.data = content[1]
            elif self.version == 3:
                response.data = content

        self._last_response = response
        return response

    def _validate_response_format(self, content: Union[list, dict], version: int=2) -> bool:
        """
        POS Connect v2 expects a list in the response, which contains the message name and a dictionary with the actual data.
        POS Connect v3 expects just the dictionary.
        :param content: Body of the response.
        :param version: Version of the POS Connect interface.
        """
        if version == 2:
            if not isinstance(content, list) \
                    or len(content) != 2 \
                    or not isinstance(content[0], str) \
                    or not isinstance(content[1], dict):
                raise ProductError('Unknown format of a response |{}| for version 2'.format(content))
        elif version == 3:
            if not isinstance(content, dict):
                raise ProductError('Unknown format of a response |{}| for version 3'.format(content))
        return True

    def send_message(self, message: str, data: dict, timeout: float=30) -> POSConnectResponse:
        """
        Send a POS Connect message to the POS Connect server.
        :param message: Message
        :param data: Message data (dictionary)
        :param timeout: Timeout of the message in seconds.
        :return: Decoded response.
        """
        if not message:
            raise ProductError('POS Connect message is empty')
        if data is not None and not isinstance(data, dict):
            raise ProductError('POS Connect data is not dictionary')

        return self.send_formatted_message(
            json.dumps([message, data if data is not None else {}]),
            timeout)

    def is_device_online(self, device: str) -> bool:
        """
        Gets the device's state.
        :param device: The device, where is checked the state.
        :return: The state of the device.
        """
        if self.last_response.code == 0 and self.last_response.message == "":
            raise ProductError('No request was sent to the POS Connect.')
        if not device:
            raise ProductError('Name of the device is empty.')
        device_states = self.last_response.data.get('DeviceStates')
        device_state = device_states.get(device)
        if device_state == None:
            raise ProductError('Device with name "{}" was not found'.format(device))
        device_online = device_state.get('IsOnline')
        if device_online == None:
            raise ProductError('Device with name "{}" has got no attribute "IsOnline".'.format(device))
        else:
            return device_online

    @property
    def last_response(self) -> POSConnectResponse:
        """
        Last received response of the POS Connect server.
        """
        return self._last_response

    def finalize_flow(self, pos: POSProduct):
        """
        We need to get rid of the DataNeeded POS Connect state after a test scenario finishes.
        If another scenario would begin afterwards and POS would try to get to the inital state, it would crash.
        """
        depth = 0
        max_depth = 2
        frame = pos.control.get_menu_frame()
        while frame.use_description != POSFrame.MAIN.value and self.last_response.message == 'Pos/DataNeeded' and depth < max_depth:
            if self.last_response.data.get('DataType').lower() == 'yesno':
                assert self.send_formatted_message(
                    "[\"Pos/DataNeededResponse\", {\"DataType\": \"YesNo\", \"YesNoData\": \"No\"}]") is not None
            else:
                assert self.send_formatted_message(
                    "[\"Pos/DataNeededResponse\", {\"SelectedOperationName\": \"Cancel\"}]") is not None
            depth =+ 1
            pos.control.wait_for_frame_open(POSFrame.MAIN, 5)
            frame = pos.control.get_menu_frame()

    def activate_version(self, version: int=3, address: str='127.0.0.1', port: int=8080) -> None:
        """
        Enables given version of POSConnect protocol by changing default headers and URI.
        """
        if version == 3:
            self._url = 'http://{}:{}/api/v3/'.format(address, port)
            self.headers = {'PosConnect-Client': '/rpossco', 'Content-Type': 'application/json'}
            self.version = 3
        elif version == 2:
            self._url = 'http://{}:{}/rpossco'.format(address, port)
            self.headers = {'Content-Type': 'application/json'}
            self.version = 2
        else:
            raise ProductError('Unknown/Unsupported POSConnect version: {}'.format(version))
