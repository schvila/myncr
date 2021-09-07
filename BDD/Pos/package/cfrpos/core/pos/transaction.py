__all__ = [
    "Transaction",
    "TransactionItem"
]


from typing import Optional
from datetime import datetime
from lxml import etree

from . item import Item
from .. bdd_utils.pos_utils import POSUtils
from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.errors import ProductError


@wrap_all_methods_with_log_trace
class Transaction:
    """
    This class represents a POS transaction
    """

    def __init__(self,
                 sequence_number: int,
                 total: float,
                 subtotal: float,
                 tax_amount: float,
                 balance: float,
                 item_list: Optional[list],
                 terminal_id: int,
                 tran_end_time: datetime,
                 age_verification_type: int,
                 header_nvps: Optional[list],
                 credit_nvps: Optional[list],
                 epsilon_tran_numbers: Optional[list],
                 order_system_id: str,
                 order_reference: str):
        self.sequence_number = sequence_number
        self.total = round(total, 2)
        self.subtotal = round(subtotal, 2)
        self.tax_amount = round(tax_amount, 2)
        self.balance = round(balance, 2)
        self.item_list = item_list
        self.terminal_id = terminal_id
        self.tran_end_time = tran_end_time
        self.age_verification_type = age_verification_type
        self.header_nvps = header_nvps
        self.credit_nvps = credit_nvps
        self.epsilon_tran_numbers = epsilon_tran_numbers
        self.order_system_id = order_system_id
        self.order_reference = order_reference

    @classmethod
    def from_dict(cls, source: dict) -> "Transaction":
        """
        Deserialize dictionary into the Transaction object.

        :param source: Dictionary with the serialized transaction.
        :return: Deserialized transaction
        :rtype: Transaction
        """
        item_list = [TransactionItem.from_dict(item) for item in source["ItemList"]]

        return Transaction(
            sequence_number=int(source["SequenceNumber"]),
            total=source["Total"],
            subtotal=source["Subtotal"],
            tax_amount=source["TaxAmount"],
            balance=source["Balance"],
            item_list=item_list,
            terminal_id=source["terminal_id"],
            tran_end_time=source["tran_end_time"],
            age_verification_type=source["age_verification_type"],
            header_nvps=source["header_NVP"],
            credit_nvps=source["credit_NVP"],
            epsilon_tran_number=source["EpsilonTranNumbers"],
            order_system_id=source["OrderSystemId"],
            order_reference=source["OrderReference"]
        )

    def to_dict(self) -> dict:
        """
        Serializes the transaction into the dictionary

        :return: Serialized transaction in dictionary.
        :rtype: dict
        """
        final_item_list = []
        for item_from_self in self.item_list:
            final_item_list.append(item_from_self.to_dict())

        return {
            "SequenceNumber": self.sequence_number,
            "Total": self.total,
            "Subtotal": self.subtotal,
            "TaxAmount": self.tax_amount,
            "Balance": self.balance,
            "OrderSystemId": self.order_system_id,
            "OrderReference": self.order_reference,
            "EpsilonTranNumbers": self.epsilon_tran_numbers,
            "ItemList": final_item_list
        }

    @classmethod
    def from_xml(cls, xml: str) -> "Transaction":
        """
        Initialize transaction according to parameters obtained in the input XML in the string value

        :param str xml: XML representation of the transaction
        :return: Initialized transaction
        :rtype: Transaction
        """
        return Transaction.from_xml_element(etree.XML(xml))

    @classmethod
    def from_xml_element(cls, root: etree._Element) -> "Transaction":
        """
        Initialize transaction according to values obtained from the XML element

        :param root: Root XML element which represents the transaction
        :return: initialized transaction
        :rtype: Transaction
        """
        list_of_header_nvps = POSUtils.get_nvp_info(root, "/LHPersistentTran/Header/NVPs/NVP")
        list_of_credit_nvps = POSUtils.get_nvp_info(root, "/LHPersistentTran/Credit/NVPs/NVP")

        item_list = [TransactionItem.from_xml_element(element) for element in root.xpath("/LHPersistentTran/Detail")]
        debit_total = POSUtils.convert_pos_amount_to_float(root.xpath(
            "/LHPersistentTran/Header/DebitTotal[1]/text()")[0])
        tax_total = POSUtils.convert_pos_amount_to_float(root.xpath(
            "/LHPersistentTran/Header/TaxTotal[1]/text()")[0])
        credit_total = POSUtils.convert_pos_amount_to_float(root.xpath(
            "/LHPersistentTran/Header/CreditTotal[1]/text()")[0])
        discount_total = POSUtils.convert_pos_amount_to_float(root.xpath(
            "/LHPersistentTran/Header/DiscountTotal[1]/text()")[0])
        service_charge_total = POSUtils.convert_pos_amount_to_float(root.xpath(
            "/LHPersistentTran/Header/ServiceChargeTotal[1]/text()")[0])
        non_merch_credit_total = POSUtils.convert_pos_amount_to_float(root.xpath(
            "/LHPersistentTran/Header/NonMerchCreditTotal[1]/text()")[0])
        terminal_id = root.xpath("/LHPersistentTran/Header/TerminalId[1]/text()")[0]
        tran_end_time = datetime.strptime(root.xpath("/LHPersistentTran/Header/EndTime[1]/text()")[0], "%Y-%m-%dT%H:%M:%S.%f")
        age_verification_type = root.xpath("/LHPersistentTran/Header/AgeVerificationType[1]/text()")[0]
        order_system_id = root.xpath("/LHPersistentTran/Header/OrderSystemId[1]/text()")[0] if len(root.xpath("/LHPersistentTran/Header/OrderSystemId[1]/text()")) > 0 else None
        order_reference = root.xpath("/LHPersistentTran/Header/OrderReference[1]/text()")[0] if len(root.xpath("/LHPersistentTran/Header/OrderReference[1]/text()")) > 0 else None
        epsilon_tran_numbers = None
        if len(root.xpath("/LHPersistentTran/Credit")) and len(root.xpath("/LHPersistentTran/Credit/EpsilonTranNumber")):
                epsilon_tran_numbers = [int(number) for number in root.xpath("/LHPersistentTran/Credit/EpsilonTranNumber[1]/text()")]

        return Transaction(
            sequence_number=int(root.xpath("/LHPersistentTran/Header/TranSequenceNumber[1]/text()")[0]),
            total=debit_total + tax_total + discount_total + service_charge_total + non_merch_credit_total,
            subtotal=debit_total + discount_total,
            tax_amount=tax_total,
            balance=debit_total + tax_total + discount_total + credit_total + service_charge_total,
            item_list=item_list,
            terminal_id=terminal_id,
            tran_end_time=tran_end_time,
            age_verification_type=age_verification_type,
            header_nvps=list_of_header_nvps,
            credit_nvps=list_of_credit_nvps,
            epsilon_tran_numbers=epsilon_tran_numbers,
            order_system_id=order_system_id,
            order_reference=order_reference
        )

    def has_tran_nvp(self, nvp: dict, section: str = 'header') -> bool:
        """
        Method to check whether the transaction has the nvp that is supplied as parameter in the given section.

        :param section: Transaction section to check, supported values are header and credit.
        :param nvp: NVP to check together with all its attributes.
        :return: True if the NVPs are/is found with proper values.
        """
        if type(nvp) is str:
            nvp = eval(nvp)

        if section.lower() == 'header':
            nvp_found = self._has_nvp(nvp, self.header_nvps)
        elif section.lower() == 'credit':
            nvp_found = self._has_nvp(nvp, self.credit_nvps)
        else:
            raise ProductError("Wrong section argument is used, supported values are 'credit' and 'header'.")
        return nvp_found

    def _has_nvp(self, nvp: dict, tran_nvps: list) -> bool:
        """
        Method to check whether the item has the nvp that is supplied as parameter in the given section.

        :param nvp: NVP to check together with all its attributes.
        :param tran_nvps: List of either header or credit transaction NVPs to be inspected.
        :return: True if the NVP is found with proper values.
        """
        nvp_found = False
        if type(nvp) is str:
            nvp = eval(nvp)

        for tran_nvp in tran_nvps:
            for attr in nvp:
                if attr in tran_nvp and nvp[attr] == tran_nvp[attr]:
                    nvp_found = True
                else:
                    nvp_found = False
                    break
            else:
                return nvp_found
        return nvp_found

    def has_item_nvp(self, item_name: str, nvp: dict) -> bool:
        """
        Method to check if in the transaction there is an item detail containing given nvp.
        :param item_name: Item with given name to be checked for existing nvps.
        :param nvp: NVP to check together with all its attributes.
        """
        nvp_found = False
        if type(nvp) is str:
            nvp = eval(nvp)

        for item in self.item_list:
            if item.name.lower() == item_name:
                nvp_found = self._has_nvp(nvp, item.nvps)
                break
        return nvp_found

    def has_tran_nvp_with_element(self, element_name: str, element_value: str, section: str):
        """
        Method to check if transaction nvps contain nvp with given element name and value.
        :param element_name: Name of the nvp element to be checked.
        :param element_name: Value of the nvp element to be checked.
        :param section: Transaction section to check, supported values are header and credit.
        """

        if section.lower() == 'header':
            nvps = self.header_nvps
        elif section.lower() == 'credit':
            nvps =  self.credit_nvps

        for nvp in nvps:
            if self._has_nvp_element(element_name, element_value, nvp):
                return True
        return False

    def _has_nvp_element(self, element_name: str, element_value: str, nvp: dict):
        """
        Method to check if nvp contains element with given name and value.
        :param element_name: Name of the nvp element to be checked.
        :param element_name: Value of the nvp element to be checked.
        :param nvp: NVP to be checked if contains element name with the given value.
        """

        element_found = False
        if element_name in nvp.keys() and nvp[element_name] == element_value:
            element_found = True
        return element_found

    def check_fuel_metrics(self, fuel_item_name: str, should_be_included: bool) -> bool:
        """
        Method to check the presence of fuel metrics NVP in the fuel item.
        :param fuel_item_name: Name of the fuel item
        :param should_be_included: True if the fuel metrics should be present, False otherwise
        """

        if self.has_item_nvp(item_name=fuel_item_name.lower(), nvp="{'name': 'RPOS.FuelMetrics.FuelingHandleLiftDateTime', 'type': '3', 'persist': 'true'}") != should_be_included:
            return False
        if self.has_item_nvp(item_name=fuel_item_name.lower(), nvp="{'name': 'RPOS.FuelMetrics.FuelingHandleReplaceDateTime', 'type': '3', 'persist': 'true'}") != should_be_included:
            return False
        if self.has_item_nvp(item_name=fuel_item_name.lower(), nvp="{'name': 'RPOS.FuelMetrics.FuelingDispenseStartDateTime', 'type': '3', 'persist': 'true'}") != should_be_included:
            return False
        if self.has_item_nvp(item_name=fuel_item_name.lower(), nvp="{'name': 'RPOS.FuelMetrics.FuelingDispenseEndDateTime', 'type': '3', 'persist': 'true'}") != should_be_included:
            return False
        if self.has_item_nvp(item_name=fuel_item_name.lower(), nvp="{'name': 'RPOS.FuelMetrics.FuelingStartReading', 'type': '4', 'persist': 'true'}") != should_be_included:
            return False
        if self.has_item_nvp(item_name=fuel_item_name.lower(), nvp="{'name': 'RPOS.FuelMetrics.FuelingEndReading', 'type': '4', 'persist': 'true'}") != should_be_included:
            return False
        return True


@wrap_all_methods_with_log_trace
class TransactionItem(Item):
    """
    This class represents an item that is on a POS transaction
    """

    def __init__(self,
                 item_number: int,
                 quantity: float,
                 **kwargs):
        super().__init__(**kwargs)
        self.item_number = item_number
        self.quantity = quantity

    @classmethod
    def from_dict(cls, source: dict) -> "TransactionItem":
        """
        Deserialize dictionary into the TransactionItem object.

        :param source: Dictionary with the serialized transaction item.
        :return: Deserialized transaction item
        :rtype: TransactionItem
        """
        item = super().from_dict(source)

        return TransactionItem(
            item_number=source["ItemNumber"],
            quantity=float(source["Quantity"]),
            **item.__dict__
        )

    @classmethod
    def from_xml_element(cls, root: etree._Element) -> "TransactionItem":
        """
        Initialize transaction according to values obtained from the XML element

        :param root: Root XML element which represents the transaction item
        :return: initialized transaction item
        :rtype: TransactionItem
        """
        item = super().from_xml_element(root)
        qty_list = root.xpath("./Quantity[1]/text()")
        qty = 0 if not qty_list else float(qty_list[0])
        return TransactionItem(
            item_number=int(POSUtils.first_or_default(root.xpath("./ItemNumber[1]/text()"), 0)),
            quantity=qty,
            **item.__dict__
        )

    def to_dict(self) -> dict:
        """
        Serializes the transaction item into the dictionary

        :return: Serialized transaction item in dictionary.
        :rtype: dict
        """
        full_dict = super().to_dict()
        full_dict["ItemNumber"] = self.item_number
        full_dict["Quantity"] = self.quantity

        return {
            key: value for key, value in full_dict.items()
            if value is not None
            }
