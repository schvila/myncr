__all__ = [
    "Item",
    "ItemStatuses"
]

import enum
from typing import Optional

from lxml.etree import _Element

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.pos_utils import POSUtils


@wrap_all_methods_with_log_trace
class ItemStatuses(enum.Enum):
    """
    Item statuses from RPOS PosConstants.h.
    """
    RESERVED = 0x80000000
    EDITED = 0x40000000
    CONSOLIDATED = 0x20000000
    DELETED = 0x10000000
    CANCELLED_TRAN = 0x08000000
    REPLACED = 0x04000000
    ADDED = 0x02000000
    ORIGINAL_ITEM = 0x01000000
    TRAINING_TRAN = 0x00800000
    TAX_CHANGED = 0x00400000
    AUTO_DELETED = 0x00200000
    DO_NOT_DISPLAY = 0x00100000
    REFUND_TRAN = 0x00040000
    WAITING_FOR_TIP_AMOUNT = 0x00020000
    MOVED = 0x00010000
    SMART_PREPAY_OVERPAY = 0x00008000
    LOYALTY_ADDED_POST_TENDER = 0x00004000
    IGNORE_PRICE = 0x00002000
    MANUAL_PRICE_OVERRIDE = 0x00001000
    PRINT_VOIDED = 0x00000040
    DRINK_DISPENSED = 0x00000020
    SUB_ITEMS_REPLACED = 0x00000010
    QUANTITY_CHANGED = 0x00000008
    MODIFIER_ADDED = 0x00000004
    LEVEL1_MODIFIED = 0x00000002
    PRICE_CHANGED = 0x00000001


@wrap_all_methods_with_log_trace
class Item:
    """
    This class represents a POS item
    """

    def __init__(self,
                 name: str,
                 barcode: Optional[str],
                 price: float,
                 external_id: Optional[str],
                 tender_itemizer_rank: Optional[int],
                 age_minimum: int,
                 mode: int,
                 status: list,
                 item_type: int,
                 item_id: int,
                 modifier_id_1: int,
                 modifier_id_2: int,
                 modifier_id_3: int,
                 credit_code: Optional[int],
                 nvps: Optional[list]):
        self.name = name
        self.barcode = barcode
        self.price = price
        self.external_id = external_id
        self.tender_itemizer_rank = tender_itemizer_rank
        self.age_minimum = age_minimum
        self.status = status
        self.mode = mode
        self.item_type = item_type
        self.item_id = item_id
        self.modifier_id_1 = modifier_id_1
        self.modifier_id_2 = modifier_id_2
        self.modifier_id_3 = modifier_id_3
        self.credit_code = credit_code
        self.nvps = nvps

    def __eq__(self, other: "Item") -> bool:
        # Require same instance attributes
        if other.__dict__.keys() != self.__dict__.keys():
            return False

        for key, value in other.__dict__.items():
            if value is None or self.__dict__[key] is None:
                # None means match anything
                continue

            if value != self.__dict__[key]:
                return False

        return True

    def __ne__(self, other: "Item") -> bool:
        return not self.__eq__(other)

    @classmethod
    def from_dict(cls, source: dict) -> Optional["Item"]:
        """
        Initializes item's object with values obtained from the dictionary

        :param dict source: Dictionary which represents an item
        :return: Created item
        :rtype: Item or None
        """
        if source is not None and source != {}:
            return Item(
                name=source.get("Name"),
                barcode=source.get("Barcode"),
                price=source.get("Price"),
                external_id=source.get("ExternalId"),
                tender_itemizer_rank=source.get("TenderItemizerRank"),
                age_minimum=source.get("AgeMinimum"),
                status=source.get("Status"),
                mode=source.get("Mode"),
                item_type=source.get("ItemType"),
                item_id=source.get("ItemId"),
                modifier_id_1=source.get("ModifierId1"),
                modifier_id_2=source.get("ModifierId2"),
                modifier_id_3=source.get("ModifierId3"),
                credit_code=source.get("CreditCode"),
                nvps=source.get("NVP")
            )
        else:
            return None

    @classmethod
    def from_xml_element(cls, root: _Element) -> Optional["Item"]:
        """
        Initializes item's object with values obtained from the XML

        :param _Element root: The XML with the Item's representation
        :return: Created item
        :rtype: Item or None
        """
        if root is None:
            return None

        raw_status = int(POSUtils.first_or_default(root.xpath("./Status[1]/text()"), 0))
        statuses = []
        for status in ItemStatuses:
            if (raw_status & status.value) == status.value:
                statuses.append(status)

        list_of_item_nvps = POSUtils.get_nvp_info(root, "./NVPs/NVP")

        return Item(
            name=POSUtils.first_or_default(root.xpath("./Description[1]/text()"), ""),
            barcode=POSUtils.first_or_default(root.xpath("./Barcode[1]/text()"), ""),
            price=POSUtils.convert_pos_amount_to_float(POSUtils.first_or_default(
                root.xpath("./ExtendedPrice[1]/text()"), 0)),
            external_id=POSUtils.first_or_default(root.xpath("./ExternalId[1]/text()"), ""),
            tender_itemizer_rank=int(POSUtils.first_or_default(root.xpath("./TenderItemizerRank[1]/text()"), 0)),
            age_minimum=int(POSUtils.first_or_default(root.xpath("./AgeMinimum[1]/text()"), 0)),
            status=statuses,
            mode=int(POSUtils.first_or_default(root.xpath("./ItemMode[1]/text()"), 0)),
            item_type=int(POSUtils.first_or_default(root.xpath("./ItemType[1]/text()"), 0)),
            item_id=int(POSUtils.first_or_default(root.xpath("./ItemId[1]/text()"), 0)),
            modifier_id_1=int(POSUtils.first_or_default(root.xpath("./Modifier1Id[1]/text()"), 0)),
            modifier_id_2=int(POSUtils.first_or_default(root.xpath("./Modifier2Id[1]/text()"), 0)),
            modifier_id_3=int(POSUtils.first_or_default(root.xpath("./Modifier3Id[1]/text()"), 0)),
            credit_code=None,
            nvps=list_of_item_nvps

        )

    def to_dict(self) -> dict:
        """
        Serialize item object to dictionary.

        :return: Serialize item.
        :rtype: dict
        """
        full_dict = {
            "Name": self.name,
            "Barcode": self.barcode,
            "Price": self.price,
            "ExternalId": self.external_id,
            "TenderItemizerRank": self.tender_itemizer_rank,
            "AgeMinimum": self.age_minimum,
            "Mode": self.mode,
            "ItemType": self.item_type,
            "ItemId": self.item_id,
            "ModifierId1": self.modifier_id_1,
            "ModifierId2": self.modifier_id_2,
            "ModifierId3": self.modifier_id_3,
            "CreditCode": self.credit_code,
            "NVPs": self.nvps
        }

        return {
            key: value for key, value in full_dict.items()
            if value is not None
            }
        
    def has_status(self, status: ItemStatuses):
        """
        Method to check whether the item has the status that is supplied as parameter.

        :param status: Item status to be searched for.
        :return: True if the status is found.
        """
        status_found = False
        for state in self.status:
            if status == state:
                status_found = True
                break
        return status_found

    def has_nvp(self, nvp: dict) -> bool:
        """
        Method to check whether the item has the nvp that is supplied as parameter.

        :param nvp: NVP to check together with all its attributes.
        :return: True if the NVP is found with proper values.
        """
        nvp_found = False
        for tran_nvp in self.nvps:
            for attr in nvp:
                if attr in tran_nvp and nvp[attr] == tran_nvp[attr]:
                    nvp_found = True
                else:
                    nvp_found = False
                    break
            else:
                return nvp_found
        return nvp_found