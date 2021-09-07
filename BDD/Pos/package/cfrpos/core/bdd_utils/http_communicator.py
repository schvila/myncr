__all__ = [
    "HTTPCommunicator"
]

from typing import Union
import enum
import time
import json

import requests

from xml.etree import ElementTree
from . errors import NetworkError, ProductError
from . logging_utils import get_ev_logger, wrap_all_methods_with_log_trace

logger = get_ev_logger()


class HTTPVerbs(enum.Enum):
    GET = "get"
    POST = "post"
    PUT = "put"
    DELETE = "delete"
    PATCH = "patch"


@wrap_all_methods_with_log_trace
class HTTPCommunicator:
    """
    This class is the base HTTP communication layer that is used by each
    communication layer from EVCore to either EVAgent or a specific product.
    """

    def __init__(self, hostname, port=None):
        """
        :param str hostname: Hostname without protocol
        :param int port: Port number
        """
        if hostname.lower() == "localhost":
            self.hostname = "127.0.0.1"
        else:
            self.hostname = hostname
        self.port = port

        if self.port:
            self.base_url = "http://{}:{}/".format(self.hostname, self.port)
        else:
            self.base_url = "http://{}/".format(self.hostname)

    def __str__(self):
        return "{}({}, {})".format(type(self).__name__, self.hostname, self.port)

    def get(self,
             resource: str,
             *,
             query: dict = None,
             json: dict = None,
             body: Union[str, bytes] = None,
             timeout: Union[float, None]=None,
             validate_response_result: bool = True) -> dict:
        """Send a GET request.

        :param resource: Resource name to add onto base URL
        :param query: Parameters to specify in URL query
        :param json: JSON data to insert in body. Exclusive with `body` argument.
        :param body: Arbitrary data to insert in body. Exclusive with `json` argument.
        :param timeout: Timeout in seconds of the request. Use None for infinity.
        :return: JSON data response
        """

        function_name = "GET_request"
        get_response = {}
        try:
            get_response = self._request(HTTPVerbs.GET, resource, query=query, json=json, body=body, timeout=timeout, validate_response_result=validate_response_result)
        except Exception as error:
            message = "'{0}': Unable to send a GET request, occurred an error: '{1}'".format(function_name, error)
            raise ProductError(message, name=self)
        return get_response

    def post(self,
              resource: str,
              *,
              query: dict = None,
              json: dict = None,
              body: Union[str, bytes] = None,
              timeout: Union[float, None] = None,
              validate_response_result: bool = True) -> dict:
        """Send a POST request.

        :param resource: Resource name to add onto base URL
        :param query: Parameters to specify in URL query
        :param json: JSON data to insert in body. Exclusive with `body` argument.
        :param body: Arbitrary data to insert in body. Exclusive with `json` argument.
        :param timeout: Timeout in seconds of the request. Use None for infinity.
        :return: JSON data response
        """

        function_name = "POST_request"
        post_response = {}
        try:
            post_response = self._request(HTTPVerbs.POST, resource, query=query, json=json, body=body, timeout=timeout, validate_response_result=validate_response_result)
        except Exception as error:
            message = "'{0}': Unable to send a POST request, occurred an error: '{1}'".format(function_name, error)
            raise ProductError(message, name=self)
        return post_response

    def put(self,
              resource: str,
              *,
              query: dict = None,
              json: dict = None,
              body: Union[str, bytes] = None,
              timeout: Union[float, None]=None,
              validate_response_result: bool = True) -> dict:
        """Send a PUT request.

        :param resource: Resource name to add onto base URL
        :param query: Parameters to specify in URL query
        :param json: JSON data to insert in body. Exclusive with `body` argument.
        :param body: Arbitrary data to insert in body. Exclusive with `json` argument.
        :param timeout: Timeout in seconds of the request. Use None for infinity.
        :return: JSON data response
        """

        function_name = "PUT_request"
        put_response = {}
        try:
            put_response = self._request(HTTPVerbs.PUT, resource, query=query, json=json, body=body, timeout=timeout, validate_response_result=validate_response_result)
        except Exception as error:
            message = "'{0}': Unable to send a PUT request, occurred an error: '{1}'".format(function_name, error)
            raise ProductError(message, name=self)
        return put_response

    def delete(self,
              resource: str,
              *,
              query: dict = None,
              json: dict = None,
              body: Union[str, bytes] = None,
              timeout: Union[float, None]=None,
              validate_response_result: bool = True) -> dict:
        """Send a DELETE request.

        :param resource: Resource name to add onto base URL
        :param query: Parameters to specify in URL query
        :param json: JSON data to insert in body. Exclusive with `body` argument.
        :param body: Arbitrary data to insert in body. Exclusive with `json` argument.
        :param timeout: Timeout in seconds of the request. Use None for infinity.
        :return: JSON data response
        """

        function_name = "DELETE_request"
        delete_response = {}
        try:
            delete_response = self._request(HTTPVerbs.DELETE, resource, query=query, json=json, body=body, timeout=timeout, validate_response_result=validate_response_result)
        except Exception as error:
            message = "'{0}': Unable to send a DELETE request, occurred an error: '{1}'".format(function_name, error)
            raise ProductError(message, name=self)
        return delete_response

    def patch(self,
              resource: str,
              *,
              query: dict = None,
              json: dict = None,
              body: Union[str, bytes] = None,
              timeout: Union[float, None]=None,
              validate_response_result: bool = True) -> dict:
        """Send a PATCH request.

        :param resource: Resource name to add onto base URL
        :param query: Parameters to specify in URL query
        :param json: JSON data to insert in body. Exclusive with `body` argument.
        :param body: Arbitrary data to insert in body. Exclusive with `json` argument.
        :param timeout: Timeout in seconds of the request. Use None for infinity.
        :return: JSON data response
        """

        function_name = "PATCH_request"
        patch_response = {}
        try:
            patch_response = self._request(HTTPVerbs.PATCH, resource, query=query, json=json, body=body, timeout=timeout, validate_response_result=validate_response_result)
        except Exception as error:
            message = "'{0}': Unable to send a PATCH request, occurred an error: '{1}'".format(function_name, error)
            raise ProductError(message, name=self)
        return patch_response

    def _request(self,
                 verb: HTTPVerbs,
                 resource: str,
                 *,
                 query: dict = None,
                 json: dict = None,
                 body: Union[str, bytes] = None,
                 timeout: Union[float, None]=None,
                 validate_response_result: bool = True) -> dict:
        """Send an HTTP request.

        :param resource: Resource name to add onto base URL
        :param query: Parameters to specify in URL query
        :param json: JSON data to insert in body. Exclusive with `body` argument.
        :param body: Arbitrary data to insert in body. Exclusive with `json` argument.
        :param timeout: Timeout in seconds of the request. Use None for infinity.
        :return: JSON data response
        """

        if json is not None and body is not None:
            raise ValueError("Cannot set both `json` and `body` at the same time.")

        logger.debug("Sending request '{}'".format(self._expand_url(resource)))

        method = {
            HTTPVerbs.GET: requests.get,
            HTTPVerbs.POST: requests.post,
            HTTPVerbs.PUT: requests.put,
            HTTPVerbs.DELETE: requests.delete,
            HTTPVerbs.PATCH: requests.patch
        }[verb]

        start = time.perf_counter()

        try:
            response = method(url=self._expand_url(resource), params=query, json=json, data=body, timeout=timeout)
            duration = time.perf_counter() - start
            if duration > 0.5:
                logger.debug("Request '{0}' took {1:.3f} seconds.".format(resource, duration))
        except requests.exceptions.ConnectionError as error:
            duration = time.perf_counter() - start
            logger.error("Request '{0}' failed after {1:.3f} seconds with an error: {2}.".format(
                resource, duration, error))
            return {}
        except requests.exceptions.ReadTimeout as error:
            duration = time.perf_counter() - start
            logger.error("Request '{0}' timed out after {1:.3f} seconds with an error: {2}.".format(
                resource, duration, error))
            return {}

        self._validate_response(response, validate_response_result)

        content_type = response.headers.get('Content-Type', '')
        if 'application/xml' in content_type:
            return response
        else:
            if response.text != '':
                return response.json()

    def _validate_response(self, response, validate_response_result):
        """Verify that the response indicates a successful command.

        This calls the other validation methods so that you can selectively
        override whichever ones you need without overriding the entire set.

        :param requests.models.Response response: HTTP response
        :return: None
        """

        self._validate_response_code(response)
        if response.text != '':
            body = self._validate_response_body(response)
            if validate_response_result:
                self._validate_response_result(response, body)
        

    def _validate_response_body(self, response):
        """Validate the response's body.

        :param requests.models.Response response: HTTP response
        :return: Parsed JSON
        :rtype: dict
        """

        content_type = response.headers.get('Content-Type', '')
        if 'application/xml' in content_type:
            return self._check_response_status(response)
        else:
            try:
                # requests uses simplejson instead of json if available,
                # so need to catch either version of JSONDecodeError.
                return response.json()
            except ValueError as error:
                # json.decoder.JSONDecodeError
                # simplejson.scanner.JSONDecodeError
                message = "Could not parse JSON from response: {}"
                raise NetworkError(message.format(error), name=self)

    def _validate_response_code(self, response):
        """Validate the response's HTTP status code.

        :param requests.models.Response response: HTTP response
        :param dict body: Parsed JSON from body
        :return: None
        """

        content_type = response.headers.get('Content-Type', '')
        if response.status_code == 500:
            message = "Command failed with status {} and reason '{}'."
            message = message.format(response.status_code, response.reason)
            raise ProductError(message, name=self)
        if not (response.status_code == 200 and response.text != '') \
                and response.status_code != 204\
                and not (response.status_code == 404 and content_type == 'application/json'):
            message = "Command failed to execute with status {} and reason '{}'."
            message = message.format(response.status_code, response.reason)
            raise NetworkError(message, name=self)

    def _validate_response_result(self, response, body):
        """Validate the response's effective result.

        :param requests.models.Response response: HTTP response
        :param dict body: Parsed JSON from body
        :return: None
        """
        if response.status_code != 200 \
                or body["Result"].lower() != "success":
            message = "Command '{}' executed, but there was an error, response-status-code: '{}' Description: '{}'"
            message = message.format(response.url, response.status_code, body.get("ResultDescription", ""))
            raise ProductError(message, name=self)

    def _expand_url(self, suffix):
        """Get the full URL for a given suffix.

        :param str suffix: New text to append to the base URL
        :return: Full URL
        :rtype: str
        """

        return self.base_url.strip("/") + "/" + suffix.strip("/")

    def _check_response_status(self, response):
        """
        Check if the HTTP response contains a string confirming the request was processed.
        Temporary fix, until RPOS-18022 is done.

        :param parsed_parameters: Parsed parameters from xml response.
        """
        response_parameters = ElementTree.fromstring(response.content)
        for element in response_parameters.iter('*'):
            if 'responseStatus' in element.tag and element.text == 'OK':
                return {'Result':'success'}
            elif 'responseString' in element.tag and element.text == 'OK':
                return {'Result':'success'}
            elif 'string' in element.tag and element.text == 'OK':
                return {'Result':'success'}