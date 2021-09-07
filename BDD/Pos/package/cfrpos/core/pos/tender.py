__all__ = [
    "Tender",
    "TenderFlags",
    "TenderTypes"
]

import enum
import json
from typing import Optional

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace


@wrap_all_methods_with_log_trace
class TenderFlags:
    """
    This class represents the flag information for a single tender.
    """

    def __init__(self,
                 allow_paid_out=None,
                 allow_paid_in=None,
                 allow_pick_up=None,
                 allow_loan=None,
                 disqualified=None,
                 allow_exclusive=None,
                 allow_account_payment=None,
                 qualified=None,
                 not_to_exceed_balance_due=None,
                 allow_refund=None,
                 allow_cc_payment=None,
                 require_whole_amount_payment=None,
                 pick_up_envelope=None,
                 pick_up_bill_reader=None,
                 separate_on_shift_summary=None,
                 allow_drawer_count=None,
                 no_change_back=None,
                 additional_info_on_pos=None,
                 security_required_refund=None,
                 roundable=None,
                 tax_invoice_receipt=None,
                 electronic=None,
                 allow_change_safe_count=None,
                 show_confirm_frame=None):
        self.allow_paid_out = allow_paid_out
        self.allow_paid_in = allow_paid_in
        self.allow_pick_up = allow_pick_up
        self.allow_loan = allow_loan
        self.disqualified = disqualified
        self.allow_exclusive = allow_exclusive
        self.allow_account_payment = allow_account_payment
        self.qualified = qualified
        self.not_to_exceed_balance_due = not_to_exceed_balance_due
        self.allow_refund = allow_refund
        self.allow_cc_payment = allow_cc_payment
        self.require_whole_amount_payment = require_whole_amount_payment
        self.pick_up_envelope = pick_up_envelope
        self.pick_up_bill_reader = pick_up_bill_reader
        self.separate_on_shift_summary = separate_on_shift_summary
        self.allow_drawer_count = allow_drawer_count
        self.no_change_back = no_change_back
        self.additional_info_on_pos = additional_info_on_pos
        self.security_required_refund = security_required_refund
        self.roundable = roundable
        self.tax_invoice_receipt = tax_invoice_receipt
        self.electronic = electronic
        self.allow_change_safe_count = allow_change_safe_count
        self.show_confirm_frame = show_confirm_frame

    def __eq__(self, other: "TenderFlags") -> bool:
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

    def __ne__(self, other: "TenderFlags") -> bool:
        return not self.__eq__(other)

    @classmethod
    def from_dict(cls, source: dict) -> "TenderFlags":
        """
        Initializes TenderFlag's object with values obtained from the dictionary

        :param source: Dictionary which represents TenderFlags
        :return: Initialized instance of TenderFlags
        :rtype: TenderFlags
        """
        return cls(
            allow_paid_out=source.get("AllowPaidOut"),
            allow_paid_in=source.get("AllowPaidIn"),
            allow_pick_up=source.get("AllowPickUp"),
            allow_loan=source.get("AllowLoan"),
            disqualified=source.get("Disqualified"),
            allow_exclusive=source.get("AllowExclusive"),
            allow_account_payment=source.get("AllowAccountPayment"),
            qualified=source.get("Qualified"),
            not_to_exceed_balance_due=source.get("NotToExceedBalanceDue"),
            allow_refund=source.get("AllowRefund"),
            allow_cc_payment=source.get("AllowCCPayment"),
            require_whole_amount_payment=source.get("RequireWholeAmountPayment"),
            pick_up_envelope=source.get("PickUpEnvelope"),
            pick_up_bill_reader=source.get("PickUpBillReader"),
            separate_on_shift_summary=source.get("SeparateOnShiftSummary"),
            allow_drawer_count=source.get("AllowDrawerCount"),
            no_change_back=source.get("NoChangeBack"),
            additional_info_on_pos=source.get("AdditionalInfoOnPOS"),
            security_required_refund=source.get("SecurityRequiredRefund"),
            roundable=source.get("Roundable"),
            tax_invoice_receipt=source.get("TaxInvoiceReceipt"),
            electronic=source.get("Electronic"),
            allow_change_safe_count=source.get("AllowChangeSafeCount"),
            show_confirm_frame=source.get("ShowConfirmFrame")
        )

    @classmethod
    def from_json(cls, source: dict) -> "TenderFlags":
        """
        Initializes TenderFlag's object with values obtained from the JSON

        :param source: JSON which represents TenderFlags
        :return: Initialized instance of TenderFlags
        :rtype: TenderFlags
        """
        return cls.from_dict(json.loads(source))

    def to_dict(self) -> dict:
        """
        Serialize TenderFlags object to dictionary.

        :return: Serialized instance of TenderFlags object
        :rtype: dict
        """
        full_dict = {
            "AllowPaidOut": self.allow_paid_out,
            "AllowPaidIn": self.allow_paid_in,
            "AllowPickUp": self.allow_pick_up,
            "AllowLoan": self.allow_loan,
            "Disqualified": self.disqualified,
            "AllowExclusive": self.allow_exclusive,
            "AllowAccountPayment": self.allow_account_payment,
            "Qualified": self.qualified,
            "NotToExceedBalanceDue": self.not_to_exceed_balance_due,
            "AllowRefund": self.allow_refund,
            "AllowCCPayment": self.allow_cc_payment,
            "RequireWholeAmountPayment": self.require_whole_amount_payment,
            "PickUpEnvelope": self.pick_up_envelope,
            "PickUpBillReader": self.pick_up_bill_reader,
            "SeparateOnShiftSummary": self.separate_on_shift_summary,
            "AllowDrawerCount": self.allow_drawer_count,
            "NoChangeBack": self.no_change_back,
            "AdditionalInfoOnPOS": self.additional_info_on_pos,
            "SecurityRequiredRefund": self.security_required_refund,
            "Roundable": self.roundable,
            "TaxInvoiceReceipt": self.tax_invoice_receipt,
            "Electronic": self.electronic,
            "AllowChangeSafeCount": self.allow_change_safe_count,
            "ShowConfirmFrame": self.show_confirm_frame
        }

        return {
            key: value for key, value in full_dict.items()
            if value is not None
        }

    def to_json(self) -> str:
        """
        Serialize TenderFlags object to JSON string.

        :return: Serialized instance of TenderFlags object
        :rtype: str
        """
        return json.dumps(self.to_dict())


class TenderTypes(enum.Enum):
    """
    Tender type constants from RPOS PosConstants.h.
    """

    CASH = 1
    CHECK = 2
    CREDIT = 3
    DEBIT = 4
    GIFT_CERTIFICATE = 5
    PUMP_TEST = 6
    DRIVE_OFF = 7
    FOOD_STAMP = 8
    MANUAL_IMPRINT = 9
    LOCAL_AUTH = 10
    MONEY_ORDER = 11
    SERVICE_BILL = 12
    OVER_SHORT = 13
    INSTALLMENT = 14
    TRAVELLERS_CHECK = 15
    LOYALTY_POINT = 16
    LOCAL_ACCOUNTS = 17
    CHARGE_POST_INTERFACE = 18
    STORE_USE = 19
    BAD_MECHANDISE = 20
    MANUFACTURER_COUPON = 21
    PAY_AT_PUMP_CASH = 22
    EBT_FOOD_STAMP = 23
    EBT_CASH_BENEFIT = 24
    OTHER = 31
    FSA = 33


@wrap_all_methods_with_log_trace
class Tender:
    """
    This class represents the information for a single tender.
    """

    def __init__(self,
                 tender_id: int,
                 type_id: TenderTypes,
                 description: str,
                 external_id: Optional[str],
                 security: int,
                 flags: TenderFlags):
        self.tender_id = tender_id
        self.type_id = type_id
        self.description = description
        self.external_id = external_id
        self.security = security
        self.flags = flags

    @classmethod
    def from_dict(cls, source: dict) -> "Tender":
        """
        Deserialize Tender from the dictionary.

        :param source: Dict representation of the Tender
        :return: Deserialized tender
        :rtype: Tender
        """
        return cls(
            tender_id=source["TenderId"],
            type_id=TenderTypes(source["TypeId"]),
            description=source["Description"],
            external_id=source["ExternalId"],
            security=source["Security"],
            flags=TenderFlags.from_dict(source["Flags"])
        )

    def to_dict(self) -> dict:
        """
        Serializes tender into the dictionary.

        :return: Tender serialized into the dictionary
        :rtype: dict
        """
        return {
            "TenderId": self.tender_id,
            "TypeId": self.type_id.value,
            "Description": self.description,
            "ExternalId": self.external_id,
            "Security": self.security,
            "Flags": self.flags.to_dict()
        }
