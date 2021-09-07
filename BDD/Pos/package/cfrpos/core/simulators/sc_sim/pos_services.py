"""This module contains base functions for POS testing."""
from typing import Optional

import datetime as dt
import zeep

from cfrpos.core.bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from cfrpos.core.bdd_utils.http_communicator import HTTPCommunicator
from cfrpos.core.bdd_utils.foreign import i64_to_f64, f64_to_i64
from cfrpos.core.bdd_utils.errors import ProductError
from . pos_service_constants import ShiftStatus


@wrap_all_methods_with_log_trace
class PosServiceHandler(HTTPCommunicator):

    def __init__(self, hostname: str = '127.0.0.1', port: int = 8900):
        super().__init__(hostname=hostname, port=port)
        self._wsdl_root = "POSServicesConfiguration"
        self._wsdls = {}

    def _lazy_wsdl(self, name: str) -> zeep.client.ServiceProxy:
        """
        Load WSDLs only when needed.

        :param name: WSDL file name.
        :return: SOAP service.
        """
        long_name = "{}/{}".format(self._wsdl_root, name)
        if long_name not in self._wsdls:
            self._wsdls[long_name] = self._make_soap_service(name)
        return self._wsdls[long_name]

    @property
    def _ps_bus_date(self) -> zeep.client.ServiceProxy:
        return self._lazy_wsdl("PSBusDate.PSBusDateSvcs.wsdl")

    @property
    def _ps_seq_nbr(self) -> zeep.client.ServiceProxy:
        return self._lazy_wsdl("PSSeqNbr.PSSeqNbrSvcs.wsdl")

    @property
    def _ps_shift_mgmt(self) -> zeep.client.ServiceProxy:
        return self._lazy_wsdl("PSShiftMgmt.PSShiftMgmtSvcs.wsdl")

    @property
    def _ps_tran_capture(self) -> zeep.client.ServiceProxy:
        return self._lazy_wsdl("PSTranCapture.PSTranCaptureSvcs.wsdl")

    def _make_soap_service(self, wsdl_name: str) -> zeep.client.ServiceProxy:
        """Create a SOAP service from a WSDL.

        :param wsdl: WSDL file name
        :return: SOAP service for given WSDL
        """
        # "POSServices" could be used for both URLs on a production SC,
        # but the POS SC sim needs some special handling.
        url_template = self.base_url + "/{}/" + wsdl_name
        client_url = url_template.format(self._wsdl_root)
        service_url = url_template.format("POSServices")

        client = zeep.Client(client_url)
        wsdl_parts = wsdl_name.rsplit('.', 2)
        binding = '{http://tempuri.org/wsdl/}' + wsdl_parts[1] + 'SoapBinding'
        return client.create_service(binding, service_url)

    def _expand_soap_url(self, suffix: str) -> str:
        """Get the full URL for a given suffix.

        :param suffix: New text to append to the base URL
        :return: Full URL
        """

        return self._soap_base_url.strip("/") + "/" + suffix.strip("/")

    def _validate_soap_response_result(self, response: dict) -> None:
        """Validate a full JSON response as successful.

        :param response: SOAP response containing a "Result" key
        """

        # Response is custom type, not dict, so have to check for keys with `in`.
        result = response["Result"]
        result_msg = response["pResultMsg"] if "pResultMsg" in response else ""

        if result != 0:
            message = "Site controller returned error {}: '{}'"
            raise ProductError(message.format(result, result_msg), name=self)

    def _validate_soap_response_result_int(self, response: int) -> None:
        """Validate an integer-only response as successful.

        :param response: SOAP response
        """

        if response != 0:
            message = "Site controller returned error {}".format(response)
            raise ProductError(message, name=self)

    @staticmethod
    def _business_day_to_ordinal(day: dt.datetime) -> int:
        return day.toordinal() - dt.datetime(1899, 12, 30).toordinal()

    @staticmethod
    def _business_day_from_ordinal(day: int) -> dt.datetime:
        return dt.datetime.fromordinal(day + dt.datetime(1899, 12, 30).toordinal())

    def get_current_business_day(self) -> Optional[dt.datetime]:
        """Get current business day.

        :return: Current business day or None
        """

        response = self._ps_bus_date.GetBusinessDate(BusDate=0)
        if response["Result"] == 2000 and response["BusDate"] == 0.0:
            return None
        else:
            self._validate_soap_response_result(response)
            return self._business_day_from_ordinal(int(response["BusDate"]))

    def get_pos_operator(self, node: int) -> int:
        """
        Get POS operator ID.

        :param node: Number number on which to find the operator.
        :return: Operator ID.
        """
        response = self._ps_shift_mgmt.GetPosOperator(TerminalId=node, PosOper=0)
        self._validate_soap_response_result(response)
        return f64_to_i64(response["PosOper"])

    def get_operator_shift_number(self, operator: int, day: dt.datetime) -> int:
        """
        Get operator shift number.

        :param operator: ID of the operator whose shift to find.
        :param day: Business day.
        :return: Shift number.
        """
        response = self._ps_shift_mgmt.GetOperatorShiftNumber(
            OperatorId=i64_to_f64(operator),
            BusinessDate=self._business_day_to_ordinal(day),
            ShiftNum=0
        )
        self._validate_soap_response_result(response)
        return response["ShiftNum"]

    def set_operator_status(self, operator: int, day: dt.datetime, shift: int, status: ShiftStatus, node: int) -> None:
        """
        Set operator shift status.

        :param operator: Operator ID.
        :param day: Business day.
        :param shift: Operator's shift ID.
        :param status: Status to set.
        :param node: Node number where the status will be set.
        """
        response = self._ps_shift_mgmt.SetOperatorStatus(
            OperatorId=i64_to_f64(operator),
            BusinessDate=self._business_day_to_ordinal(day),
            ShiftId=shift,
            Status=status.value,
            TerminalId=node
        )
        self._validate_soap_response_result_int(response)

@wrap_all_methods_with_log_trace
class PosPesServiceHandler(HTTPCommunicator):

    def __init__(self, hostname: str = '127.0.0.1', port: int = 8000):
        super().__init__(hostname=hostname, port=port)

    def get_pes_configuration(self):
        return self.get('/api/v1/configuration/hosts/NEP', validate_response_result=False)

    def set_pes_configuration(self, json: dict):
        return self.post('/api/v1/configuration/hosts/NEP', json=json)

    def reset_pes_configuration(self):
        return self.get('/api/v1/configuration/hosts/NEP/Reset')