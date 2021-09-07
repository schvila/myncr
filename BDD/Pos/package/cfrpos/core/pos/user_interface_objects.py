class UserInterfaceObject:
    BINDING = 0
    BINDING_PARAMETER = 0

    @classmethod
    def compare(cls, binding: int, binding_param: int) -> bool:
        return cls.BINDING == binding and cls.BINDING_PARAMETER == binding_param


class UserInterfaceText(UserInterfaceObject):
    pass


class UserInterfaceList(UserInterfaceObject):
    pass


class ListVirtualReceipt(UserInterfaceList):
    BINDING = 1100
    BINDING_PARAMETER = 1


class TextVirtualReceipt(UserInterfaceText):
    BINDING = 4200


class TextVirtualReceiptOperator(TextVirtualReceipt):
    BINDING_PARAMETER = 1


class TextVirtualReceiptTranNumber(TextVirtualReceipt):
    BINDING_PARAMETER = 3


class TextVirtualReceiptInformation(TextVirtualReceipt):
    BINDING_PARAMETER = 4


class TextVirtualReceiptSubtotalLabel(TextVirtualReceipt):
    BINDING_PARAMETER = 5


class TextVirtualReceiptSubtotalAmount(TextVirtualReceipt):
    BINDING_PARAMETER = 6


class TextVirtualReceiptTaxLabel(TextVirtualReceipt):
    BINDING_PARAMETER = 7


class TextVirtualReceiptTaxAmount(TextVirtualReceipt):
    BINDING_PARAMETER = 8


class TextVirtualReceiptTotalLabel(TextVirtualReceipt):
    BINDING_PARAMETER = 9


class TextVirtualReceiptTotalAmount(TextVirtualReceipt):
    BINDING_PARAMETER = 10


class TextVirtualReceiptBalanceChangeLabel(TextVirtualReceipt):
    BINDING_PARAMETER = 11


class TextVirtualReceiptBalanceChangeAmount(TextVirtualReceipt):
    BINDING_PARAMETER = 12


class TextVirtualReceiptFsChangeLabel(TextVirtualReceipt):
    BINDING_PARAMETER = 13


class TextVirtualReceiptFsChangeAmount(TextVirtualReceipt):
    BINDING_PARAMETER = 14


class TextVirtualReceiptVATAmount(TextVirtualReceipt):
    BINDING_PARAMETER = 15
