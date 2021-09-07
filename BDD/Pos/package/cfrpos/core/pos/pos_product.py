__all__ = [
    "POSProduct"
]

import time
import winreg
import math
import datetime
import json
import re
from win32 import win32crypt
import base64

from dateutil.relativedelta import relativedelta
from os import path, remove
from typing import Union, Optional
from enum import Enum
from .pos_control import POSControl
from .pos_communicator import POSCommunicator
from ..bdd_utils.errors import ProductError
from .item import ItemStatuses
from ..relay import RelayCatalog
from ..bdd_utils.logging_utils import get_ev_logger, wrap_all_methods_with_log_trace
from .transaction import Transaction, TransactionItem
from sim4cfrpos.api.scan_sim.scan_sim_control import ScanSimControl
from sim4cfrpos.api.swipe_sim.swipe_sim_control import SwipeSimControl
from sim4cfrpos.api.print_sim.print_sim_control import PrintSimControl
from sim4cfrpos.api.checkreader_sim.check_reader_control import CheckReaderSimControl
from cfrpos.core.simulators.sc_sim.pos_services_control import PosServicesControl
from .ui_metadata import POSButton, POSFrame
from .user_interface import UiRecallTransactionItem, UiScrollPreviousItem
from .. bdd_utils.performance_stats import PerformanceStats, PerfomanceCounter
from cfrpos.core.bdd_utils.timeouter import timeouter

logger = get_ev_logger()

POS_PRODUCT_DEFAULT_BIN_DIR = 'C:\\Program Files\\Radiant\\Fastpoint\\Bin'
POS_PRODUCT_DEFAULT_BINARY = 'PosEngine.exe'
POS_PRODUCT_DEFAULT_INITIAL_DATA_DIR = path.abspath(path.join(path.dirname(path.realpath(__file__)), '..', '..', '..', '..', 'config', 'data'))


class BarcodeInputMethod(Enum):
    MANUAL = "manual"
    SCAN = "scan"


class PosProductPerformance(PerformanceStats):
    def reset(self):
        self.sending_relay_files = PerfomanceCounter()
        self.rebooting = PerfomanceCounter()
        self.ensuring_ready_to_sell__verify_ready = PerfomanceCounter()
        self.ensuring_ready_to_sell__close_frame = PerfomanceCounter()
        self.ensuring_ready_to_sell__wait_for_main = PerfomanceCounter()
        self.ensuring_ready_to_sell__void_transaction = PerfomanceCounter()
        self.ensuring_ready_to_sell__clear_store_recall = PerfomanceCounter()
        self.ensuring_ready_to_sell__end_waiting_for_events = PerfomanceCounter()


@wrap_all_methods_with_log_trace
class POSProduct:
    """
    This class is the highest level abstraction of the product and
    should be used in test step implementations. Only this POS class
    is exposed to steps and should be used to operate POS.
    """

    def __init__(self, config: dict = {}, scanner: ScanSimControl = None,
                                          swiper: SwipeSimControl = None,
                                          printer: PrintSimControl = None,
                                          checkreader: CheckReaderSimControl = None,
                                          sc: PosServicesControl = None) -> None:
        """
        :param dict config: Configuration of POS.
        :param ScanSimControl scanner: The instance of the scanner control
        :param SwipeSimControl swiper: The instance of the swipe sim control
        :param CheckreaderSimControl checkreader: The instance of the checkreader sim control
        :param PrintSimControl printer: The instance of the print sim control
        """
        self._address = config.get('address', '127.0.0.1')
        self._port = config.get('port', 10000)
        self.node_number = config.get('node_number', 1)
        self._bin_dir = config.get('bin_dir', POS_PRODUCT_DEFAULT_BIN_DIR)
        self._binary = config.get('binary', POS_PRODUCT_DEFAULT_BINARY)
        self.comm = POSCommunicator(hostname=self._address, port=self._port)
        self._control = POSControl(node_number=self.node_number, comm=self.comm)
        self._scanner = scanner
        self._swiper = swiper
        self._checkreader = checkreader
        self._printer = printer
        self._sc = sc
        self._performance = PosProductPerformance()
        self.receipts_available = []
        self.receipt_sections = []
        self.rpos_env = config.get('rpos_env')
        self.relay_catalog = RelayCatalog(config.get('initial_data_dir', POS_PRODUCT_DEFAULT_INITIAL_DATA_DIR))
        self._pes_configuration_path = config.get('pes_configuration_path', 'C:\Program Files\Radiant\Fastpoint\data\DirectPes.json')

    @property
    def binary(self):
        """Name of the binary required by this controller."""
        return self._binary

    @property
    def bin_dir(self):
        """Name of the folder containing the required binary."""
        return self._bin_dir

    @property
    def control(self) -> POSControl:
        """
        Get used POSControl.

        :return: POS Control
        :rtype: POSControl
        """
        return self._control

    def is_active(self):
        return self._control.is_active()

    def _wait_for_availability(self, timeout: float = 45) -> bool:
        """
        Waits until the control is fully operable and able to communicate via API calls.

        :param float timeout: Timeout in seconds.
        :return: True, if the control was successfully started. False if the timeout occurred.
        :rtype: bool
        """
        started = False
        start = time.perf_counter()
        duration = 0
        active = self.control.is_active(timeout=0.5)
        while not active and duration < timeout:
            logger.info("Waiting for '{0}' to became active".format(str(self.control)))
            active = self.control.is_active(timeout=1)
            duration = time.perf_counter() - start
        duration = time.perf_counter() - start

        if not active:
            logger.warning("'{0}' did not became active in {1:.3f} seconds.".format(
                str(self.control), duration))
        else:
            logger.info("'{0}' is up and running (after {1:.3f} seconds).".format(
                str(self.control), duration))
            started = True

        return started

    def verify_ready(self) -> None:
        """
        Verifies that POS and all required controls are ready to operate.

        :return: Nothing
        :raises: ProductError if the POSEngine is not ready
        """
        if not self._wait_for_availability():
            logger.warning("Communication with '{0}' cannot be established, attempting to run POSEngine again.".format(
                str(self.control)))
            self.start(self.rpos_env)
            if not self._wait_for_availability():
                logger.error("Communication with '{0}' cannot be established, the tests execution aborted.".format(
                    str(self.control)))
                raise KeyboardInterrupt()

    def start(self, environment: dict):
        """
        Method to start the POSEngine binary if required.

        :param environment: Dictionary with the environmental variables
        """
        self.control.start_binary(self._bin_dir, environment, self._binary)
        self._wait_for_availability()

    def tender_transaction(self, tender_type: str = "cash", external_id: str = '70000000023', amount:
                        Union[float, str] = "exact_dollar", check_name: str = '', tender_group_id: str = None) -> None:
        """
        Tender the current transaction with the given tender type and amount.
        If no parameters are given, it will tender exact dollar with cash.

        :param tender_type: Tender type of the desired tender. Type can be cash, credit etc..
        :param external_id: External ID of the desired tender.
        :param amount: An amount to tender.
        :param check_name: Name of the check.
        :tender_group_id: ID of a tender group if a given tender is a member of one, otherwise None
        ** Usage: **
        Start a transaction and add an item to it
        >>> pos = POSProduct()
        >>> pos.tender_transaction(tender_type="cash", external_id='')
        """
        frame = self._control.get_menu_frame()
        if frame.name == 'common-yes/no':
            self._control.press_button(frame.instance_id, POSButton.NO.value)
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()
        if frame.use_description != POSFrame.MAIN.value:
            raise ProductError('The main frame is not displayed. The displayed frame is "{}".'.format(frame.name))
        if self.get_current_transaction() is None:
            raise ProductError('There is no active transaction to be tendered.')

        tender_button, tender_button_fallback, tender_frame = self._get_tender_button_and_next_frame(tender_type, external_id)
        if tender_group_id is not None:
            self.select_tender_group_from_tenderbar(tender_group_id)
            self.select_tender_from_tender_group(tender_button)
        else:
            self.select_tender_from_tenderbar(tender_button, tender_button_fallback)
        frame = self._control.get_menu_frame_after_processing()
        if frame.use_description == POSFrame.ASK_FINALIZE_ZERO_TRANSACTION.value:
            self._control.press_button_on_frame(POSFrame.ASK_FINALIZE_ZERO_TRANSACTION, POSButton.YES)
            return
        if check_name != '':
            self.wait_for_frame_open(POSFrame.ASK_CHECK_TRANSIT_NUMBER)
            self._checkreader.read(check_name=check_name)
        self.wait_for_frame_open(tender_frame)

        if isinstance(amount, str):
            button = self._get_quick_button(amount, tender_type)
            self._control.press_button_on_frame(tender_frame, button)
            frame = self._control.get_menu_frame_after_processing()
        elif isinstance(amount, float):
            amount = round(amount, 2)
            if amount < 0:
                raise ProductError("The amount has to be greater or equal to 0.")
            self.press_digits(tender_frame, amount)
            self.press_button_on_frame(tender_frame, POSButton.ENTER)
        else:
            raise ProductError("Wrong type of amount. Amount type '{0}'.".format(type(amount)))

    def _get_quick_button(self, amount: str, tender_type: str) -> POSButton:
        """
        Gets a hotkey button according to the given tender_type.

        :param amount: Amount of the hotkey as 5, 10, exact_dollar etc
        :param tender_type: Type of the tender as cash, credit etc
        :return: Hotkey button
        """
        button = amount.lower()
        tender_type = tender_type.lower()
        accepted_tenders = ["credit", "debit", "check", "gift certificate", "manual imprint", "food stamps", "e-check"]
        if tender_type == "cash":
            if button == "5":
                button = POSButton.PRESET_5
            elif button == "10":
                button = POSButton.PRESET_10
            elif button == "20":
                button = POSButton.PRESET_20
            elif button == "next_dollar":
                button = POSButton.NEXT_DOLLAR
            elif button == "exact_dollar":
                button = POSButton.EXACT_DOLLAR
            else:
                raise ProductError("This is not a correct quick button '{0}' for cash tender.".format(amount))
        elif tender_type in accepted_tenders:
            if button == "exact_dollar":
                button = POSButton.EXACT_DOLLAR
            else:
                raise ProductError("This is not a correct quick button '{0}' for {1} tender.".format(amount, tender_type))
        else:
            raise ProductError("The tender type '{0}' does not exist or is not implemented yet.".format(tender_type))
        return button

    def _get_tender_button_and_next_frame(self, tender_type: str, external_id: str) -> [str, POSButton, POSFrame]:
        """
        Gets tender button and tender's next frame.

        :param tender_type: Type of the tender as cash, credit, etc.
        :param external_id: External ID of the desired tender.
        :return: a string representation of the tender button, a POSButton fallback of the tender and its next frame POSFrame
        """
        tender_type = tender_type.lower()
        if tender_type == "cash":
            tender_button = POSButton.TENDER_CASH_NO_EXTERNAL_ID.value + '-' + external_id
            tender_button_fallback = POSButton.TENDER_CASH
            tender_frame = POSFrame.ASK_TENDER_AMOUNT_CASH
        elif tender_type == "credit":
            tender_button = POSButton.TENDER_CREDIT_NO_EXTERNAL_ID.value + '-' + external_id
            tender_button_fallback = POSButton.TENDER_CREDIT
            tender_frame = POSFrame.ASK_TENDER_AMOUNT_CREDIT
        elif tender_type == "debit":
            tender_button = POSButton.TENDER_DEBIT_NO_EXTERNAL_ID.value + '-' + external_id
            tender_button_fallback = POSButton.TENDER_DEBIT
            tender_frame = POSFrame.ASK_TENDER_AMOUNT_DEBIT
        elif tender_type == "check" or tender_type == 'e-check':
            tender_button = POSButton.TENDER_CHECK_NO_EXTERNAL_ID.value + '-' + external_id
            tender_button_fallback = POSButton.TENDER_CHECK
            tender_frame = POSFrame.ASK_TENDER_AMOUNT_CHECK
        elif tender_type == "gift certificate":
            tender_button = POSButton.TENDER_GIFT_CERTIFICATE_NO_EXTERNAL_ID.value + '-' + external_id
            tender_button_fallback = POSButton.TENDER_GIFT_CERTIFICATE
            tender_frame = POSFrame.ASK_TENDER_AMOUNT_GIFT_CERTIFICATE
        elif tender_type == "manual imprint":
            tender_button = POSButton.TENDER_MANUAL_IMPRINT_NO_EXTERNAL_ID.value + '-' + external_id
            tender_button_fallback = POSButton.TENDER_MANUAL_IMPRINT
            tender_frame = POSFrame.ASK_TENDER_AMOUNT_MANUAL_IMPRINT
        elif tender_type == "food stamps":
            tender_button = POSButton.TENDER_FOOD_STAMPS_NO_EXTERNAL_ID.value + '-' + external_id
            tender_button_fallback = POSButton.TENDER_FOOD_STAMPS
            tender_frame = POSFrame.ASK_TENDER_AMOUNT_FOOD_STAMPS
        else:
            raise ProductError('Tender type "{0}" is not implemented yet or does not exist.'.format(tender_type))
        return tender_button, tender_button_fallback, tender_frame

    def get_transaction(self, number: int or str="current") -> Optional[Transaction]:
        """
        Retrieve a transaction from the POS.

        ** Usage: **
        >>> pos = POSProduct()
        >>> pos.get_transaction(5)

        :param int or str number: Transaction number or 'current' for the current transaction.
        :return: If the transaction was found then its data, otherwise None.
        :rtype: Transaction or None
        """
        return self._control.get_transaction(number)

    def get_current_transaction(self) -> Optional[Transaction]:
        """
        Retrieve the current transaction from the POS

        ** Usage: **
        >>> pos = POSProduct()
        >>> pos.get_current_transaction()

        :return: Transaction of current transaction data or None if there is no transaction
        :rtype: Transaction or None
        """
        return self.get_transaction("current")

    def get_previous_transaction(self) -> Optional[Transaction]:
        """
        Retrieve the previous transaction from the POS

        ** Usage: **
        >>> pos = POSProduct()
        >>> pos.get_previous_transaction()

        :return: Transaction of previous transaction data or None if there is no transaction
        :rtype: Transaction or None
        """
        return self.get_transaction("previous")

    def ensure_ready_to_sell(self, operator_pin: int = 1234, manager_pin: int = 2345) -> None:
        """
        Attempts to sign-in the operator and unlock the terminal and there is not transaction in progress.

        :param int operator_pin: Operator's PIN.
        :param int manager_pin: used for manager override if required
        """
        with self._performance.ensuring_ready_to_sell__verify_ready:
            self.verify_ready()
        with self._performance.ensuring_ready_to_sell__close_frame:
            frame = self._control.get_menu_frame_after_processing()

            self.return_to_mainframe()

            frame = self._control.get_menu_frame()
            if frame.use_description == POSFrame.ASK_OPERATOR_PIN.value:
                # at this point, the end shift flow cannot be aborted short of pos reboot
                # instead the end shift is finalized and a new shift started
                self.end_shift()
                frame = self._control.get_menu_frame()
            if frame.use_description == POSFrame.START_SHIFT.value:
                self.start_shift(operator_pin)
            elif frame.use_description == POSFrame.TERMINAL_LOCK.value:
                self.unlock_pos(operator_pin)

        with self._performance.ensuring_ready_to_sell__wait_for_main:
            self.wait_for_frame_open(POSFrame.MAIN)

        if self.get_current_transaction() is not None:
            with self._performance.ensuring_ready_to_sell__void_transaction:
                self.void_transaction(manager_pin)

        with self._performance.ensuring_ready_to_sell__clear_store_recall:
            self.clear_recall_transactions()

        with self._performance.ensuring_ready_to_sell__end_waiting_for_events:
            self._control.end_waiting_for_events()

    def ensure_ready_to_start_shift(self, operator_pin: int = 1234, manager_pin: int = 2345) -> None:
        """
        Attempts to make sure there is no transaction in progress and end the current shift.

        :param int operator_pin: Operator's PIN.
        :param int manager_pin: Manager's PIN.
        """
        self.verify_ready()
        frame = self._control.get_menu_frame_after_processing()

        if frame.use_description == POSFrame.ASK_CONFIRM_USER_OVERRIDE.value:
            self.return_to_mainframe()
            frame = self._control.get_menu_frame()

        if self.is_someone_signed_in():
            self.return_to_mainframe()
            if self._control.get_menu_frame().use_description == POSFrame.TERMINAL_LOCK.value:
                self.unlock_pos(operator_pin)
            self.wait_for_frame_open(POSFrame.MAIN)
            if self.get_current_transaction() is not None:
                self.void_transaction(manager_pin)
                self.wait_for_frame_open(POSFrame.MAIN)
            self.clear_recall_transactions()
            self._control.end_waiting_for_events()
            self.end_shift(operator_pin)
        elif frame.use_description != POSFrame.START_SHIFT:
            self.return_to_mainframe()
        self.wait_for_frame_open(POSFrame.START_SHIFT)

    def end_shift(self, operator_pin: int = 1234, ending_count: float = 0) -> None:
        """
        Method to go through the end shift flow with the supplied operator pin. No Safe drop is performed. POS is
        expected to be on the main menu frame with no transaction in progress OR on the last prompt to enter pin,
        which cannot be aborted. Can be refactored in the future to provide capability to handle different flows
        depending on POS option values.

        :param operator_pin: Pin of the operator who is ending the shift.
        :param ending_count: Ending count amount for all tenders which require it.
        """
        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.MAIN.value:
            self.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
            self.wait_for_frame_open(POSFrame.OTHER_FUNCTIONS)
            self.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.END_SHIFT)
            self.wait_for_frame_open(POSFrame.SELECT_SAFE_DROP_TENDER)
            self.press_button_on_frame(POSFrame.SELECT_SAFE_DROP_TENDER, POSButton.TENDER_CASH)
            self.wait_for_frame_open(POSFrame.ASK_SAFE_DROP_AMOUNT_CASH)
            self.press_button_on_frame(POSFrame.ASK_SAFE_DROP_AMOUNT_CASH, POSButton.ENTER)
            self.wait_for_frame_open(POSFrame.SELECT_SAFE_DROP_TENDER)
            frame = self._control.get_menu_frame()
            self.press_button_on_frame(POSFrame.SELECT_SAFE_DROP_TENDER, POSButton.DONE)
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()
            if frame.use_description == POSFrame.ASK_TENDER_ENDING_COUNTS.value:
                self.enter_all_tender_counts(ending_count, POSFrame.ASK_TENDER_ENDING_COUNTS)
            elif frame.use_description == POSFrame.ASK_DRAWER_COUNT_CASH.value:
                self.enter_tender_count(ending_count)
            self.wait_for_frame_open(POSFrame.ASK_OPERATOR_PIN)
        self.press_digits(POSFrame.ASK_OPERATOR_PIN, operator_pin)
        self.press_button_on_frame(POSFrame.ASK_OPERATOR_PIN, POSButton.SHIFT)
        try:
            self.wait_for_frame_open(POSFrame.START_SHIFT)
        except Exception:
            self.return_to_mainframe()
            self.wait_for_frame_open(POSFrame.START_SHIFT)
      

    def return_to_mainframe(self) -> None:
        """
        Tries to return from any frame to the main frame. The exception is start shift frame.
        """
        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.MAIN.value or frame.use_description == POSFrame.START_SHIFT.value:
            return
        if frame.name == 'common-yes/no' or frame.name == 'other-lock-term-veri':
            self._control.press_button(frame.instance_id, POSButton.NO.value)
            self._control.wait_for_frame_close(frame)
            try:
                self.wait_for_frame_open(POSFrame.ASK_TENDER_AMOUNT_CASH)
            except AssertionError:
                pass
            finally:
                frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_VERIFY_AGE_OVER_UNDER.value:
            self._control.press_button(frame.instance_id, POSButton.UNDER.value)
            frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_DRAWER_COUNT_CASH.value:
            self.enter_tender_count()
            frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_TENDER_ENDING_COUNTS.value:
            self.enter_all_tender_counts(frame_use=POSFrame.ASK_TENDER_ENDING_COUNTS)
            frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_TENDER_STARTING_COUNTS.value:
            self.enter_all_tender_counts(frame_use=POSFrame.ASK_TENDER_STARTING_COUNTS)
            frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.LAST_CHANCE_LOYALTY.value:
            self._control.press_button(frame.instance_id, POSButton.CONTINUE.value)
            time.sleep(0.2)
            frame = self._control.get_menu_frame()

        self._return_from_current_frame(frame)

    def _return_from_current_frame(self, frame: POSFrame) -> None:
        """
        Helper method that tries to return from current frame, going through Go-Back, Cancel and Done buttons, to the main frame.

        Unfortunately there are several cases where frames are displayed over one another and closing one then messes up go back flow,
        in that case add the frame's metadata to the exception_list to include a hardcoded sleep.

        :param frame: Current POS frame, from which should be returned to the main frame.
        """
        MAX_DEPTH = 10
        depth = 0
        exception_list = [POSFrame.MSG_AGE_REQUIREMENTS_NOT_MET.value, POSFrame.ASK_OPERATOR_PIN.value, POSFrame.ASK_ENTER_LOYALTY_PIN.value]
        while True:
            if frame.has_go_back():
                self.press_goback_on_current_frame(raise_error=False)
                if frame.use_description in exception_list:
                    # 1 seconds sleep works, but something like cancelling all events that are currently in POS would work much better.
                    time.sleep(1)
                frame = self._control.get_menu_frame()
            elif frame.has_cancel():
                self.press_cancel_on_current_frame(raise_error=False)
                frame = self._control.get_menu_frame()
            elif frame.has_done():
                self.press_done_on_current_frame(raise_error=False)
                frame = self._control.get_menu_frame()
            elif frame.use_description == POSFrame.WAIT_CREDIT_PROCESSING.value or \
                frame.use_description == POSFrame.WAIT_PES_PROCESSING.value:
                frame = self._control.get_menu_frame_after_processing()
            else:
                break

            if depth >= MAX_DEPTH:
                raise ProductError("The go_back/cancel/done loop ran over the depth limit and probably got stuck.")
            depth += 1

    def clear_recall_transactions(self):
        """
        Tries to remove all transactions from the recall transaction list by recalling and finishing them.
        """
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
        self.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.RECALL_TRANSACTION)
        self.wait_for_frame_open(POSFrame.RECALL_TRANSACTION_LIST_FRAME)
        recall_frame = self._control.get_menu_frame()
        recall_items = recall_frame.list_windows[0].list_items
        if not recall_items:
            self._control.press_button(recall_frame.instance_id, POSButton.GO_BACK.value)
            self.wait_for_frame_open(POSFrame.MAIN)
        else:
            self._control.select_item(instance_id=recall_frame.instance_id, list_item=recall_items[0].number)
            self._control.press_button(recall_frame.instance_id, POSButton.DONE.value)
            self.approve_age_verification()
            self.finish_current_transaction(10)
            self.wait_for_frame_open(POSFrame.MAIN)
            self.clear_recall_transactions()

    def approve_age_verification(self, drivers_license: str = 'valid DL') -> None:
        """
        Helper function which attempts to approve a pending age verification.

        :param drivers_license: name of a valid DL to be swiped IF on a frame which does not allow manual entry.
        """
        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_VERIFY_AGE.value and frame.has_button(POSButton.INSTANT_APPROVAL):
            self.press_button_on_frame(POSFrame.ASK_VERIFY_AGE, POSButton.INSTANT_APPROVAL)
        elif frame.use_description == POSFrame.ASK_VERIFY_AGE_MANUAL.value or frame.use_description == POSFrame.ASK_VERIFY_AGE.value:
            age = self.calculate_birthday(30)
            self.enter_birthday_manually(age)
        elif frame.use_description == POSFrame.ASK_VERIFY_AGE_OVER_UNDER.value:
            self.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_OVER_UNDER, POSButton.OVER)
        elif frame.use_description == POSFrame.ASK_VERIFY_AGE_NO_MANUAL.value:
            self.swipe_card(drivers_license)
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()
            if frame.use_description == POSFrame.ASK_VALIDATE_ID.value:
                self.press_button_on_frame(POSFrame.ASK_VALIDATE_ID, POSButton.YES)
        elif frame.use_description == POSFrame.MSG_RECALL_ITEMS_REMOVED.value:
            self.press_goback_on_current_frame()

    def start_shift(self, operator_pin: int = 1234, drawer_count: float = 0) -> None:
        """
        Attempts to start a new shift on POS. It also provides drawer's starting count.

        :param operator_pin: Operator PIN.
        :param drawer_count: Starting drawer count which will be used if prompted for it
        """
        self.wait_for_frame_open(POSFrame.START_SHIFT)
        self._control.press_button_on_frame(POSFrame.START_SHIFT, POSButton.SHIFT)
        self.wait_for_frame_open(POSFrame.ASK_OPERATOR_PIN)
        self.press_digits(POSFrame.ASK_OPERATOR_PIN, operator_pin)
        frame = self._control.get_menu_frame()
        self._control.press_button_on_frame(POSFrame.ASK_OPERATOR_PIN, POSButton.SHIFT)
        self._control.wait_for_frame_close(frame)
        frame = self._control.get_menu_frame()

        if frame.use_description == POSFrame.ASK_TENDER_STARTING_COUNTS.value:
            self.enter_all_tender_counts(drawer_count)

        elif frame.use_description == POSFrame.ASK_DRAWER_COUNT_CASH.value:
            self.enter_tender_count(drawer_count)

        self.wait_for_frame_open(POSFrame.MAIN)

    def enter_all_tender_counts(self, tender_count: float = 0, frame_use: POSFrame = POSFrame.ASK_TENDER_STARTING_COUNTS,
                                confirm: bool = True) -> None:
        """
        Iterate through all tenders which require starting/ending count and enter the given amount.

        :param tender_count: Starting/ending amount to be entered.
        :param frame_use: Specifies the frame with the count, usually starting or ending count.
        :param confirm: Specifies if the Done button should be pressed after entering all tender counts.
        """
        tenders_entered = False
        tender_page = 0
        while not tenders_entered:
            frame = self._control.get_menu_frame()
            if frame.has_button(POSButton.DONE):
                self.press_done_on_current_frame()
                break
            for button in frame.frames[0].buttons:
                if button.name != 'more':
                    self.press_button_on_frame(frame_use, button.name)
                    self.enter_tender_count(tender_count)
                    for i in range(tender_page):
                        self.press_button_on_frame(frame_use, 'more')
                    if self._control.get_menu_frame().has_button(POSButton.DONE):
                        if confirm:
                            self.press_button_on_frame(frame_use, POSButton.DONE)
                        tenders_entered = True
                        break
            else:
                self.press_button_on_frame(frame_use, 'more')
                tender_page += 1

    def enter_tender_count(self, tender_count: float = 0) -> None:
        """
        Enter starting/ending count for the currently selected tender.

        :param tender_count: Starting/ending amount to be entered.
        """
        if tender_count != 0:
            self.press_digits(POSFrame.ASK_DRAWER_COUNT_CASH, tender_count)
        frame = self._control.get_menu_frame()
        self._control.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CASH, POSButton.ENTER)
        self.wait_for_frame_open(POSFrame.ASK_DRAWER_COUNT_CORRECT)
        self._control.press_button_on_frame(POSFrame.ASK_DRAWER_COUNT_CORRECT, POSButton.YES)
        self._control.wait_for_frame_close(frame)

    def press_digits(self, frame: POSFrame, number: Union[int, float, str]) -> None:
        """
        Press digit keys.

        :param frame: POS frame that contains number keys
        :param number: Numbers that should be pressed. If a float is given,
            it will be converted to two decimal places.
        """

        if isinstance(number, float):
            digits = "{:.2f}".format(number).replace(".", "")
        elif isinstance(number, int):
            digits = str(number)
        else:
            digits = number.replace(".", "")

        for digit in digits:
            self._control.press_button_on_frame(frame, POSButton("key-{}".format(digit)))

    def press_goback_on_current_frame(self, raise_error: bool = True):
        """
        Presses go back button on the current main frame, if there is a go back button.

        :param bool raise_error: If True, function will raise an error if there is no back button on the frame
        """
        frame = self._control.get_menu_frame()
        if raise_error and not frame.has_go_back():
            raise ProductError('The current frame "{}" does not have go back button.'.format(frame.name))
        if not frame.has_go_back():
            return
        self._control.press_button(frame.instance_id, POSButton.GO_BACK.value)

    def press_cancel_on_current_frame(self, raise_error: bool = True):
        """
        Presses Cancel button on the current main frame, if there is a Cancel button.

        :param bool raise_error: If True, function will raise an error if there is no Cancel button on the frame
        """
        frame = self._control.get_menu_frame()
        if raise_error and not frame.has_cancel():
            raise ProductError('The current frame "{}" does not have Cancel button.'.format(frame.name))
        if not frame.has_cancel():
            return
        self._control.press_button(frame.instance_id, POSButton.CANCEL.value)

    def press_enter_on_current_frame(self, raise_error: bool = True):
        """
        Presses enter button on the current frame, if there is an enter button.

        :param bool raise_error: If True, function will raise an error if there is no enter button on the frame
        """
        frame = self._control.get_menu_frame()
        if not frame.has_button(POSButton.ENTER):
            if raise_error:
                raise ProductError('The current frame "{}" does not have enter button.'.format(frame.name))
            else:
                return
        self._control.press_button(frame.instance_id, POSButton.ENTER.value)

    def press_done_on_current_frame(self, raise_error: bool = True):
        """
        Presses Done button on the current main frame, if there is a Done button.

        :param bool raise_error: If True, function will raise an error if there is no Done button on the frame
        """
        frame = self._control.get_menu_frame()
        if raise_error and not frame.has_done():
            raise ProductError('The current frame "{}" does not have Done button.'.format(frame.name))
        if not frame.has_done():
            return
        self._control.press_button(frame.instance_id, POSButton.DONE.value)


    def _get_transaction_age_verification_method_code(self, transaction: str = 'current') -> int:
        """
        Returns the code for age verification used in the current/previous transaction.
        0 - no age verification performed
        2 - instant approval button (over 30)
        3 - manual entry
        """
        if not isinstance(transaction, str):
            raise ProductError('Expected either \'current\' or \'previous\' transaction identifier')
        tran = self._control.get_transaction(transaction)
        if tran is None:
            raise ProductError("No transaction was retrieved.")
        return int(tran.age_verification_type)

    def get_transaction_age_verification_method(self, transaction: str = 'current') -> int:
        """
        Returns the code for age verification used in the current/previous transaction.
        0 - no age verification performed
        1 - driver's license swipe
        2 - instant approval button (over 30)
        3 - manual entry
        """
        code = self._get_transaction_age_verification_method_code(transaction)
        available_codes = {
            0: 'none',
            1: 'license swipe',
            2: 'instant button',
            3: 'manual',
            4: 'over button',
            5: 'license scan',
            6: 'under button',
            7: 'cancel button',
            8: 'license swipe fail',
            9: 'license scan fail',
            10: 'manual fail'
        }
        method = available_codes.get(code, 'code {} not found in the list of verification methods'.format(code))
        return method

    def enter_birthday_manually(self, birth_date: str, confirm_with_enter: bool=True) -> None:
        """
        Converts the birth date given through gherkin into int, inputs the result manually and confirms by pressing enter.

        :param str birth_date: birth date of the customer supplied in MM-DD-YYYY format
        :param bool confirm_with_enter: controls whether the birthday entry should be followed by pressing the Enter button
        """
        frame = self._control.get_menu_frame()
        formatted_birth_date = ''
        for char in birth_date:
            if char.isdigit():
                formatted_birth_date += char
        if frame.use_description == POSFrame.ASK_VERIFY_AGE.value:
            self.press_digits(POSFrame.ASK_VERIFY_AGE, number=formatted_birth_date)
            if confirm_with_enter:
                self.press_button_on_frame(POSFrame.ASK_VERIFY_AGE, POSButton.ENTER)
        else:
            self.press_digits(POSFrame.ASK_VERIFY_AGE_MANUAL, number=formatted_birth_date)
            if confirm_with_enter:
                self.press_button_on_frame(POSFrame.ASK_VERIFY_AGE_MANUAL, POSButton.ENTER)

    def calculate_birthday(self, age: int, day_offset: int = 0) -> str:
        """
        Calculates a birth date based on the supplied age and current system time. This helper method is intended to be
        used as an input to enter_birthday_manually method so the output format matches its expected input format.

        :param int age: age of the customer in years
        :param int day_offset: optional shift of a customer's birthday by a number of days
        :return: string with the month, day and year of customers birthday
        """
        current_time = datetime.datetime.now()
        birthdate = current_time + relativedelta(years=-age, days=day_offset)
        return birthdate.strftime("%m-%d-%Y")

    def calculate_effective_date(self, year_dif: int, month_dif: int = 0, day_dif: int = 0) -> tuple:
        """
        Calculates an effective date based on the given delta and current system time, both positive and negative values
        are accepted.

        :param int year_dif: year difference from now to the effective date application, positive value means future date
        :param int month_dif: month difference from now to the effective date application, positive value means future date
        :param int day_dif: day difference from now to the effective date application, positive value means future date
        """
        current_date = datetime.datetime.now()
        effective_date = current_date + relativedelta(years=year_dif, months=month_dif, days=day_dif)
        return effective_date

    def calculate_and_parse_effective_date(self, year_dif: int, month_dif: int = 0, day_dif: int = 0) -> tuple:
        """
        This method is intended to be used as an input to the create_sale_item method, so the effective
        date is returned as three separate integers.

        :param int year_dif: year difference from now to the effective date application, positive value means future date
        :param int month_dif: month difference from now to the effective date application, positive value means future date
        :param int day_dif: day difference from now to the effective date application, positive value means future date
        """
        eff_date = self.calculate_effective_date(year_dif=year_dif, month_dif=month_dif, day_dif=day_dif)
        return eff_date.year, eff_date.month, eff_date.day

    def finish_current_transaction(self, timeout: Optional[float] = None, tender_type: str = "cash", tender_ext_id: str = '70000000023') -> int:
        """
        Finishes the current transaction if any.

        :param Optional[float] timeout: Timeout in seconds.
        :param tender_type: Tender type of the desired tender. Type can be cash, credit etc..
        :param tender_ext_id: External ID of the desired tender.
        :return: Number of the finished transaction if any. Otherwise zero.
        :rtype: int
        """
        tran = self.get_transaction("current")
        tran_number = tran.sequence_number if tran is not None else 0
        if tran_number != 0:
            self.tender_transaction(tender_type=tender_type, external_id=tender_ext_id)

            transaction = self._control.wait_for_transaction_end(timeout)
            if transaction is None:
                raise ProductError("Unable to clear transaction '{0}'.".format(transaction.sequence_number))
        return tran_number

    def wait_for_item_added_to_VR(self, item_name: str, item_price: float=None, item_quantity: int=None,
                                    consolidate: bool=False, unit_of_measure: str=None, timeout: float=3) -> bool:
        """
        Wait until the desired item is added to the VR or the timeout is reached.
        If item_price is None, it checks only for item_name in the VR and ignores other params.

        :param item_name: Name of the item which should be on the VR.
        :param item_price: Price of the item which should be on the VR.
        :param item_quantity: Quantity of the item which should be on the VR.
        :param consolidate: Merge lines containing the item before checking its price and quantity.
        :param unit_of_measure: unit of measure(KG/LB) which should be on the VR.
        :return: bool if the item is in the VR or not
        """
        logger.info("Waiting for the item to be added to the virtual receipt")
        item_added = False
        item_added = self.verify_virtual_receipt_contains_item(item_name, item_price, item_quantity, consolidate, unit_of_measure)

        item_added = timeouter(self.verify_virtual_receipt_contains_item, timeout,
            item_name, item_price, item_quantity, consolidate, unit_of_measure)

        if not item_added:
            logger.error("Item was not added in {0:.3f} seconds.".format(timeout))
        return item_added

    def verify_virtual_receipt_contains_item(self, item_name: str, item_price: float=None, item_quantity: int=None, consolidate: bool=False, unit_of_measure: str=None) -> bool:
        """
        Verifies that the provided item is displayed on the virtual receipt.

        :param item_name: Name of the item which should be on the VR.
        :param item_price: Price of the item which should be on the VR.
        :param item_quantity: Quantity of the item which should be on the VR.
        :param consolidate: Merge lines containing the item before checking its price and quantity.
        :param unit_of_measure: unit of measure(KG/LB) which should be on the VR.
        :return: bool if the item is in the VR or not
        """
        frame_receipt = self._control.get_receipt_frame()
        items = frame_receipt.virtual_receipt.receipt_items
        item_quantity_in_receipt = 0
        item_price_in_receipt = 0.0
        for item in items:
            if consolidate and item.description == item_name:
                item_quantity_in_receipt += int(item.quantity)
                item_price_in_receipt += float(item.price)
            elif item.description == item_name:
                if not unit_of_measure:
                    if not item_quantity or int(item.quantity) == int(item_quantity):
                        if not item_price or math.isclose(float(item.price), float(item_price), rel_tol=1e-5):
                            return True
                elif str(item.formatted_quantity[:-1]) == str(unit_of_measure):
                    if not item_price or math.isclose(float(item.price), float(item_price), rel_tol=1e-5):
                        return True

        if consolidate:
            if not item_quantity or item_quantity_in_receipt == int(item_quantity):
                if math.isclose(item_price_in_receipt, float(item_price), rel_tol=1e-5):
                    return True
        logger.debug("Item '{}' with price ${} and quantity {} not found on VR.".format(item_name, item_price, item_quantity))
        return False

    def verify_virtual_receipt_contains_fuel_item(self, item_name: str, item_price: float, pump_prefix: str=None) -> bool:
        """
        Verifies that the provided fuel item is displayed on the virtual receipt.

        :param item_name: Name of the fuel item which should be on the VR.
        :param item_price: Price of the fuel item which should be on the VR.
        :param pump_prefix: Prefix of the pump which should be on the VR with fuel item.
        :return: bool if the fuel item is in the VR or not
        """
        frame_receipt = self._control.get_receipt_frame()
        items = frame_receipt.virtual_receipt.receipt_items
        for item in items:
            if item.description == item_name:
                if not pump_prefix or item.formatted_quantity == pump_prefix:
                    if math.isclose(float(item.price), float(item_price), rel_tol=1e-5):
                        return True

        logger.debug("Fuel item '{}' with price ${} not found on VR.".format(item_name, item_price))
        return False

    def select_item_in_list(self, frame: POSFrame, item_name: str=None, item_position: int=None, list_number: int=0, only_highlighted: bool=False) -> None:
        """
        Selects an item in list on given frame. If item_name and item_position arguments are provided,
        then item_name has to match the name of an item on the given position.

        :param item_name: Name of the item which is going to be selected in list on current frame.
        :param item_position: Position of item which is going to be selected in list on current frame.
        :param only_highlighted: Force the item to be only marked as selected in UI.
        :return: None
        """
        if item_name is None and item_position is None:
            raise ProductError("At least one of the parameters - description or item_position - has to be provided.".format(item_position))

        self.wait_for_frame_open(frame)
        current_frame = self._control.get_menu_frame()

        if not current_frame.list_windows:
            raise ProductError("Current frame '{}' doesn't contain any list view.".format(current_frame.name))
        if len(current_frame.list_windows) < list_number:
            raise ProductError("Current frame '{}' requested list '{}' exceeded number of lists on frame '{}'".format(current_frame.name, list_number, len(current_frame.list_windows)))
        items = current_frame.list_windows[list_number].list_items

        if item_position is not None:
            if item_position > items.__len__():
                raise ProductError("Item position '{}' is out of range!".format(item_position))
            if item_position < 0:
                raise ProductError("Item position '{}' is not a valid number!".format(item_position))
            if item_name is not None and item_name != items[item_position].text:
                raise ProductError("Item on position '{}' with name '{}' doesn't match given name '{}'".format(item_position, items[item_position].text, item_name))
            self._control.select_item(instance_id=current_frame.instance_id, list_item=items[item_position].number, only_highlighted=only_highlighted)
            return

        if items is None:
            raise ProductError("Items in list do not exist. They may have been incorrectly proccessed.")
        item_position = -1
        for item in items:
            if item.text == item_name:
                item_position = item.number
                break

        if item_position == -1:
            raise ProductError("Item '{}' not found in list!".format(item_name))
        self._control.select_item(instance_id=current_frame.instance_id, list_item=item_position, only_highlighted=only_highlighted)

    def select_item_in_recall_transaction_list(self, transaction_sequence_number: int = None, position: int = 0) -> None:
        """
        Selects an item in recall transaction list. If transaction number is given, it is preferred over position argument.

        :param transaction_sequence_number: Number of transaction to be selected.
        :param position: List position of the transaction to be selected, counting from the top. 0 means first item.
        :return: None
        """
        self.wait_for_frame_open(POSFrame.RECALL_TRANSACTION_LIST_FRAME)
        current_frame = self._control.get_menu_frame()

        if not current_frame.list_windows:
            raise ProductError("Current frame '{}' doesn't contain any list view.".format(current_frame.name))

        items = current_frame.list_windows[0].list_items
        if transaction_sequence_number is not None:
            item_position = -1
            for item in map(UiRecallTransactionItem.from_list_item, items):
                if item.transaction_sequence_number == transaction_sequence_number:
                    item_position = item.number
                    break

            if item_position == -1:
                raise ProductError("Transaction #{} not found in Recall transaction list.".format(transaction_sequence_number))
            self._control.select_item(instance_id=current_frame.instance_id, list_item=item_position)
        else:
            self._control.select_item(instance_id=current_frame.instance_id, list_item=items[position].number)

    def select_item_in_scroll_previous_list(self, transaction_sequence_number: int = None, position: int = 0) -> None:
        """
        Selects an item in scroll previous list. If transaction number is given, it is preferred over position argument.

        :param transaction_sequence_number: Number of transaction to be selected.
        :param position: List position of the transaction to be selected, counting from the top. 0 means first item.
        :return: None
        """
        self.wait_for_frame_open(POSFrame.SCROLL_PREVIOUS_FRAME)
        current_frame = self._control.get_menu_frame()

        if not current_frame.list_windows:
            raise ProductError("Current frame '{}' doesn't contain any list view.".format(current_frame.name))

        items = current_frame.list_windows[0].list_items
        if transaction_sequence_number is not None:
            item_position = -1
            for item in map(UiScrollPreviousItem.from_list_item, items):
                if item.transaction_sequence_number == transaction_sequence_number:
                    item_position = item.number
                    break

            if item_position == -1:
                if len(items) < 10:
                    raise ProductError("Transaction #{} not found in Scroll Previous list.".format(transaction_sequence_number))
                else:
                    self.press_button_on_frame(POSFrame.SCROLL_PREVIOUS_FRAME, POSButton.DOWN_ARROW)
                    return self.select_item_in_scroll_previous_list(transaction_sequence_number, position)
            self._control.select_item(instance_id=current_frame.instance_id, list_item=item_position)
        else:
            self._control.select_item(instance_id=current_frame.instance_id, list_item=items[position].number)

    def get_tran_param_from_scroll_previous_line(self) -> UiScrollPreviousItem:
        """
        Get a selected line in Scroll previous transactions list.
        """
        self.wait_for_frame_open(POSFrame.SCROLL_PREVIOUS_FRAME)
        current_frame = self._control.get_menu_frame()
        items = current_frame.list_windows[0].list_items
        for item in map(UiScrollPreviousItem.from_list_item, items):
            # Temporary fix to avoid that empty transaction is returned as selected.
            # Will be solved in RPOS-35342
            if len(items) == 2 and item.node_type != '':
                return item
            elif item.selected == True:
                return item

        return None

    def select_item_in_virtual_receipt(self, item_name: str=None, item_price: float=None) -> None:
        """
        Selects an item in VR. 
        If there is provided only item_name and there are more items
        with the same name in VR, the first one found will be selected.

        :param str item_name: Name of the item which is going to be selected in VR.
        :param float item_price: Price of the item which is going to be selected in VR.
        :return: Item number of selected item.
        """
        if item_name is None:
            raise ProductError("Description has to be provided.")
        frame_receipt = self._control.get_receipt_frame()
        items = frame_receipt.virtual_receipt.receipt_items

        if items is None:
            raise ProductError("Items in receipt do not exist. They may have been incorrectly proccessed.")
        item_number = 0
        for item in items:
            if item.description == item_name:
                if not item_price or math.isclose(float(item.price), item_price, rel_tol=1e-5):
                    item_number = item.number
                    if item.selected:
                        return item_number
                    break

        if item_number == 0:
            raise ProductError("Item '{}' with price {} not found on VR!".format(item_name, item_price))
        self._control.select_item(instance_id=frame_receipt.instance_id, list_item=item_number)
        return item_number

    def is_item_selected(self, item_name: str, item_price: float) -> bool:
        """
        Selects an item in VR.
        :param item_name: Name of the item which is going to be selected in VR.
        :param float item_price: Price of the item which is going to be selected in VR.

        :return bool: True if the item is selected
        """
        frame_receipt = self._control.get_receipt_frame()
        items = frame_receipt.virtual_receipt.receipt_items
        for item in items:
            if item.description == item_name:
                if item_price is None or math.isclose(float(item.price), item_price, rel_tol=1e-5):
                    if item.selected:
                        return True
        return False

    def void_item(self, item_name: str, item_price: float = None, manager_pin: int = 2345) -> None:
        """
        Selects item in VR and then deletes it.

        :param str item_name: Name of the item
        :param str item_price: Price of the item
        :return: None
        """
        self.select_item_in_virtual_receipt(item_name=item_name, item_price=item_price)
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.VOID_ITEM)
        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_SECURITY_OVERRIDE.value:
            self.press_digits(POSFrame.ASK_SECURITY_OVERRIDE, int(manager_pin))
            self.press_button_on_frame(POSFrame.ASK_SECURITY_OVERRIDE, POSButton.ENTER)
            self._control.wait_for_frame_close(frame)

    def void_transaction(self, manager_pin: int = 2345, reason: str = None) -> None:
        """
        Voids the transaction.

        :param int manager_pin: Pin of the manager
        :param str reason: Which reason should be chosen from the list.
        """
        if self.get_current_transaction is None:
            raise ProductError('There is no transaction to void.')
        frame = self._control.get_menu_frame()
        if frame.use_description != POSFrame.MAIN.value:
            raise ProductError('The POS is not in main menu.')
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
        self.wait_for_frame_open(POSFrame.OTHER_FUNCTIONS)
        self.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.VOID_RECEIPT)

        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_VOID_MULTIPLE_TRANSACTIONS.value:
            self.press_button_on_frame(POSFrame.ASK_VOID_MULTIPLE_TRANSACTIONS, POSButton.YES)
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_SECURITY_OVERRIDE.value:
            self.press_digits(POSFrame.ASK_SECURITY_OVERRIDE, int(manager_pin))
            self.press_button_on_frame(POSFrame.ASK_SECURITY_OVERRIDE, POSButton.ENTER)
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()

        if frame.use_description == POSFrame.ASK_FOR_A_REASON.value:
            reason_index = 0
            if reason is not None:
                for i in range(len(frame.list_windows[0].list_items)):
                    if reason == frame.list_windows[0].list_items[i].text:
                        reason_index = i
                        break
            self.select_item_in_list(POSFrame.ASK_FOR_A_REASON, item_position=reason_index)
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()

        if frame.use_description == POSFrame.WAIT_CARWASH_PROCESSING.value:
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_CANCEL_CARWASH_RETRY.value:
            self.press_button_on_frame(POSFrame.ASK_CANCEL_CARWASH_RETRY, POSButton.YES)
        if frame.use_description == POSFrame.MSG_TRANSACTION_CANCEL_NOT_ALLOWED.value:
            self.return_to_mainframe()
            self.tender_transaction()

        self.wait_for_frame_open(POSFrame.MAIN)

    def store_transaction(self) -> int:
        """
        Stores the current transaction.

        :return: Sequence number of the stored transaction
        """
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
        current_transaction = self.get_current_transaction()
        if current_transaction is None:
            raise ProductError("Store transaction called when there is no current transaction.")
        transaction_sequence_number = current_transaction.sequence_number
        self.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.STORE_TRANSACTION)
        return transaction_sequence_number

    def recall_transaction(self, transaction_sequence_number: int = None, position: int = None) -> None:
        """
        Recalls a transaction.

        :param int transaction_sequence_number: Number of the transaction to be recalled
        :param int position: List position of the transaction to be selected, counting from the top. 0 means first item.
        :return: None
        """
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
        self.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.RECALL_TRANSACTION)
        self.select_item_in_recall_transaction_list(transaction_sequence_number=transaction_sequence_number, position=position)
        self.press_button_on_frame(POSFrame.RECALL_TRANSACTION_LIST_FRAME, POSButton.DONE)

    def change_quantity(self, item_name: str, quantity: Union[int, float, str], item_price: float=None, manager_pin: int = 2345) -> None:
        """
        Selects item in VR and then changes its quantity.

        :param str item_name: Name of the item
        :param str item_price: Price of the item
        :param quantity: The desired final quantity.
        :return: None
        """
        self.select_item_in_virtual_receipt(item_name=item_name, item_price=item_price)
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.CHANGE_QUANTITY)
        self.press_digits(POSFrame.ENTER_QUANTITY_AMOUNT, quantity)
        frame = self._control.get_menu_frame()
        self.press_button_on_frame(POSFrame.ENTER_QUANTITY_AMOUNT, POSButton.ENTER)
        self._control.wait_for_frame_close(frame)
        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_SECURITY_OVERRIDE.value:
            self.press_digits(POSFrame.ASK_SECURITY_OVERRIDE, int(manager_pin))
            self.press_button_on_frame(POSFrame.ASK_SECURITY_OVERRIDE, POSButton.ENTER)
            self._control.wait_for_frame_close(frame)
            frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.MAIN.value:
            self.wait_for_item_added_to_VR(item_name=item_name, item_quantity=int(quantity))

    def price_override(self, item_name: str, updated_item_price: float, item_price: float=None, manager_pin: int = 2345) -> None:
        """
        Selects item in VR and then changes its price.

        :param str item_name: Name of the item
        :param float updated_item_price: The desired final price
        :param float item_price: Original price of the item for more accurate lookup in VR
        :param int manager_pin: Pin to override the cashier, if necessary
        """
        self.select_item_in_virtual_receipt(item_name=item_name, item_price=item_price)
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRICE_OVERRIDE)
        self.press_digits(POSFrame.PRICE_OVERRIDE_FRAME, updated_item_price)
        self.press_button_on_frame(POSFrame.PRICE_OVERRIDE_FRAME, POSButton.ENTER)
        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_SECURITY_OVERRIDE.value:
            self.press_digits(POSFrame.ASK_SECURITY_OVERRIDE, int(manager_pin))
            self.press_button_on_frame(POSFrame.ASK_SECURITY_OVERRIDE, POSButton.ENTER)
        frame = self._control.get_menu_frame()
        if frame.use_description == POSFrame.ASK_FOR_A_REASON.value:
            self.select_item_in_list(POSFrame.ASK_FOR_A_REASON, item_position=0)
            self.wait_for_frame_open(POSFrame.MAIN)

    def enter_barcode_manually(self, barcode: str) -> None:
        """
        Enter the given barcode by using manual entry button on the main menu frame.

        :param str barcode: Barcode to enter
        :return: None
        """
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.ENTER_PLU_UPC)
        self.wait_for_frame_open(POSFrame.ASK_BARCODE_ENTRY)
        self.press_digits(POSFrame.ASK_BARCODE_ENTRY, barcode)
        self.press_button_on_frame(POSFrame.ASK_BARCODE_ENTRY, POSButton.ENTER)

    def add_manufacturer_coupon(self, barcode: str, barcode_type: str, input_method: BarcodeInputMethod) -> None:
        """
        Adds the manufacturer coupon into the POS transaction by scanning its barcode.
        Then it confirms expected prompts.

        :param str barcode: The requested barcode
        :param str barcode_type: The requested barcode type
        :param str input_method: The input method of adding the MFC.
        :return: None
        """
        self._control.begin_waiting_for_event("tender-added")
        if input_method == BarcodeInputMethod.MANUAL:
            self.press_button_on_frame(POSFrame.RECEIPT, POSButton.ENTER_PLU_UPC)
            self.press_digits(POSFrame.ASK_BARCODE_ENTRY, barcode)
            self.wait_for_frame_open(frame=POSFrame.ASK_BARCODE_ENTRY, timeout=0.5)
            barcode_entry_frame = self._control.get_menu_frame()
            self._control.press_button(instance_id=barcode_entry_frame.instance_id, button=POSButton.ENTER.value)
            self._control.wait_for_frame_close(frame=barcode_entry_frame, timeout=0.5)
        elif input_method == BarcodeInputMethod.SCAN:
            menu_frame = self._control.get_menu_frame()
            self.scan_item_barcode(barcode=barcode, barcode_type=barcode_type)
            self._control.wait_for_frame_close(frame=menu_frame, timeout=0.5)
        else:
            raise ProductError("Wrong input method")
        menu_frame = self._control.get_menu_frame()
        if menu_frame.use_description == POSFrame.ASK_CONFIRM_MANUFACTURER_COUPON.value:
            self._control.press_button(instance_id=menu_frame.instance_id, button=POSButton.YES.value)
            self._control.wait_for_frame_close(frame=menu_frame, timeout=0.5)
            menu_frame = self._control.get_menu_frame()
        if menu_frame.use_description == POSFrame.ASK_COUPONS_EXPIRATION_DATE_ACCEPTABLE.value:
            self._control.press_button(instance_id=menu_frame.instance_id, button=POSButton.YES.value)
            self._control.wait_for_frame_close(frame=menu_frame, timeout=0.5)
            menu_frame = self._control.get_menu_frame()
        if menu_frame.use_description == POSFrame.MAIN.value:
            self.wait_for_tender_added(tender_type='mfc')

    def wait_for_tender_added(self, tender_type: str, timeout: float=0.5):
        """
        Waits until a tender is added to the transaction.

        :param str tender_type: Type of the tender.
        :param float timeout: Timeout in seconds.
        """
        self._control.wait_for_tender_added(tender_type=tender_type, timeout=timeout)

    def scan_item_barcode(self, barcode: str, barcode_type: str='UPC_EAN') -> None:
        """
        Adds the item into the POS transaction by scanning the item barcode.

        :param str barcode: The requested barcode
        :param str barcode_type: The requested barcode type
        :return: None
        """
        meta = self._control.get_menu_frame()
        frames = [POSFrame.MAIN.value, POSFrame.CREDIT_GET_CARD_SWIPE.value, POSFrame.PRICE_CHECK_FRAME.value, POSFrame.ASK_LOYALTY_CARD.value, POSFrame.LAST_CHANCE_LOYALTY.value]
        if meta.use_description in frames:
            self._scanner.scan(barcode=barcode, barcode_type=barcode_type)
        else:
            raise ProductError(
                "The currently displayed frame [name: {}, use_description: {}] is not the main menu or card scan/swipe frame.".format(
                    meta.name, meta.use_description))

    def scan_drivers_license(self, barcode_name: str) -> None:
        """
        Scans a given drivers license from the SimBarcodes.xml file.

        :param str barcode_name: Name of the barcode from the SimBarcodes.xml file
        :return: None
        """
        self._scanner.scan(barcode_name=barcode_name)

    def swipe_card(self, card_name: str) -> None:
        """
        Swipes a given card from the SimCards.xml file.

        :param str card_name: Name of the card from the SimCards.xml file
        :return: None
        """
        self._swiper.swipe(card_name)

    def swipe_card_tracks(self, track1: str, track2: str) -> None:
        """
        Swipes a given card tracks.

        :param str track1, track2: Card tracks to be encoded and swiped
        :return: None
        """
        b_raw_data = self._swiper.encode_tracks(track1, track2)
        self._swiper.swipe(track=b_raw_data)

    def read_check(self, check_name: str) -> None:
        """
        Read a given check from the CheckData.xml file.

        :param str check_name: Name of the chek from the CheckData.xml file
        :return: None
        """
        self._checkreader.read(check_name)

    def print_receipt(self) -> None:
        """
        Prints a receipt.
        """
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRINT_RECEIPT)

    def get_latest_printed_receipt(self) -> str:
        """
        Gets the latest printed receipt.

        :return str: Returns string of the receipt.
        """
        return self._printer.get_latest_printed_receipt()

    def get_all_printed_receipts(self) -> list:
        """
        Returns all the printed receipts.

        :return list: Returns a list of receipts of type string.
        """
        return self._printer.get_all_printed_receipts()

    def clear_receipts(self) -> None:
        """
        Clears all the receipts printed.
        """
        self._printer.clear_receipts()

    def get_receipt_count(self) -> int:
        """
        Method to get the number of printed receipts from the server since simulator initialization or last reset..
        """
        return self._printer.get_receipt_count()

    def print_and_wait_for_receipt(self, timeout: int = 15) -> bool:
        """
        Press the print button and wait for a receipt to make it into the proper radram.

        :param timeout: Timeout in seconds
        """
        time.sleep(0.2) # Delay for transaction tender
        orig_count = self._printer.get_receipt_count()
        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.PRINT_RECEIPT)
        return self.wait_for_receipt_count_increase(orig_count, timeout)

    def print_receipt_from_scroll_previous(self, tran_number: int = 0, timeout: int = 15) -> bool:
        """
        Press the print receipt button on Scroll previous frame, after selecting the transaction to be printed, and wait for a receipt to make it into the proper radram.

        :param tran_number: Transaction sequence number. By default 0, meaning last performed transaction.
        :param timeout: Timeout in seconds
        """
        time.sleep(0.2) # Delay for transaction tender
        orig_count = self._printer.get_receipt_count()
        menu_frame = self._control.get_menu_frame()
        if menu_frame.use_description != POSFrame.SCROLL_PREVIOUS.value:
            raise ProductError("Scroll Previous frame is not being displayed.")

        if self.get_tran_param_from_scroll_previous_line() is None:
            self.select_item_in_scroll_previous_list(transaction_sequence_number=tran_number)
        self.press_button_on_frame(POSFrame.SCROLL_PREVIOUS, POSButton.PRINT_RECEIPT)
        return self.wait_for_receipt_count_increase(orig_count, timeout)

    def wait_for_receipt_count_increase(self, orig_count: int, timeout: int = 15) -> bool:
        """
        Wait until the reported receipt count increases.
        """
        start = time.perf_counter()
        duration = 0
        count = orig_count
        while count == orig_count and duration < timeout:
            logger.info("Waiting for the receipt to print")
            count = self._printer.get_receipt_count()
            duration = time.perf_counter() - start
            time.sleep(0.1)
        if count == orig_count:
            logger.warning("Receipt did not print in {0:.3f} seconds.".format(duration))
            return False
        else:
            logger.info("Receipt printed after {0:.3f} seconds).".format(duration))
            return True

    def wait_for_transaction_item_count_increase(self, orig_count: int, timeout: int = 15) -> None:
        """
        Wait until the reported item count increases.
        """
        start = time.perf_counter()
        duration = 0
        count = orig_count
        while count == orig_count and duration < timeout:
            logger.info("Waiting for the item count to increase")
            count = self.get_transaction_item_count()
            duration = time.perf_counter() - start
            time.sleep(0.1)
        if count == orig_count:
            logger.warning("Item count did not increase in {0:.3f} seconds.".format(duration))
        else:
            logger.info("Item count increased after {0:.3f} seconds).".format(duration))

    def get_transaction_item_count(self) -> int:
        """
        Method to get the total item count in a transaction.
        """
        current_tran = self._control.get_transaction()
        return len(current_tran.item_list) if current_tran is not None else 0

    def wait_for_item_added(self, barcode: str = None, description: str = None, price: float = None, timeout: float = 3,
                               quantity: float = None, item_type: int = None, item_id: int=None, has_not_status: str = 'DELETED',
                               has_status: str = None, consolidate: bool = False, transaction: str = 'current') -> bool:
        """
        Wait until the desired item is added to the transaction or the timeout is reached.
        At least one value of barcode, description, quantity, item_type or price has to be provided.

        :param str barcode: Item's barcode
        :param str description: Item's description
        :param float price: Item's price
        :param float quantity: Item's quantity
        :param int item_type: Item's type
        :param int item_id: Item's ID
        :param str has_not_status: Report the item as not present in the transaction if it has this status
        :param str has_status: Only report the item as present in the transaction if it has this status
        :param str transaction: Which transaction should be verified. 'current' for current transaction, 'previous' for previous transaction.
        """
        logger.info("Waiting for the item to be added to the transaction")
        item_added = self.is_item_in_transaction(barcode, description, price, quantity, item_type, item_id, has_not_status,
                                              has_status, consolidate, transaction=transaction)
        start = time.perf_counter()
        duration = 0
        while not item_added and duration < timeout:
            time.sleep(0.1)
            item_added = self.is_item_in_transaction(barcode, description, price, quantity, item_type, item_id, has_not_status,
                                              has_status, consolidate, transaction=transaction)
            duration = time.perf_counter() - start

        if not item_added:
            logger.error("Item was not added in {0:.3f} seconds.".format(duration))
        return item_added

    def is_item_in_transaction(self, barcode: str=None, description: str=None, price: float=None,
                               quantity: float=None, item_type: int=None, item_id: int=None, has_not_status: str='DELETED',
                               has_status: str=None, consolidate: bool=False, transaction: Union[int, str] = "current") -> bool:
        """
        Checks if the given item is included in the current transaction.
        At least one value of barcode, description, quantity, item_type or price has to be provided.

        :param str barcode: Item's barcode
        :param str description: Item's description
        :param float price: Item's price
        :param float quantity: Item's quantity
        :param int item_type: Item's type
        :param int item_id: Item's ID
        :param str has_not_status: Report the item as not present in the transaction if it has this status
        :param str has_status: Only report the item as present in the transaction if it has this status
        :param str transaction: Which transaction should be verified. 'current' for current transaction, 'previous' for previous transaction.
        :return: True if the item is in the current POS transaction
        :rtype: bool
        :raises ProductError: If no parameter is provided
        """
        if all(x is None for x in [barcode, description, price, quantity, item_type, item_id]):
            raise ProductError("At least one of parameters - description, barcode, price. quantity, item_type, item_id - has to be provided.")


        if not isinstance(transaction, str) and not isinstance(transaction, int):
            raise ProductError('Wrong transaction type, must be str or int. Now it is type "{}"'.format(type(transaction)))

        current_tran = self.get_transaction(transaction)
        if current_tran is None:
            return False

        quantity_in_transaction = 0
        price_in_transaction = 0.0
        for item in current_tran.item_list:
            if barcode is not None and len(barcode) > 19 and not item.has_nvp({'name': 'RPOS.LongBarcodeData', 'text': barcode}):
                continue
            elif barcode is not None and len(barcode) <= 19 and item.barcode != barcode:
                continue
            elif description is not None and item.name.lower() != description.lower():
                continue
            elif item_type is not None and item.item_type != item_type:
                continue
            elif has_not_status and item.has_status(status=ItemStatuses[has_not_status]):
                continue
            elif has_status and not item.has_status(status=ItemStatuses[has_status]):
                continue
            elif item_id is not None and item.item_id != item_id:
                continue
            elif consolidate:
                quantity_in_transaction += float(item.quantity)
                price_in_transaction += float(item.price)
                continue
            elif quantity and float(quantity) != float(item.quantity):
                continue
            elif price and not math.isclose(float(item.price), float(price), rel_tol=1e-5):
                continue
            return True

        if quantity is not None and quantity_in_transaction != float(quantity):
            return False
        if price is not None and not math.isclose(price_in_transaction, float(price), rel_tol=1e-5):
            return False
        return quantity_in_transaction != 0

    def verify_transaction_total(self, total: float = None, subtotal: float = None, tax: float = None) -> bool:
        """
        Verifies the current transaction's total, subtotal and/or tax values.
        At least one of the parameters total, subtotal and tax has to be provided.

        :param float total: transaction total to verify
        :param float subtotal: transaction subtotal to verify
        :param float tax: transaction tax to verify
        :return: True if the values being verified match the expected ones
        :rtype: bool
        :raises ProductError: If there is no current transaction or when no parameter is provided
        """
        if all(x is None for x in [total, subtotal, tax]):
            raise ProductError("At least one of parameters - total, subtotal, tax - has to be provided.")

        current_tran = self._control.get_transaction()
        if current_tran is None:
            raise ProductError("There is no current transaction.")

        if total is not None and abs(current_tran.total - total) >= 0.001:
            return False
        if subtotal is not None and abs(current_tran.subtotal - subtotal) >= 0.001:
            return False
        if tax is not None and abs(current_tran.tax_amount - tax) >= 0.001:
            return False

        return True

    def lock_pos(self) -> None:
        """
        Locks the POS.
        """
        frame = self._control.get_menu_frame()
        if frame.use_description is POSFrame.TERMINAL_LOCK.value:
            return
        if frame.use_description is not POSFrame.MAIN.value:
            self.ensure_ready_to_sell()

        self.press_button_on_frame(POSFrame.RECEIPT, POSButton.OTHER_FUNCTIONS)
        self.press_button_on_frame(POSFrame.OTHER_FUNCTIONS, POSButton.LOCK)
        self._control.press_button_on_frame(POSFrame.ASK_CONFIRM_LOCK_TERMINAL, POSButton.YES)

    def unlock_pos(self, pin: int) -> None:
        """
        Attempts to unlock the POS based on the signed in cashier.
        """
        self.wait_for_frame_open(POSFrame.TERMINAL_LOCK)
        response = self._control.get_operator_info()
        override_operator = response.get('OverrideOperator', {})
        if not override_operator:
            operator_id = response.get('Operator', {}).get('ID', '')
        else:
            operator_id = override_operator.get('ID', '')
        operator_pin = self.relay_catalog.pos_man_relay.get_operators_pin(operator_id)
        if operator_pin == -1:
            operator_pin = pin
        logger.debug('Attempting to unlock POS using pin {}'.format(operator_pin))
        self.press_digits(POSFrame.TERMINAL_LOCK, operator_pin)
        self.press_button_on_frame(POSFrame.TERMINAL_LOCK, POSButton.UNLOCK)

    def current_frame_has_button(self, button: POSButton) -> bool:
        """
        Checks if the current frame has the desired button.

        :param POSButton button: The wanted button.
        :return bool: Whether the button was found or not.
        """
        frame = self._control.get_menu_frame()
        # if isinstance(button, POSButton):
        #    button = button.value
        return frame.has_button(button)

    def press_button_on_frame(self, frame:  Union[str, POSFrame], button: Union[str, POSButton]) -> None:
        """
        Press a button.

        :param frame: Frame which should contain the button.
        :param button: Button which should be pressed.
        """
        self._control.press_button_on_frame(frame=frame, button=button)

    def press_item_button(self, barcode: str) -> None:
        """
        Press an item button from the menu frame.
        :param barcode: The barcode of the button which should be used
        """
        self._control.press_button_on_frame(frame=POSFrame.MAIN, button=POSButton.SELL_BC_PREFIX, button_suffix=barcode)

    def is_signed_in(self, operator_id: int = 0, operator_name: str = "") -> bool:
        """
        Check if an operator is signed in to the POS.
        If the parameter operator_name is provided, the operator will be searched by name only.

        :param int operator_id: The operator ID of the operator. Use -1 if nobody should be signed in.
        :param str operator_name: Operator's full name. e.g. 1234, Cashier
        :return: Whether an operator is signed in.
        """
        response = self._control.get_operator_info()
        override_operator = response.get('OverrideOperator', {})
        if not override_operator:
            operator = response.get('Operator', {})
        else:
            operator = override_operator
        if operator_name != "":
            return operator.get('DisplayedName') == operator_name
        return operator.get('ID', 0) == operator_id

    def is_someone_signed_in(self) -> bool:
        """
        Check if any operator is signed in.

        :return: True if any operator is signed in.
        """
        return not self.is_signed_in(operator_id=0)

    def override_current_operator(self, pin: int) -> None:
        """
        Overrides actual user with a user from parameter.

        :param int pin: User's pin, that we want to sign in.
        """
        response = self._control.get_operator_info()
        override_operator = response.get('OverrideOperator', {})
        if not override_operator:
            operator = response.get('Operator', {})
        else:
            raise ProductError('Operator is already overriden.')
        if not operator:
            raise ProductError('No operator is signed in.')
        if operator.get('FamilyName') == str(pin):
            raise ProductError('The operator with pin {} is already signed in.'.format(pin))
        self.lock_pos()
        self.press_digits(POSFrame.TERMINAL_LOCK, pin)
        self.press_button_on_frame(POSFrame.TERMINAL_LOCK, POSButton.UNLOCK)

    def send_config(self, only_changed=True) -> None:
        """
        Submit updated relay file configuration, if any changes are pending.

        :param only_changed: If true, only send configurations with pending changes.
        """
        start = time.perf_counter()
        queue = list(self.relay_catalog.iter_update_required()) if only_changed else list(self.relay_catalog.iter_relays())
        if not queue:
            logger.debug("{0} configuration does no require any update.".format(str(self.control)))
            return
        logger.debug("{0} configuration requires update to {1}.".format(
                str(self.control),
                [relay.pos_name for relay in queue]))

        send_result = None
        availability_performance = PerfomanceCounter()
        if queue:
            with self._performance.sending_relay_files:
                send_result = self._control.send_relay_files(relay_files=queue)
        else:
            send_result = self._control.send_relay_files(relay_files=[])

        wait_for_pos = True
        if send_result.reboot_required:
            logger.debug("{0} configuration requires restart.".format(str(self.control)))
            availability_performance = self._performance.rebooting
            self._control.restart()
        elif not send_result.config_present_already:
            logger.debug("{0} configuration requires reload.".format(str(self.control)))
            self._control.reload_config()
        else:
            logger.debug("{0} configuration is already present at the node.".format(str(self.control)))
            wait_for_pos = False

        if wait_for_pos:
            available = False
            with availability_performance:
                available = self._wait_for_availability()
            if not available:
                raise ProductError("{0} configuration did not update in {1:.3f} seconds.".format(str(self.control), time.perf_counter() - start))

        logger.debug("{0} configuration applied after {1:.3f} seconds.".format(str(self.control), time.perf_counter() - start))

    def restart(self) -> None:
        """Restart the POS application."""
        start = time.perf_counter()
        self._control.restart()
        if not self._wait_for_availability():
            raise ProductError("{0} did not restart in {1:.3f} seconds".format(str(self.control), time.perf_counter() - start))
        logger.debug("{0} restarted after {1:.3f} seconds".format(str(self.control), time.perf_counter() - start))

    def wait_for_frame_open(self, frame: Union[POSFrame, str], timeout: int = 10):
        """
        Verifies a given POSFrame or a frame of given use (metadata) opens within the specified timeout.
        """
        assert self._control.wait_for_frame_open(frame, timeout), 'Desired frame {} was not opened in {} seconds, ' \
                        'frame with metadata {} is open instead.'.format(frame, str(timeout),
                        self._control.get_menu_frame().use_description)

    def wait_for_complete_prepay_finalization(self, pump: int, amount: float, timeout: float = 10):
        """
        Wait until the prepay finalization is completed.
        """
        if not self._control.wait_for_complete_prepay_finalization(pump, amount, timeout):
            raise ProductError('Prepay finalizations was not completed')
        else:
            logger.debug('Prepay finalization was completed')

    def wait_for_refund_on_pump(self, pump: int, amount: float, timeout: float = 10):
        """
        Wait until pump button displays refund with the given amount.
        """
        if not self._control.wait_for_refund_on_pump(pump, amount, timeout):
            raise ProductError('Pump button {0} did not display refund amount {1}'.format(pump, amount))
        else:
            logger.debug('Pump button {0} displayed refund amount {1}'.format(pump, amount))

    def wait_for_pes_response(self, call_type: str, call_result: str, timeout: float) -> bool:
        """
        Waits until POS receives PES action response.

        :param call_type: PES call type, allowed values are: get, finalize, sync-finalize, void
        :param call_result: PES call result, allowed values are: success, offline, pending-action, voided, missing-credentials, process-error
        :param timeout: Timeout in seconds
        :return: True if specified PES response was received in time.
        """
        return self._control.wait_for_pes_response(call_type, call_result, timeout)

    def validate_use_details(self, details: dict=None) -> bool:
        """
        Method to validate that all given parameters are present in the frame's use_details
        :param details: dictionary of details to validate
        :return: True if all supplied details were found
        """
        if details is None:
            raise ProductError('No use details were supplied to be validated')
        frame = self._control.get_menu_frame()
        result = False
        for use_detail in details:
            if use_detail not in frame.use_details.keys() or details[use_detail] not in frame.use_details.values():
                result = False
                break
            else:
                result = True
        return result

    def transfer_prepay(self, pump_id_from: int, pump_id_to: int) -> None:
        """
        Transfers prepay from one pump to another. Works only when there is only one prepay at all pumps.

        :param pump_id_from: Pump where the prepay is
        :param pump_id_to: Pump where we want to move the prepay to
        """
        self.select_pump(pump_id_from)
        # The button PUMP_START_STOP is the Transfer button, when there is active prepay on selected pump
        self.press_button_on_frame(POSFrame.MAIN, POSButton.PUMP_START_STOP)
        self.select_pump(pump_id_to)

    def select_pump(self, pump_id: int) -> None:
        """
        Selects particular pump on the fuel pump frame and checks if it is selected.
        This, however, counts with that the pump is not in non-integrated/manual mode.

        :param pump_id: A pump number which should be selected
        :return: None
        """
        pump_name = 'pump-{}'.format(pump_id)
        pump_frame = self._control.get_fuel_pumps_frame()
        assert pump_frame is not None, "Could not find pump frame!"
        self._control.press_button(pump_frame.instance_id, pump_name)

    def get_count_of_stacked_sales_on_pump(self, pump_id: int) -> int:
        """
        Getter for stacked sales on the given pump.

        :param int pump_id: Pump id, which pump should be checked.
        :return: Count of the stacked sales on the given pump.
        :rtype: int
        """
        self.select_pump(pump_id)
        fuel_pumps_frame = self._control.get_fuel_pumps_frame()

        # find the correct pump and check it exists
        for pump in fuel_pumps_frame.pumps:
            if pump_id == pump.pump_number:
                return len(pump.completed_fuel_sales)

        raise ProductError(f"No pump with id {pump_id} found on POS.")

    def verify_fuel_sale_on_pump(self, pump_id: int, sale_type: str, sale_amount: float = None) -> bool:
        """
        Verifies the fuel sale present on pump

        :param pump_id: Which pump should be checked.
        :param sale_type: Currently only postpay is supported
        :param sale_amount: Amount expected on pump
        :return: True if verified successfully
        """
        pump_frame = self._control.get_fuel_pumps_frame()
        pump = pump_frame.find_pump(pump_id)
        if pump is not None:
            if sale_type.lower() == 'postpay':
                if len(pump.completed_fuel_sales) >= 1:
                    if sale_amount is None:
                        return True
                    elif math.isclose(sale_amount, float(pump.completed_fuel_sales[-1]), rel_tol=1e-3):
                        return True
                    else:
                        logger.debug(f"Wrong sale amount {sale_amount}")
                else:
                    logger.debug(f"Missing completed sale for {sale_type}")
            else:
                logger.debug(f"Unsupported sale type {sale_type}")
        else:
            logger.debug(f"No pump with id {pump_id} found on POS.")
        return False

    def navigate_to_tenderbar_button(self, tender_button: Union[POSButton, str]) -> bool:
        """
        Method to cycle through the tender bar until the referenced tender is found or beginning is reached.
        :param tender_button: tender button to find
        """
        button_found = False
        frame = self._control.get_menu_frame()
        first_tender_button = frame.frames[1].buttons[1]
        if isinstance(tender_button, POSButton):
            tender_button = tender_button.value
        while not button_found:
            for button in frame.frames[1].buttons:
                if button.name == tender_button:
                    button_found = True
                    break
            else:
                self.press_button_on_frame(POSFrame.MAIN, POSButton.MORE)
                frame = self._control.get_menu_frame()
                if len(frame.frames[1].buttons) > 1:
                    if first_tender_button.name == frame.frames[1].buttons[1].name:
                        break
        return button_found

    def navigate_to_tender_group_button(self, tender_button: str) -> bool:
        """
        Method to find a given tender button in a tender group grid.
        TODO: the frame currently displays all buttons as not part of a grid and lists even buttons on the next pages
        non-python dev effort will be required and a separate item will be created.
        """
        return True

    def convert_tender_type_to_button_use(self, tender_type: str) -> str:
        """
        Helper method to convert a given tender type to the new format of tender button use.
        :param tender_type: Tender to convert
        :return: use_description of the corresponding tender button
        """
        if tender_type.lower() == 'cash':
            tender_button = POSButton.TENDER_CASH.value
        elif tender_type.lower() == 'credit':
            tender_button = POSButton.TENDER_CREDIT.value
        elif tender_type.lower() == 'debit':
            tender_button = POSButton.TENDER_DEBIT.value
        elif tender_type.lower() == 'check':
            tender_button = POSButton.TENDER_CHECK.value
        elif tender_type.lower() == 'gift certificate':
            tender_button = POSButton.TENDER_GIFT_CERTIFICATE.value
        elif tender_type.lower() == 'manual imprint':
            tender_button = POSButton.TENDER_MANUAL_IMPRINT.value
        elif tender_type.lower() == 'food stamps':
            tender_button = POSButton.TENDER_FOOD_STAMPS.value
        else:
            raise ProductError('Given tender type "{}" is missing its ID')
        return tender_button

    def convert_tender_group_to_button_use(self, tender_group_id: str) -> str:
        """
        Helper method to convert a given tender group id to the new format of tender button use.
        :param tender_group_id: Tender group id to convert to button metadata
        :return: use_description of the corresponding tender button
        """
        tender_button = POSButton.TENDER_GROUP_PREFIX.value + tender_group_id
        return tender_button

    def select_tender_from_tenderbar(self, tender_button: Union[POSButton, str],
                                     tender_button_fallback: Union[POSButton, str] = None) -> None:
        """
        Method to find and press a given tender button on the tender bar. A fallback value is attempted if the given
        button is not found and fallback button name is given.
        """
        if not self.navigate_to_tenderbar_button(tender_button) and tender_button_fallback is not None:
            logger.warning(
                "Tender button '{}' wasn't found. Trying to use '{}' button.".format(tender_button, tender_button_fallback))
            tender_button = tender_button_fallback
            self.navigate_to_tenderbar_button(tender_button)
        self._control.press_button_on_frame(POSFrame.MAIN, tender_button)

    def select_tender_group_from_tenderbar(self, tender_group_id: str) -> None:
        """
        Method to find and press the tender group button of a given ID on the tender bar.
        """
        tender_group_button = self.convert_tender_group_to_button_use(tender_group_id)
        assert self.navigate_to_tenderbar_button(tender_group_button)
        self._control.press_button_on_frame(POSFrame.MAIN, tender_group_button)
        self.wait_for_frame_open(POSFrame.SELECT_TENDER_FROM_GROUP)

    def select_tender_from_tender_group(self, tender_button: str):
        """
        Method to find and press the given tender button in an already opened tender group frame.
        """
        assert self.navigate_to_tender_group_button(tender_button)
        self._control.press_button_on_frame(POSFrame.SELECT_TENDER_FROM_GROUP, tender_button)

    def delete_all_stored_transactions(self) -> None:
        """
        Delete all stored transactions.

        :return: None
        """
        self._control.delete_all_stored_transactions()

    def get_pes_configuration(self) -> dict:
        """
        Get pes configuration

        :return: Dict
        """
        configuration = self._sc.get_pes_configuration()

        regex = '(?P<protocol>http.?)(:\/\/)(?P<host>[^:\/]+)(:?)(?P<port>[0-9]*).*'

        m = re.search(regex, configuration.get('baseServiceUrl', None))
        configuration['protocol'] = m.group('protocol')
        configuration['hostName'] = m.group('host')
        configuration['hostPort'] = m.group('port')
        configuration.pop('baseServiceUrl', None)
        configuration['secretKey'] = self.pes_encrypt_key(configuration.get('secretKey', 'defaultkey'))

        return configuration

    def set_pes_configuration(self, json: dict) -> None:
        """
        Set pes configuration

        :return: None
        """

        self._sc.set_pes_configuration({"credentials": json})

    def reset_pes_configuration(self) -> None:
        """
        Reset pes configuration

        :return: None
        """

        self._sc.reset_pes_configuration()

    def create_pes_configuration_file(self) -> None:
        """
        Create a configuration json if it does not exist

        :return: None
        """
        if not path.isfile(self._pes_configuration_path):
            configuration = self.get_pes_configuration()
            if configuration:
                with open(self._pes_configuration_path, 'w') as fp:
                    json.dump(configuration, fp)

    def delete_pes_configuration_file(self) -> None:
        """
        Delete a configuration json

        :return: None
        """
        if path.isfile(self._pes_configuration_path):
            remove(self._pes_configuration_path)

    def pes_configuration_file_exists(self) -> bool:
        """
        Verifies that a configuration json exists

        :return: bool
        """
        return path.exists(self._pes_configuration_path)

    def pes_configuration_file_contains(self, expected_configuration: dict) -> bool:
        """
        Verifies that a configuration file contains specific values

        :return: bool
        """
        with open(self._pes_configuration_path) as json_file:
            configuration = json.load(json_file)

            for key, value in expected_configuration.items():
                assert configuration.get(key, False), 'key {} does not exist'.format(key)
                if (key == 'secretKey'):
                    encrypted_key = configuration[key]
                    configuration[key] = self.pes_decrypt_key(encrypted_key) # Decrypt secret key that is saved in PES configuration file
                assert str(configuration[key]) == value, 'values are not equal, {} != {}'.format(configuration[key], value)

        return True

    def pes_encrypt_key(self, key: str) -> str:
        """Encrypt the PES secret key as DirectPesApi would

        :param key: Key string
        :return: Encrypted key
        """
        key_data = key.encode('utf-8')
        encrypted_key_data = win32crypt.CryptProtectData(key_data, None, None, None, None, 0)
        base64_encrypted_key_data = base64.b64encode(encrypted_key_data)
        key_encrypted = base64_encrypted_key_data.decode('utf-8')
        return key_encrypted

    def pes_decrypt_key(self, key_encrypted: str) -> str:
        """Decrypt the PES secret key as DirectPesApi would

        :param key_encrypted: Encrypted key string
        :return: Decrepted key
        """
        key_encrypted_data = key_encrypted.encode('utf-8')
        base64_key_encrypted_data = base64.b64decode(key_encrypted_data)
        description, key_data = win32crypt.CryptUnprotectData(base64_key_encrypted_data, None, None, None, 0)
        key = key_data.decode('utf-8')
        return key

    def wait_for_prepay_finalization(self) -> None:
        """
        Start waiting for prepay finalization.

        :return: None
        """
        self._control.begin_waiting_for_event("complete-prepay-finalization")

    def create_radgcm_reg_entry_for_pes(self) -> None:
        """
        Creates RadGCM pluginIn registry for pes card if it does not exist.

        :return: None
        """
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\RadiantSystems\RadGCM\PlugInDLLs\PES') as radgcm_key:
            winreg.SetValueEx(radgcm_key, 'DllName', 0, winreg.REG_SZ, 'PESGCMPlugin.dll')
            winreg.SetValueEx(radgcm_key, 'SortOrder', 0, winreg.REG_SZ, '225')

    def create_radgcm_reg_entry_for_mrd(self) -> None:
        """
        Creates RadGCM pluginIn registry for mrd card if it does not exist.

        :return: None
        """
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, r'Software\RadiantSystems\RadGCM\PlugInDLLs\MRD') as radgcm_key:
            winreg.SetValueEx(radgcm_key, 'DllName', 0, winreg.REG_SZ, 'MRDGCMPlugin.dll')
            winreg.SetValueEx(radgcm_key, 'SortOrder', 0, winreg.REG_SZ, '200')

    def collect_performance(self) -> PerformanceStats:
        """
        Collects current performance statistics.

        :return: PerformanceStats
        """
        performance = PerformanceStats()
        performance.add(self._performance)
        performance.add(self.relay_catalog.collect_performance())
        return performance
