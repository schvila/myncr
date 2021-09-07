"""This module contains base functions for POS testing."""
import os
import psutil
import random
import subprocess

from typing import Union
from . pos_services import *
from xml.etree import ElementTree
from cfrpos.core.bdd_utils.errors import *
from cfrpos.core.bdd_utils.logging_utils import get_ev_logger, wrap_all_methods_with_log_trace


__all__ = ["PosServicesControl"]


POS_SERVICES_DEFAULT_BIN_DIR = 'C:\\Program Files\\Radiant\\Fastpoint\\Bin'
POS_SERVICES_DEFAULT_BINARY = 'SCPOSServicesSimulator.exe'


@wrap_all_methods_with_log_trace
class PosServicesControl:
    def __init__(self, config):
        super().__init__()

        self._bin_dir = config.get('bin_dir', POS_SERVICES_DEFAULT_BIN_DIR)
        self._binary = config.get('binary', POS_SERVICES_DEFAULT_BINARY)
        self._binary_file_path = os.path.join(self._bin_dir, self._binary)

        self._address = config.get('address', '127.0.0.1')
        self._port = config.get('port', 8900)
        self._pesport = config.get('pesport', 8000)
        self._python_script_path = None
        self._http = PosServiceHandler(hostname=self._address, port=self._port)
        self._pes_http = PosPesServiceHandler(hostname=self._address, port=self._pesport)
        self._data_folder = config.get('api').get('sc_sim').get('data', os.path.join(os.getcwd(), 'core', 'simulators', 'sc_sim', 'data'))
        self.logger = get_ev_logger()

    def __str__(self):
        """Return string description."""
        return "SC POS Service Simulator"

    @property
    def binary(self):
        """Name of the binary required by this controller."""
        if self._python_script_path is None:
            return self._binary
        else:
            return None

    @property
    def bin_dir(self):
        """Name of the folder containing the required binary."""
        return self._bin_dir

    def is_active(self):
        """Checks whether SC POS Service Simulator interface is active."""
        return self.is_available() and self.is_running() and self.is_listening()

    def is_available(self) -> bool:
        return os.path.isfile(self._binary_file_path)

    def is_running(self) -> bool:
        return self._find_simulator_process() is not None

    def is_listening(self) -> bool:
        if not self.is_running():
            return False
        try:
            self._http.get('/POSServicesConfiguration/Server/State')
        except ProductError:
            logger.exception('Server is not available')
            return False
        return True

    def start(self, environment: dict):
        """
        Starts the SCPosServicesSimulator

        :param environment: Dictionary with the environmental variables
        """
        process = self._find_simulator_process()
        if process is None:
            info = subprocess.STARTUPINFO()
            info.dwFlags = subprocess.STARTF_USESHOWWINDOW
            # 6 means SW_MINIMIZE
            info.wShowWindow = 6
            process = subprocess.Popen(
                    [
                        self._binary_file_path,
                        '/a:{}'.format(self._address),
                        '/p:{}'.format(self._port)],
                    cwd=self._bin_dir,
                    creationflags=subprocess.CREATE_NEW_CONSOLE,
                    startupinfo=info,
                    env=environment)
        return process

    def stop(self) -> bool:
        """
        Stops the SCPosServicesSimulator.
        """
        process = self._find_simulator_process()

        if process is None:
            return True

        self._http.get('/POSServicesConfiguration/Server/Shutdown')

        try:
            process.wait(30)
            return True

        except psutil.TimeoutExpired:
            process.kill()
            return False

    def _find_simulator_process(self) -> Union[psutil.Popen, None]:
        app_name = os.path.basename(self._binary_file_path).upper()
        debug_app_name = (os.path.splitext(app_name)[0] + '.vshost').upper()
        for process in self._enumerate_processes():
            process_name = process.name().upper()
            if process_name == app_name and not process_name.startswith(debug_app_name):
                return process

        return None

    def _enumerate_processes(self):
        return psutil.process_iter()

    def close_pos_shift(self, node):
        """
        Closes the shift on node with given number.

        :param node: Node number on which shift should be closed.
        """
        day = self._http.get_current_business_day()
        operator = self._http.get_pos_operator(node)
        shift = self._http.get_operator_shift_number(operator, day)
        self._http.set_operator_status(operator, day, shift, ShiftStatus.SIGNED_OUT, node)
        self._http.set_operator_status(operator, day, shift, ShiftStatus.CLOSED, node)


    def inject_transaction(self, credit_amount: float = None, discount_amount: float = None, pump_number: int = None,
                           volume: float = 10.00, pap: str = False, pes: str = False, tran_xml: str = None):
        """
        Creates a next transaction that will be accessible in scroll previous list. The created transaction can be pes or non-pes PAP transaction,
        or a non-fuel transaction performed on some other node.

        :param credit_amount: $ value of dispensed amount tendered with credit.
        :param discount_amount: $ value of dispensed amount tendered with discounts.
        :param pump_number: Pump number on which PAP transaction should be performed.
        :param volume: Volume of dispensed fuel.
        :param pap: True if PAP transaction should be created.
        :param pes: True if PES transaction should be created.
        :param tran_xml: Transaction xml file. If not None, will be used directly for creating transaction without modifying.
        """
        if pap and pes:
            path = os.path.join(self._data_folder, 'pes_pap_transaction.xml')
            tree = self._modify_tran_xml(ElementTree.parse(path), credit_amount, discount_amount, pump_number, volume)
        elif pap and not pes:
            path = os.path.join(self._data_folder, 'pap_transaction.xml')
            tree = self._modify_tran_xml(ElementTree.parse(path), credit_amount, discount_amount, pump_number, volume)
        elif tran_xml is not None:
            path = os.path.join(self._data_folder, tran_xml)
            tree = ElementTree.parse(path)
        else:
            raise ProductError("There is no xml file loaded so the transaction can not be created.")

        self._create_tran_placeholder(transaction=tree.getroot())
        self._update_existing_tran(transaction=tree.getroot())


    def _modify_tran_header(self, tree: ElementTree.ElementTree, credit_amount: float, discount_amount: float = None, pump_number: int = None, volume: float = 10.00):
        """
        Modifies header section of the transaction xml based on the given parameters.

        :param credit_amount: $ value of dispensed amount tendered with credit.
        :param discount_amount: $ value of dispensed amount tendered with discounts.
        :param pump_number: Pump number on which PAP transaction should be performed.
        :param volume: Volume of dispensed fuel.
        """
        header = tree.getroot().find('Header')
        if pump_number is not None:
            for pump_el in ['CompletedPump', 'TerminalId']: header.find(pump_el).text = str(pump_number)
            header.find('CreditTotal').text = str(-int(credit_amount*10000))
            if discount_amount is not None:
                header.find('DebitTotal').text = str(int(discount_amount*10000 + credit_amount*10000))
                header.find('DiscountTotal').text = str(-int(discount_amount*10000))
            else:
                header.find('DebitTotal').text = str(int(credit_amount*10000))
        return tree

    def _modify_tran_details(self, tree: ElementTree.ElementTree, credit_amount: float, discount_amount: float = None, pump_number: int = None, volume: float = 10.00):
        """
        Modifies transaction detail section based on the given parameters.

        :param tree: Transaction xml to be modified.
        :param credit_amount: $ value of dispensed amount tendered with credit.
        :param discount_amount: $ value of dispensed amount tendered with discounts.
        :param pump_number: Pump number on which PAP transaction should be performed.
        :param volume: Volume of dispensed fuel.
        """
        for el in tree.getroot():
            if el.tag == 'Detail' and el.find('Description').text == 'Credit':
                for price_el in ['UnitPrice', 'ExtendedPrice']: el.find(price_el).text = str(-int(credit_amount*10000))
            elif el.tag == 'Detail' and el.find('Description').text == 'EMReward':
                for price_el in ['UnitPrice', 'ExtendedPrice']: el.find(price_el).text = str(-int(discount_amount*10000))
            elif el.tag == 'Detail' and el.find('Description').text == 'Regular':
                for fuel_el in ['ExtendedQuantity', 'Quantity']: el.find(fuel_el).text = str(volume)
                el.find('PumpNumber').text = str(pump_number)
                if discount_amount is not None:
                    el.find('ExtendedPrice').text = str(int(discount_amount*10000 + credit_amount*10000))
                else:
                    el.find('ExtendedPrice').text = str(int(credit_amount*10000))
        return tree

    def _modify_tran_number(self, tree: ElementTree.ElementTree):
        """
        Modify transaction number in transaction xml.

        :param tree: Transaction xml to be modified.
        """
        tran_number = random.randrange(100)
        for el in tree.getroot():
            if el.find('TranSequenceNumber') is not None:
                el.find('TranSequenceNumber').text = str(tran_number)
        return tree

    def _modify_tran_xml(self, transaction: ElementTree.ElementTree, credit_amount: float, discount_amount: float = None, pump_number: int = None, volume: float = 10.00):
        """
        Modifies transaction xml based on the given parameters.

        :param transaction: Transaction xml to be modified.
        :param credit_amount: $ value of dispensed amount tendered with credit.
        :param discount_amount: $ value of dispensed amount tendered with discounts.
        :param pump_number: Pump number on which PAP transaction should be performed.
        :param volume: Volume of dispensed fuel.
        """
        tran_header = self._modify_tran_header(transaction, credit_amount, discount_amount, pump_number, volume)
        tran_details = self._modify_tran_details(tran_header, credit_amount, discount_amount, pump_number, volume)
        tree = self._modify_tran_number(tran_details)

        return tree

    def _create_tran_placeholder(self, transaction: ElementTree.ElementTree) -> None:
        """
        Creates a next transaction in scroll previous based on the provided header of transaction xml.

        :param transaction: Transaction xml from which header should be used to create a placeholder in scroll previous list.
        """
        header = transaction.find('Header')

        header_request = '<Headers>' + ElementTree.tostring(header, encoding='unicode', method='xml').rstrip() + '</Headers>'
        tran_json = {
                    "Result": 0,
                    "ResultXML": header_request.replace("'",'')
                    }
        self._http.post('/Configuration/PSTranAccess/GetNextOrPrevNTranRevisionsHeaders/response', json = tran_json)

    def _update_existing_tran(self, transaction: ElementTree.ElementTree) -> None:
        """
        Fills a content of created transaction in scroll previous list. Requires whole transaction xml.

        :param transaction: Transaction xml that should be used as a content of created transaction in scroll previous list.
        """
        tran_request = ElementTree.tostring(transaction, encoding='unicode', method='xml').rstrip()
        tran_json = {
                    "Result": 0,
                    "ResultXML": tran_request
                    }
        self._http.post('/Configuration/PSTranAccess/GetTransactionRevision/response', json = tran_json)

    def reset_sim_requests(self) -> None:
        """
        Resets requests sent to the simulator.
        """
        self._http.delete('/Configuration/PSTranAccess/GetNextOrPrevNTranRevisionsHeaders/response')
        self._http.delete('/Configuration/PSTranAccess/GetTransactionRevision/response')

    def reset_tran_repository(self) -> None:
        """
        Resets transaction repository, so the transactions from scroll previous list are being deleted.
        """
        self._http.delete('/Configuration/capture-tran-repository')

    def get_pes_configuration(self):
        return self._pes_http.get_pes_configuration()

    def set_pes_configuration(self, json: dict):
        return self._pes_http.set_pes_configuration(json)

    def reset_pes_configuration(self):
        return self._pes_http.reset_pes_configuration()