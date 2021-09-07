"""This module contains base functions for POS testing."""
__all__ = [
    "POSControl"
]


from typing import Union, Optional
import subprocess
import os

from .. bdd_utils.errors import ProductError, NetworkError
from .. bdd_utils.logging_utils import get_ev_logger, wrap_all_methods_with_log_trace
from . transaction import Transaction, TransactionItem
from . pos_communicator import POSCommunicator
from . user_interface import *
from . ui_metadata import POSButton, POSFrame


logger = get_ev_logger()


class RelayFileSendResult:
    def __init__(self, reboot_required: bool = False, config_present_already: bool = True):
        self.reboot_required = reboot_required
        self.config_present_already = config_present_already


@wrap_all_methods_with_log_trace
class POSControl:
    """
    This class contains functions for POS control through REST API.
    This is class is meant only for internal use only. It should not be accessed by steps.
    """

    def __init__(self, node_number: int = 1, comm: POSCommunicator = None):
        """
        Initializes instance of PosControl class. If POSCommunicator argument is None PosControl will automatically
        create a new instance of POSCommunicator class. If POSCommunicator is not None
        then PosControl uses the value, but does not take ownership of it.
        :param int node_number: Number of POS
        :param comm: Optional POSCommunicator instance.
        """

        self.number = node_number
        self._comm = comm

    def __str__(self) -> str:
        """
        Return string description.
        """
        return "POS '{}'".format(self.number)

    def is_active(self, timeout: float = 10) -> bool:
        """
        Checks whether POS BDD interface is active.
        :param float timeout: Timeout in seconds
        :return: True, if the POScontrol is able to communicate with POS
        """
        try:
            response = self._comm.get_state(timeout)
            return response.get('Result', 'Failed') == 'Success'
        except ProductError as product_error:
            logger.debug("ProductError: '{0}'".format(product_error))
            return False

    def start_binary(self, bin_dir: str, environment: dict, bin_name: str = 'POSEngine.exe') -> None:
        """
        Method to start the POSEngine binary if required.

        :param bin_dir: The directory with binaries
        :param environment: Dictionary with the environmental variables
        :param bin_name: The binary which should be started
        """
        logger.debug('Starting binary {} from directory {}.'.format(bin_name, bin_dir))
        os.chdir(bin_dir)
        info = subprocess.STARTUPINFO()
        info.dwFlags = subprocess.STARTF_USESHOWWINDOW
        process = subprocess.Popen([bin_name], cwd=bin_dir, startupinfo=info, env=environment)
        if process is not None:
            del process

    def get_menu_frame(self) -> MenuFrame:
        """
        Retrieves menu frame.
        :return: New instance of MenuFrame
        """
        return self._get_frame("menu", MenuFrame)

    def get_menu_frame_after_processing(self) -> MenuFrame:
        """
        Retrieves menu frame after all temporary Credit/Loyalty processing frames close.
        :return: New instance of MenuFrame
        """
        frame = self.get_menu_frame()
        if frame.use_description == POSFrame.WAIT_CREDIT_PROCESSING.value or \
                frame.use_description == POSFrame.WAIT_PES_PROCESSING.value:
            self.wait_for_frame_close(frame)
            frame = self.get_menu_frame()
            
        while frame.use_description == POSFrame.WAIT_CREDIT_PROCESSING.value or \
                frame.use_description == POSFrame.WAIT_PES_PROCESSING.value:
            if frame.has_cancel():
                self.press_button(frame.instance_id, POSButton.CANCEL.value)
            self.wait_for_frame_close(frame)
            frame = self.get_menu_frame()
        return frame


    def get_receipt_frame(self) -> ReceiptFrame:
        """
        Retrieves receipt frame.
        :return: New instance of ReceiptFrame
        """
        return self._get_frame("receipt", ReceiptFrame)

    def get_fuel_pumps_frame(self) -> FuelPumpsFrame:
        """
        Retrieves fuelpumps frame.
        :return: New instance of FuelPumpsFrame
        """
        return self._get_frame("fuelpumps", FuelPumpsFrame)

    def get_transaction(self, number: Union[int, str] = "current") -> Optional[Transaction]:
        """
        Retrieves transaction information
        :param number: Transaction number or "current" for the current transaction.
        :return: POS transaction or None if error or requested transaction number was not found.
        """
        function_name = "get_transaction"
        pos_tran = None
        try:
            tran_info = self._comm.get_transaction(number)
            if tran_info.get("Number", 0) == 0:
                pos_tran = None
            else:
                pos_tran = Transaction.from_xml(tran_info.get(
                    "TransactionXML", "<LHPersistentTran></LHPersistentTran>"))
        except ProductError as error:
            logger.error("'{0}': Unable to retrieve transaction '{1}'. Error: '{2}'".format(function_name, number, error))
        return pos_tran

    def wait_for_frame_close(self, frame: UiFrame, timeout: float = 10) -> bool:
        """
        Initiates waiting until the desired frame is closed.
        :param frame: Desired frame to be closed
        :param timeout: Maximum allowed wait time
        :return: True if the frame has been successfully closed
        """
        function_name = "wait_for_frame_close"
        closed = False

        if not isinstance(frame, UiFrame):
            raise ProductError("Unexpected frame type: '{0}'".format(type(frame)))

        try:
            self._comm.wait_for_frame_close(frame.instance_id, timeout)
            logger.debug("'{0}': Frame has closed. Instance: '{1}' (ap '{2}')".format(
                    function_name, frame.instance_id, frame.application_binding))
            closed = True
        except ProductError as error:
            logger.error("'{0}': Frame did not close within '{1:.3f}' seconds. InstanceId: '{2}'. Error: '{3}'".format(
                    function_name, timeout, frame.instance_id, error))
        return closed

    def wait_for_frame_open(self, frame: Union[POSFrame, str], timeout: float = 10) -> bool:
        """
        Initiates waiting until the desired frame is displayed.
        :param frame: Desired frame to be verified
        :param timeout: Maximum allowed wait time
        :return: True if the frame has been successfully opened
        """
        function_name = "wait_for_frame_open"
        opened = False

        if isinstance(frame, POSFrame):
            expected_frame = frame.value
        else:
            expected_frame = frame
        try:
            self._comm.wait_for_frame(expected_frame, timeout)
            logger.debug("'{0}': Frame \"{1}\" has opened.".format(function_name, expected_frame))
            opened = True
        except ProductError as error:
            frame = self.get_menu_frame()
            logger.error("'{0}': Requested frame {1} did not open in {2:.3f} seconds. Frame displayed instead: '{3}' - '{4}'".format(
                function_name, expected_frame, timeout, frame.name, getattr(frame, "use_description", "")))
        return opened

    def check_frame_title(self, frame_title: str):
        """
        Checks if the title of the current frame is the same as provided one.
        :param frame_title: Title of the frame to be checked if it is displayed.
        """
        frame = self.get_menu_frame()
        if frame.use_details['title'] == frame_title:
            return True
        else:
            return False

    def _get_frame(self, frame_type: str, class_type: type) -> Union[UiFrame, MenuFrame, ReceiptFrame, FuelPumpsFrame]:
        """
        Retrieves frame content.
        :param frame_type: Frame type.
        :param class_type: Desired frame class type
        :return: A newly created instance of class_type
        :exception: Throws ProductError if anything goes wrong.
        """
        function_name = "_get_frame"
        try:
            frame_data = self._comm.get_frame(frame_type=frame_type)
        except ProductError as error:
            raise ProductError("'{0}': Unable to get frame type: '{1}' content, Error: '{2}'".format(function_name, frame_type, error))
        if frame_data is None \
                or not isinstance(frame_data, dict) \
                or len(frame_data) == 0 \
                or frame_data.get("Frame", None) is None:
            raise ProductError("No frame was retrieved for the frame type {}.".format(frame_type))
        logger.debug("'{0}': Frame has been successfully retrieved. Type: '{1}' ({2}), Class name: '{3}'".format(
            function_name, frame_type, frame_data["Frame"].get("UseDescription", ""), class_type))

        try:
            frame = class_type()
            frame.parse(frame_data["Frame"])
            return frame

        except Exception as e:
            logger.exception(e)
            raise ProductError("Problem parsing retrieved frame '{0}' Error: '{1}''".format(frame_type, frame_data))

    def _convert_traninfo_to_transaction(self, tran_info: dict) -> Optional[Transaction]:
        """
        Converts received TranInfo XML element into Transaction.
        :param tran_info: TranInfo XML element
        :return: Extracted transaction
        :rtype: Transaction or None
        """
        if tran_info is None:
            return None
        elif tran_info.get("Number", 0) == 0:
            return Transaction.from_xml("<LHPersistentTran></LHPersistentTran>")
        else:
            return Transaction.from_xml(tran_info.get("TransactionXML", "<LHPersistentTran></LHPersistentTran>"))

    def wait_for_transaction_end(self, timeout: Optional[float] = 10) -> Optional[Transaction]:
        """
        Initiates waiting until a transaction ends.
        :param timeout: Maximum allowed wait time
        :return: Transaction which ended or None
        """
        function_name = "wait_for_transaction_end"
        pos_tran = None
        try:
            tran_info = self._comm.wait_for_transaction_end(timeout)
        except ProductError as error:
            logger.error("'{0}': Waiting for the transaction end failed, Error: '{1}'".format(function_name, error))
            result = "Failure"
        else:
            result = tran_info.get("Result", "Failure")
        if result == "Success":
            pos_tran = self._convert_traninfo_to_transaction(tran_info)
            logger.debug("Transaction '{0}' ended.".format(pos_tran.sequence_number))
        else:
            logger.error("Transaction did not end within {0:.3f} seconds.".format(timeout))

        return pos_tran

    def wait_for_complete_prepay_finalization(self, pump: int, amount: float, timeout: float = 10) -> bool:
        """
        Initiates waiting until a prepay finalization completes at the given pump.
        :param timeout: Maximum allowed wait time
        :param pump: Id of the pump
        :param amount: Fuel price of the prepay transaction.
        :return: True if prepay finalization completed
        """
        function_name = "wait_for_complete_prepay_finalization"
        try:
            result = self._comm.wait_for_complete_prepay_finalization(pump, amount, timeout).get("Result", "Failure")
        except ProductError as error:
            logger.error("'{0}': Waiting for the prepay finalization failed, Error: '{1}'".format(function_name, error))
            result = "Failure"
        if result == "Success":
            logger.debug("Prepay finalization has completed.")
            return True
        else:
            logger.error("Prepay finalization did not complete within '{0:.3f}' seconds.".format(timeout))
            return False

    def wait_for_refund_on_pump(self, pump: int, amount: float, timeout: float = 10):
        """
        Initiates waiting until pos button with the given id displays the given amount.
        :param timeout: Maximum allowed wait time
        :param pump: Id of the pump
        :param amount: Amount to be refunded
        """
        function_name = "wait_for_refund_on_pump"
        try:
            result = self._comm.wait_for_refund_on_pump(pump, amount, timeout).get("Result", "Failure")
        except ProductError as error:
            logger.error("'{0}': Unable to get pump refund response, Error: '{1}'".format(function_name, error))
            result = "Failure"
        if result == "Success":
            logger.debug('Pump button {0} displayed refund amount {1}'.format(pump, amount))
            return True
        else:
            logger.debug('Pump button {0} did not display refund amount {1}'.format(pump, amount))
            return False

    def wait_for_pes_response(self, call_type: str, call_result: str, timeout: float) -> bool:
        """
        Initiates waiting until pos receives PES response with the given call type and result.

        :param call_type: PES call type, allowed values are: get, finalize, sync-finalize, void
        :param call_result: PES call result, allowed values are: success, offline, pending-action, voided, missing-credentials, process-error
        :param timeout: Timeout in seconds
        :return: True if specified PES response was received in time.
        """
        result = self._comm.wait_for_pes_response(call_type, call_result, timeout).get("Result", "Failure")
        if result == "Success":
            logger.debug('POS received PES response with call type {0} and call result {1}.'.format(call_type, call_result))
            return True
        else:
            logger.debug('POS did not received PES response with call type {0} and call result {1}.'.format(call_type, call_result))
            return False

    def press_button_on_frame(self, frame: Union[str, POSFrame], button: Union[str, POSButton], button_suffix: str = "") -> None:
        """
        Press a button on frame.
        :param frame: Frame which should contain the button.
        :param button: Button which should be pressed.
        :param button_suffix: The suffix which is appended to the button's name.
        """
        try:
            frame_id = self._comm.wait_for_frame(frame.value)["Frame"]["InstanceId"]
        except AttributeError:
            frame_id = self._comm.wait_for_frame(frame)["Frame"]["InstanceId"]
        try:
            self._comm.press_button(frame_id, button.value + button_suffix)
        except AttributeError:
            self._comm.press_button(frame_id, button + button_suffix)

    def press_button(self, instance_id: int, button: str) -> None:
        """
        Press a button.
        :param int instance_id: The instance id of the frame.
        :param str button: The value of a button.
        """
        function_name = "press_button"
        try:
            self._comm.press_button(instance_id, button)
        except ProductError as error:
            logger.error("'{0}': Unable to press a button: '{1}'. Error: '{2}'".format(function_name, button, error))

    def get_operator_info(self) -> dict:
        """
        Returning information about the current operator.
        """
        function_name = "get_operator_info"
        operator_info = {}
        try:
            operator_info = self._comm.get_operator()
        except ProductError as error:
            logger.error("'{0}': Unable to get operator info. Error: '{1}'".format(function_name, error))
        return operator_info

    def select_item(self, instance_id: int, list_item: int, only_highlighted: bool=False) -> None:
        """
        Select item in VR.
        :param instance_id: Id of an instance, where the item is going to be selected.
        :param list_item: Item number, which is going to be selected.
        :param only_highlighted: Force the item to be only marked as selected in UI.
        """
        function_name = "select_item"
        try:
            self._comm.select_item(instance_id=instance_id, list_item=list_item, only_highlighted=only_highlighted)
        except ProductError as error:
            logger.error("'{0}': Unable to select item with instance id: '{1}' in VR. Error: '{2}'".format(function_name, instance_id, error))

    def send_relay_files(self, relay_files: list) -> RelayFileSendResult:
        """
        Submit updated relay file configuration to POS, if any changes are pending.
        :param list relay_files: list of the relay files which should be sent to the POS.
        :return RelayFileSendResult: Result of sending a relay file.
        """
        function_name = "send_relay_files"
        result = RelayFileSendResult(reboot_required=False, config_present_already=True)
        for relay in relay_files:
            try:
                send_result = self._comm.send_relay(relay)
            except ValueError as error:
                raise ProductError("'{0}': Relay file name not found. '{1}'".format(function_name, error))
            except ProductError as error:
                raise ProductError("'{0}': Unable to send relay files, Error: '{1}'".format(function_name, error))
            if send_result.get("Result", "Failure") != "Success":
                raise ProductError("The result status of sending file: '{0}' was failure.".format(type(relay)))

            config_present_already = send_result.get("ConfigPresentAlready", False)
            result.config_present_already = result.config_present_already and config_present_already
            if relay.notify_applied() and not config_present_already:
                result.reboot_required = True
        return result

    def restart(self) -> None:
        """Restart the POS application."""
        function_name = "restart"
        try:
            self._comm.restart()
        except ProductError as error:
            logger.error("'{0}': Unable to restart the POS application. Error: '{1}'".format(function_name, error))

    def reload_config(self) -> None:
        """Reload configuration files not requiring a restart."""
        function_name = "reload_config"
        try:
            self._comm.reload_config()
        except ProductError as error:
            logger.error("'{0}': Unable to reload the configuration files. Error: '{1}'".format(function_name, error))

    def begin_waiting_for_event(self, event: str):
        """Prepare event trap for the event."""
        function_name = "begin_waiting_for_event"
        try:
            result = self._comm.begin_waiting_for_event(event).get("Result", "Failure")
            if result != "Success":
                raise ProductError("Unable to begin waiting for event: '{0}'.".format(event))
        except ProductError as error:
            logger.error("'{0}': Unable to set event-trap for the event: '{1}'. Error: '{2}'".format(function_name, event, error))

    def end_waiting_for_events(self):
        """Deactivate all event traps."""
        function_name = "end_waiting_for_events"
        try:
            self._comm.end_waiting_for_events()
        except ProductError as error:
            logger.error("'{0}': Unable to deactivate all event traps. Error: '{1}'".format(function_name, error))

    def begin_waiting_for_item_added(self):
        """Prepare waiting for added item."""
        self.begin_waiting_for_event('item-added')

    def wait_for_tender_added(self, tender_type: str, timeout: float, transaction_number: Union[int, str] = "current") -> None:
        """
        Initiates waiting until a tender is added to transaction.
        :param tender_type: Type of the tender.
        :param transaction_number: Transaction number or "current" for the current transaction.
        :param timeout: Maximum allowed wait time in seconds.
        """
        try:
            self._comm.wait_for_tender_added(tender_type=tender_type, transaction_number=transaction_number, timeout=timeout)
            logger.debug("Tender was added to the transaction.")
        except ProductError as error:
            logger.error("Tender was not added to transaction within '{0:.3f}' seconds. Error: '{1}'".format(timeout, error))

    def delete_all_stored_transactions(self) -> None:
        """
        Delete all stored transactions.
        :return: None
        """
        function_name = "delete_all_stored_transactions"
        try:
            self._comm.delete_all_stored_transactions()
        except ProductError as error:
            logger.error("'{0}': Unable to delete all stored transactions. Error: '{1}'".format(function_name, error))