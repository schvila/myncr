__all__ = ["ITouchable", "UiObject", "UiValue", "UiText", "UiPrompt",
           "UiButton", "UiPumpDisplay", "UiButtonGrid", "UiFrame",
           "MenuFrame", "ReceiptFrame", "FuelPumpsFrame",
           "UiPumpState", "UiListItem"]

import re
from enum import Enum
from typing import List, Optional

from .. bdd_utils.errors import ProductError
from .. bdd_utils.logging_utils import get_ev_logger, wrap_all_methods_with_log_trace
from . import user_interface_objects as ui
from . ui_metadata import POSFrame, POSButton

logger = get_ev_logger()


@wrap_all_methods_with_log_trace
class ITouchable:
    """
    Describes UI object that can be touched
    """

    def get_target_id(self) -> int:
        """
        Get ID of the target.

        :return: Target id.
        :rtype: int
        """
        raise NotImplementedError()

    def get_name(self) -> str:
        """
        Get name of the touchable object

        :return: Name of the touchable object
        :rtype: str
        """
        raise NotImplementedError()


@wrap_all_methods_with_log_trace
class UiObject:
    """
    Common base class for all UI objects
    """

    def __init__(self, obj_id=0, instance_id=0, use_description="", use_details={}, name=None, ap=0, bp=0):
        self._object_id = obj_id
        self._instance_id = instance_id
        self._use_description = use_description
        self._use_details = use_details
        self._name = name
        self._application_binding = ap
        self._binding_parameter = bp

    @property
    def object_id(self) -> int:
        """
        Get ID of the UI object.
        :return: Object ID.
        :rtype: int
        """
        return self._object_id

    @property
    def instance_id(self) -> int:
        """
        Get instance ID of the UI object.

        :return: Instance ID.
        :rtype: int
        """
        return self._instance_id

    @property
    def use_description(self) -> str:
        """
        Get the usage description of the UI Object.

        :return: Use description.
        :rtype: str
        """
        return self._use_description

    @property
    def use_details(self) -> dict:
        """
        Get the usage details of the UI Object.

        :return: Use details.
        :rtype: dict
        """
        return self._use_details

    @property
    def name(self) -> str:
        """
        Get name of the UI object.

        :return: Name.
        :rtype: str
        """
        return self._name

    @property
    def application_binding(self) -> int:
        """
        Get application binding of the UI object.

        :return: Application binding.
        :rtype: int
        """
        return self._application_binding

    @property
    def binding_parameter(self) -> int:
        """
        Get binding parameter of the UI object.

        :return: Binding parameter.
        :rtype: int
        """
        return self._binding_parameter

    @staticmethod
    def extract_attribute(dictionary: dict, name: str) -> str:
        """
        Extract attribute from the given dictionary

        :param dict dictionary: Dictionary from which should be extracted attribute
        :param str name: The name of the requested attribute
        :return: Required attribute or empty string if not exists.
        :rtype: str
        """
        return dictionary.get(name, "")

    @staticmethod
    def extract_int_attribute(dictionary: dict, name: str, required: bool=False) -> int:
        """
        Extract attribute from the given dictionary and return it as int

        :param dict dictionary: Dictionary from which should be extracted attribute
        :param str name: The name of the requested attribute
        :param bool required: True if the attribute is required
        :return: Required attribute or empty string if not exists.
        :rtype: int
        """
        try:
            return int(dictionary.get(name, 0))
        except ValueError:
            if required:
                logger.error("extract_int_attribute failed for: '{}'".format(name))
            return 0

    def parse(self, element_dictionary: dict) -> None:
        """
        Parse UiObject from the dictionary

        :param dict element_dictionary: Dictionary which should be used to fill UiObject's internal members
        """
        if element_dictionary is not None:
            self._object_id = UiObject.extract_int_attribute(element_dictionary, "Id")
            self._name = UiObject.extract_attribute(element_dictionary, "Name")
            self._application_binding = UiObject.extract_int_attribute(element_dictionary, "ApplicationBinding")
            self._binding_parameter = UiObject.extract_int_attribute(element_dictionary, "BindingParameter")
            self._instance_id = UiObject.extract_int_attribute(element_dictionary, "InstanceId")
            self._use_description = UiObject.extract_attribute(element_dictionary, "UseDescription")
            self._use_details = UiObject.extract_attribute(element_dictionary, "UseDetails")

    def __str__(self) -> str:
        return "InstanceId: '{}'".format(self.instance_id)


@wrap_all_methods_with_log_trace
class UiValue(UiObject):
    """
    Base class for value based UI objects
    """

    def __init__(self, instance_id=0, obj_id=0, name=None, ab=0, bp=0, value=None):
        super().__init__(instance_id, obj_id, name, ab, bp)
        self._value = value

    @property
    def value(self) -> str:
        """
        Get the value UiValue.

        :return: value.
        :rtype: str
        """
        return self._value

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiValue

        :param dict element_dictionary: Dictionary which should be used to fill UiValue's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._value = UiObject.extract_attribute(element_dictionary, "Value")

    def __str__(self) -> str:
        return super().__str__() + ", Value: '{}'".format(self.value)


class UiText(UiValue):
    """
    Represents single Text on the POS UI
    """

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiText

        :param dict element_dictionary: Dictionary which should be used to fill UiText's internal members
        """
        UiValue.parse(self, element_dictionary)

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiText"]:
        """ Parse multiple UiTexts and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiText objects.
        :return: List of the UiText objects parsed from the input list.
        :rtype: List["UiText"]
        """
        texts = None

        if element_list is not None:
            texts = []
            for element in element_list:
                text = UiText()
                text.parse(element)
                texts.append(text)
        return texts


@wrap_all_methods_with_log_trace
class UiPrompt(UiValue):
    """
    Represents single Prompt on the POS UI
    """

    def parse(self, parent: dict) -> None:
        """ Parse UiText

        :param dict parent: Dictionary which should be used to fill UiText's internal members
        """
        super().parse(parent)

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiPrompt"]:
        """ Parse multiple UiPrompt objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiPrompt objects.
        :return: List of the UiPrompt objects parsed from the input list.
        :rtype: List["UiPrompt"]
        """
        prompts = None

        if element_list is not None:
            prompts = []
            for element in element_list:
                prompt = UiPrompt()
                prompt.parse(element)
                prompts.append(prompt)
        return prompts


@wrap_all_methods_with_log_trace
class UiButton(UiObject, ITouchable):
    """
    Represents single Button on the POS UI
    """

    def __init__(self, instance_id=0, obj_id=0, name=None, ab=0, bp=0, text=None, graphics=None):
        super().__init__(instance_id, obj_id, name, ab, bp)
        self._text = text
        self._graphics = graphics

    @property
    def text(self) -> str:
        """
        Get the text value of the UiButton.

        :return: text value.
        :rtype: str
        """
        return self._text

    @property
    def graphics(self) -> str:
        """
        Get the graphics of the UiButton.

        :return: graphics.
        :rtype: str
        """
        return self._graphics

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiButton

        :param dict element_dictionary: Dictionary which should be used to fill UiButton's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._text = self.extract_attribute(element_dictionary, "Text")
            self._graphics = self.extract_attribute(element_dictionary, "Graphics")

    def get_target_id(self) -> int:
        """
        Get the target id of the UiButton

        :return: Target ID
        :rtype: int
        """
        return self.instance_id

    def get_name(self) -> str:
        """
        Get the name of the UiButton

        :return: name of the button
        :rtype: str
        """
        if self.name:
            return self.name
        elif self.graphics:
            return self.graphics
        else:
            return self.text

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiButton"]:
        """ Parse multiple UiButton objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiButton objects.
        :return: List of the UiButton objects parsed from the input list.
        :rtype: List["UiButton"]
        """
        buttons = None

        if element_list is not None:
            buttons = []
            for element in element_list:
                button = UiButton()
                button.parse(element)
                buttons.append(button)
        return buttons

    def __str__(self) -> str:
        return super().__str__() + ", Graphics: '{}', Text: '{}'".format(self.graphics, self.text)


@wrap_all_methods_with_log_trace
class UiPumpState(Enum):
    """
    Valid UI Pump states
    """
    NONE = 'None'
    INACTIVE = 'Inactive'
    IDLE = 'Idle'
    HANDLE_LIFTED = 'HandleLifted'
    AUTHORIZED = 'Authorized'
    FUELING = 'Fueling'
    FUEL_DONE = 'FuelDone'
    PUMP_STOPPED = 'PumpStopped'
    AMOUNT_DUE = 'AmountDue'
    STACKED_SALES = 'StackedSales'
    DRIVE_OFF = 'DriveOff'
    AUTH_PREPAY = 'AuthPrepay'
    AUTH_ICR = 'AuthIcr'
    FUELING_PREPAY = 'FuelingPrepay'
    FUELING_ICR = 'FuelingIcr'
    CLOSED = 'Closed'
    LOYALTY_IDLE = 'LoyaltyIdle'
    LOYALTY_FUELING = 'LoyaltyFueling'
    LOYALTY_DECLINED = 'LoyaltyDeclined'
    MANUAL = 'Manual'
    INTEGRATED_MANUAL = 'IntegratedManual'
    SMART_PREPAY_INCOMPLETE = 'SmartPrepayIncomplete'


@wrap_all_methods_with_log_trace
class UiPumpDisplay(UiObject, ITouchable):
    """
    Represents single Pump on the POS UI
    """
    def __init__(self, instance_id=0, obj_id=0, name=None, ab=0, bp=0, pump_number=0,
                 selected=False, top_text="", bottom_text="", last_state=0, completed_fuel_sales=[], current_fuel_sale_price=0.0):
        super().__init__(instance_id, obj_id, name, ab, bp)
        self._pump_number = pump_number
        self._selected = selected
        self._last_state = last_state
        self._completed_fuel_sales = completed_fuel_sales
        self._current_fuel_sale_price = current_fuel_sale_price

    @property
    def pump_number(self) -> int:
        """
        Return number of the pump.

        :return: Pump number
        :rtype: int
        """
        return self._pump_number

    @property
    def selected(self) -> bool:
        """
        Get value of the selected flag.

        :return: True if the pump is selected
        :rtype: bool
        """
        return self._selected

    @property
    def last_state(self) -> str:
        """
        Get the last state of the pump

        :return: The last state of the pump
        :rtype: str
        """
        return self._last_state

    @property
    def completed_fuel_sales(self) -> dict:
        """
        Get the dictionary of the completed fuel sales.

        :return: Dictionary of completed sales.
        :rtype: dict
        """
        return self._completed_fuel_sales

    @property
    def current_fuel_sale_price(self) -> float:
        """
        Get the current fuel sale price.

        :return: Current sale displayed on the pump.
        :rtype: float
        """
        return self._current_fuel_sale_price

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiPumpDisplay

        :param dict element_dictionary: Dictionary which should be used to fill UiPumpDisplay's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._pump_number = int(self._name.split('-')[-1])
            self._selected = True if self.extract_int_attribute(element_dictionary, "Selected") == 1 else False
            self._last_state = self.extract_attribute(element_dictionary, "State")
            self._completed_fuel_sales = self.extract_attribute(element_dictionary, "CompletedSaleFuelPrices")
            self._current_fuel_sale_price = float(self.extract_attribute(element_dictionary, "CurrentSaleFuelPrice"))

    def get_target_id(self) -> int:
        """
        Get the target id of the UiPumpDisplay

        :return: The target ID of the UiPumpDisplay
        :rtype: int
        """
        return self._instance_id

    def get_name(self) -> str:
        """
        Get the name of the UiPumpDisplay

        :return: The name of the UiPumpDisplay
        :rtype: str
        """
        return "Pump %d" % self._pump_number

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiPumpDisplay"]:
        """ Parse multiple UiPumpDisplay objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiPumpDisplay objects.
        :return: List of the UiPumpDisplay objects parsed from the input list.
        :rtype: List["UiPumpDisplay"]
        """
        pumps = None

        if element_list is not None:
            pumps = []
            for element in element_list:
                button = UiPumpDisplay()
                button.parse(element)
                pumps.append(button)
        return pumps

    def __str__(self) -> str:
        return super().__str__() + ", PumpNumber: '{}', Selected: '{}', State: '{}'".format(
            self._pump_number, self._selected, self._last_state)


@wrap_all_methods_with_log_trace
class UiButtonGrid(UiObject):
    """
    Represents single Button grid on the POS UI
    """

    def __init__(self, obj_id=0, instance_id=0, name=None, ap=0, bp=0):
        super().__init__(obj_id, instance_id, name, ap, bp)
        self._buttons = []

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiButtonGrid

        :param dict element_dictionary: Dictionary which should be used to fill UiButtonGrid's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._buttons = UiButton.parse_multiple(element_dictionary.get("Buttons", []))

    @property
    def buttons(self) -> List[UiButton]:
        """
        Get all buttons on the button grid.

        :return: The list of all buttons on the button grid.
        :rtype: List[UiButton]
        """
        return self._buttons

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiButtonGrid"]:
        """ Parse multiple UiButtonGrid objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiButtonGrid objects.
        :return: List of the UiButtonGrid objects parsed from the input list.
        :rtype: List["UiButtonGrid"]
        """
        button_grids = None

        if element_list is not None:
            button_grids = []
            for element in element_list:
                button_grid = UiButtonGrid()
                button_grid.parse(element)
                button_grids.append(button_grid)
        return button_grids

    def __str__(self) -> str:
        return super().__str__() + ", ButtonCount: '{}'".format(len(self.buttons) if self.buttons is not None else 0)


@wrap_all_methods_with_log_trace
class UiListItem(UiObject):
    """
    Represents single List item on the POS UI
    """

    def __init__(self, number: int=0, text: str="", selected: bool=False):
        super().__init__()
        self._text = text
        self._number = number
        self._selected = selected
        self._data = {}

    @property
    def text(self) -> str:
        """
        Get the text of the list item.
        """
        return self._text

    @property
    def number(self) -> int:
        """
        Get the item ID of the list item.
        """
        return self._number

    @property
    def selected(self) -> bool:
        """
        Tell if the line item is selected
        """
        return self._selected

    @property
    def data(self) -> dict:
        """
        Get dictionary containing additional data - what is not exposed as property.
        """
        return self._data

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiListItem

        :param dict element_dictionary: Dictionary which should be used to fill UiListItem's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._data = element_dictionary.copy()
            if "Text" in self._data:
                self._text = self._data.pop("Text")
            if "Number" in self._data:
                self._number = self._data.pop("Number")
            if "Selected" in self._data:
                self._selected = self._data.pop("Selected")

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiListItem"]:
        """ Parse multiple UiListItem objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiListItem objects.
        :return: List of the UiListItem objects parsed from the input list.
        :rtype: List["UiListItem"]
        """
        list_items = None

        if element_list is not None:
            list_items = []
            for element in element_list:
                list_item = UiListItem()
                list_item.parse(element)
                list_items.append(list_item)
        return list_items

    def __str__(self) -> str:
        return super().__str__() + ", Text: '{}', Number: '{}'".format(self.text, self.number)


@wrap_all_methods_with_log_trace
class UiVirtualReceiptItem(UiObject):
    """
    Represents single virtual receipt item on the POS UI
    """

    def __init__(self, number: int=0, text: str="", formatted_description: str="", formatted_quantity: str="",
                 formatted_price: str="", formatted_calories: str="", selected: bool=False):
        super().__init__()
        self._text = text
        self._formatted_description = formatted_description
        self._formatted_quantity = formatted_quantity
        self._formatted_price = formatted_price
        self._formatted_calories = formatted_calories
        self._number = number
        self._selected = selected

    @property
    def text(self) -> str:
        """
        Get the text of the list item.
        """
        return self._text

    @property
    def number(self) -> int:
        """
        Get the item ID of the list item.
        """
        return self._number

    @property
    def selected(self) -> bool:
        """
        Tell if the line item is selected
        """
        return self._selected

    @property
    def formatted_calories(self) -> str:
        """
        Get the formatted calories amount of the line
        """
        return self._formatted_calories

    @property
    def formatted_description(self) -> str:
        """
        Get the formatted description of the item
        """
        return self._formatted_description

    @property
    def formatted_quantity(self) -> str:
        """
        Get the formatted quantity of the item
        """
        return self._formatted_quantity

    @property
    def formatted_price(self) -> str:
        """
        Get the formatted price of the item
        """
        return self._formatted_price

    @property
    def description(self) -> str:
        return self._formatted_description.strip()

    @property
    def price(self) -> str:
        price = self._formatted_price
        count = 0
        for char in price:
            if ord(char) >= ord("0") and ord(char) <= ord("9"):
                break
            count = count + 1
        if price[-1] == ')':
            price = price[count:-1]
            price = "-" + price
        else:
            price = price[count:]
        return price

    @property
    def quantity(self) -> str:
        quantity = self._formatted_quantity
        count = 0
        for char in quantity:
            if ord(char) >= ord("0") and ord(char) <= ord("9"):
                break
            count = count + 1
        quantity = quantity[count:]
        if quantity == "":
            quantity = "1"
        return quantity

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiVirtualReceiptItem

        :param dict element_dictionary: Dictionary which should be used to fill UiVirtualReceiptItem's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._text = self.extract_attribute(element_dictionary, "Text")
            self._number = self.extract_int_attribute(element_dictionary, "Number")
            self._formatted_description = self.extract_attribute(element_dictionary, "FormattedDescription")
            self._formatted_quantity = self.extract_attribute(element_dictionary, "FormattedQuantity")
            self._formatted_calories = self.extract_attribute(element_dictionary, "FormattedCalories")
            self._formatted_price = self.extract_attribute(element_dictionary, "FormattedPrice")
            self._selected = self.extract_attribute(element_dictionary, "Selected")

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiVirtualReceiptItem"]:
        """ Parse multiple UiVirtualReceiptItem objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiVirtualReceiptItems.
        :return: List of the UiVirtualReceiptItem objects parsed from the input list.
        :rtype: List["UiVirtualReceiptItem"]
        """
        list_items = None

        if element_list is not None:
            list_items = []
            for element in element_list:
                list_item = UiVirtualReceiptItem()
                list_item.parse(element)
                list_items.append(list_item)
        return list_items

    def __str__(self) -> str:
        return super().__str__() + ", Text: '{}', Number: '{}'".format(self.text, self.number)

@wrap_all_methods_with_log_trace
class UiRecallTransactionItem(UiListItem):
    """
    Wrapper of UiListItem to represent items in recall transaction list.
    """
    def __init__(self, number: int=0, text: str="", selected: bool=False, transaction_sequence_number: int=-1):
        super().__init__(number, text, selected)
        self._transaction_sequence_number = transaction_sequence_number

    @classmethod
    def from_list_item(cls, list_item: UiListItem):
        return cls(list_item.number, list_item.text, list_item.selected, list_item.data.get("TransactionNumber", -1))

    @property
    def transaction_sequence_number(self) -> int:
        return self._transaction_sequence_number

@wrap_all_methods_with_log_trace
class UiScrollPreviousItem(UiListItem):
    """
    Wrapper of UiListItem to represent items in scroll previous list.
    """
    def __init__(self, number: int=0, text: str="", selected: bool=False, transaction_sequence_number: int=-1,
        prepay_sequence_number: int=0, node_number: int=-1, node_type: str="", transaction_type: str="",
        transaction_time: str="", transaction_total: str="", order_reference: str=""):
        super().__init__(number, text, selected)
        self._transaction_sequence_number = transaction_sequence_number
        self._prepay_sequence_number = prepay_sequence_number
        self._transaction_total = transaction_total
        self._transaction_type = transaction_type
        self._transaction_time = transaction_time
        self._order_reference = order_reference
        self._node_number = node_number
        self._node_type = node_type

    @classmethod
    def from_list_item(cls, list_item: UiListItem):
        return cls(list_item.number, list_item.text, list_item.selected, list_item.data.get("TransactionNumber", -1),
            list_item.data.get("PrepaySequenceNumber", 0), list_item.data.get("NodeNumber", -1), list_item.data.get("NodeType", ""),
            list_item.data.get("TransactionType", ""), list_item.data.get("TransactionTime", ""), list_item.data.get("TransactionTotal", ""),
            list_item.data.get("OrderReference", ""))

    @property
    def transaction_sequence_number(self) -> int:
        return self._transaction_sequence_number

    @property
    def prepay_sequence_number(self) -> int:
        return self._prepay_sequence_number
    
    @property
    def transaction_total(self) -> str:
        return self._transaction_total

    @property
    def transaction_total_amount(self) -> float:
        amount_list = [float(s) for s in re.findall('[\d]*[.][\d]+', self._transaction_total)]
        if len(amount_list) is 1:
            tran_total_amout = amount_list[0]
            if len(self._transaction_total) > 1 and self._transaction_total[0] is '-':
                tran_total_amout *= -1
        else:
            raise ProductError("Failed to parse transaction total amount from {}". format(self._transaction_total))
        return tran_total_amout
    
    @property
    def transaction_type(self) -> str:
        return self._transaction_type

    @property
    def transaction_time(self) -> str:
        return self._transaction_time

    @property
    def order_reference(self) -> str:
        return self._order_reference

    @property
    def node_number(self) -> int:
        return self._node_number

    @property
    def node_type(self) -> str:
        return self._node_type

@wrap_all_methods_with_log_trace
class UiListWindow(UiObject):
    """
    Represents single List Window on the POS UI
    """

    def __init__(self, obj_id=0, instance_id=0, name=None, ap=0, bp=0):
        super().__init__(obj_id, instance_id, name, ap, bp)
        self._list_items = []

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiListWindow

        :param dict element_dictionary: Dictionary which should be used to fill UiListWindow's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._list_items = UiListItem.parse_multiple(element_dictionary.get("ListItems", []))

    @property
    def list_items(self) -> List[UiListItem]:
        """
        Get list items in the list window.

        :return: The list of all list items in the list window.
        :rtype: List[UiListItem]
        """
        return self._list_items

    def find_item_by_id(self, item_id: int) -> Optional[UiListItem]:
        """
        Get value of the auto_commit member.

        :param int item_id: ID of the ListItem which should be found in the list window
        :return: Found list item if any. Otherwise None.
        :rtype: UiListItem or None
        """
        return next((x for x in self.list_items if x.item_id == item_id), None)

    def find_item_by_text(self, text: str) -> Optional[UiListItem]:
        """
        Get value of the auto_commit member.

        :param str text: text of the ListItem which should be found in the list window
        :return: Found list item if any. Otherwise None.
        :rtype: UiListItem or None
        """
        return next((x for x in self.list_items if x.text == text), None)

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiListWindow"]:
        """ Parse multiple UiListWindow objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiListWindow objects.
        :return: List of the UiListItem objects parsed from the input list.
        :rtype: List["UiListWindow"]
        """
        list_windows = None

        if element_list is not None:
            list_windows = []
            for element in element_list:
                list_window = UiListWindow()
                list_window.parse(element)
                list_windows.append(list_window)
        return list_windows

    def __str__(self) -> str:
        return super().__str__() + ", ListItemCount: '{}'".format(
            len(self.list_items) if self.list_items is not None else 0)

@wrap_all_methods_with_log_trace
class UiReceiptListWindow(UiObject):
    """
    Represents single List Window of the receipt on the POS UI
    """

    def __init__(self):
        super().__init__()
        self._receipt_items = []

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiReceiptListWindow

        :param dict element_dictionary: Dictionary which should be used to fill UiReceiptListWindow's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._receipt_items = UiVirtualReceiptItem.parse_multiple(element_dictionary.get("ListItems", []))

    @property
    def receipt_items(self) -> List[UiVirtualReceiptItem]:
        """
        Get virtual receipt items in the list window.

        :return: The list of all list items in the list window.
        :rtype: List[UiVirtualReceiptItem]
        """
        return self._receipt_items

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiReceiptListWindow"]:
        """ Parse multiple UiReceiptListWindow objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiReceiptListWindows.
        :return: List of the UiReceiptListWindow objects parsed from the input list.
        :rtype: List["UiReceiptListWindow"]
        """
        list_windows = None

        if element_list is not None:
            list_windows = []
            for element in element_list:
                list_window = UiReceiptListWindow()
                list_window.parse(element)
                list_windows.append(list_window)
        return list_windows

    def __str__(self) -> str:
        return super().__str__() + ", ListItemCount: '{}'".format(
            len(self.list_items) if self.list_items is not None else 0)



@wrap_all_methods_with_log_trace
class UiFrame(UiObject):
    """
    Represents single Frame on the POS UI
    """

    def __init__(self, instance_id=0, obj_id=0, name=None, ab=0, bp=0):
        super().__init__(obj_id, instance_id, name, ab, bp)
        self._buttons = []
        self._prompts = []
        self._texts = []
        self._button_grids = []
        self._frames = []
        self._list_windows = []

    @property
    def buttons(self) -> List[UiButton]:
        """
        Get list of all buttons on the frame.

        :return: All buttons on the frame.
        :rtype: List[UiButton]
        """
        return self._buttons

    @property
    def prompts(self) -> List[UiPrompt]:
        """
        Get all prompts on the frame.

        :return: All prompts on the frame.
        :rtype: List[UiPrompt]
        """
        return self._prompts

    @property
    def texts(self) -> List[UiText]:
        """
        Get all texts on the frame.

        :return: All texts on the frame.
        :rtype: List[UiText]
        """
        return self._texts

    @property
    def button_grids(self) -> List[UiButtonGrid]:
        """
        Get all button grids on the frame.

        :return: All button grids on the frame.
        :rtype: List[UiButtonGrid]
        """
        return self._button_grids

    @property
    def frames(self) -> List["UiFrame"]:
        """
        Get all sub-frames.

        :return: All sub-frames.
        :rtype: List["UiFrame"]
        """
        return self._frames

    @property
    def list_windows(self) -> List["UiListWindow"]:
        """
        Get all list windows on the frame.

        :return: All list windows
        :rtype: List["UiListWindow"]
        """
        return self._list_windows

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiFrame

        :param dict element_dictionary: Dictionary which should be used to fill UiFrame's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._buttons = UiButton.parse_multiple(element_dictionary.get("Buttons", []))
            self._prompts = UiPrompt.parse_multiple(element_dictionary.get("Prompts", []))
            self._texts = UiText.parse_multiple(element_dictionary.get("Texts", []))
            self._button_grids = UiButtonGrid.parse_multiple(element_dictionary.get("ButtonGrids", []))
            self._list_windows = UiListWindow.parse_multiple(element_dictionary.get("ListWindows", []))
            self._frames = UiFrame.parse_multiple(element_dictionary.get("ChildFrames", []))

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiFrame"]:
        """ Parse multiple UiFrame objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiFrame objects.
        :return: List of the UiListItem objects parsed from the input list.
        :rtype: List["UiFrame"]
        """
        frames = None

        if element_list is not None:
            frames = []
            for element in element_list:
                frame = UiFrame()
                frame.parse(element)
                frames.append(frame)
        return frames

    def add_button(self, button: UiButton) -> None:
        """
        Add button among buttons on the frame.

        :param UiButton button: The button which should be into the list of known buttons.
        """
        self.buttons.append(button)

    def _find_button_by_text(self, value: str) -> Optional[UiButton]:
        """
        Find button on the frame by text.

        :param str value: Text of the button which should be found on the current frame.
        :return: Found button if any. Otherwise None.
        :rtype: None or UiButton
        """
        if self.buttons is not None:
            for button in self.buttons:
                if button.text.lower() == value.lower():
                    return button

        if self.button_grids is not None:
            for button_grid in self.button_grids:
                for button in button_grid.buttons:
                    if button.text.lower() == value.lower():
                        return button

    def _find_button_by_name(self, value: str) -> Optional[UiButton]:
        """
        Find button on the frame by its name.

        :param str value: The name of the button which should be found on the current frame.
        :return: Found button if any. Otherwise None.
        :rtype: None or UiButton
        """
        if self.buttons is not None:
            for button in self.buttons:
                if button.get_name().lower() == value.lower():
                    return button

        if self.button_grids is not None:
            for button_grid in self.button_grids:
                for button in button_grid.buttons:
                    if button.get_name().lower() == value.lower():
                        return button

    def _find_button_by_graphics(self, value: str) -> Optional[UiButton]:
        """
        Find button on the frame by its graphics.

        :param str value: The graphics of the button which should be found on the current frame.
        :return: Found button if any. Otherwise None.
        :rtype: None or UiButton
        """
        if self.buttons is not None:
            for button in self.buttons:
                if button.graphics.lower() == value.lower():
                    return button

        if self.button_grids is not None:
            for button_grid in self.button_grids:
                for button in button_grid.buttons:
                    if button.graphics.lower() == value.lower():
                        return button

    def find_button(self, value: str) -> Optional[UiButton]:
        """
        Find button by name or text or graphics.
        :param value: Button name or text or image filename. Use name if possible.
        :return: UiButton if found or None.
        """
        value = str(value)
        button = self._find_button_by_name(value)
        if button is None:
            button = self._find_button_by_text(value)
            if button is None:
                button = self._find_button_by_graphics(value)

        return button

    def find_frame_by_text(self, value: str) -> Optional["UiFrame"]:
        """
        Find the sub-frame by its text.

        :param str value: The text of the sub-frame which should be found.
        :return: Found sub-frame if any. Otherwise None.
        :rtype: None or UiFrame
        """
        if self.frames is not None:
            for frame in self.frames:
                if frame.name.lower() == value.lower():
                    return frame

        return None

    def validate_displayed_texts(self, texts: List[str]) -> None:
        """
        Confirm that the displayed texts are the expected ones.

        :param texts: List of strings. Ordered texts.
        :return: Nothing
        :raises ProductError: If different texts then expected are displayed.
        """
        for index, text in enumerate(texts):
            if self.texts[index].value != text:
                error_msg = "Frame '{0}' (ab '{1}' binding param {2} contains different texts than expected.".format(
                    self.name, self.application_binding, self.binding_parameter)
                error_msg += "\nExpected '{}' but the frame contains '{}'".format(text, self.texts[index].value)
                raise ProductError(error_msg)

    def __str__(self) -> str:
        return super().__str__() + ", Name: '{}', UseDescription: '{}'".format(self.name, self.use_description)


@wrap_all_methods_with_log_trace
class ReceiptFrame(UiFrame):

    def __init__(self):
        super().__init__()
        self._virtual_receipt = None
        self._list_windows = []

    def parse(self, element_dictionary: dict) -> None:
        """ Parse UiFrame

        :param dict element_dictionary: Dictionary which should be used to fill UiFrame's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._buttons = UiButton.parse_multiple(element_dictionary.get("Buttons", []))
            self._prompts = UiPrompt.parse_multiple(element_dictionary.get("Prompts", []))
            self._texts = UiText.parse_multiple(element_dictionary.get("Texts", []))
            self._button_grids = UiButtonGrid.parse_multiple(element_dictionary.get("ButtonGrids", []))
            self._virtual_receipt = UiReceiptListWindow.parse_multiple(element_dictionary.get("ListWindows", []))
            self._frames = UiFrame.parse_multiple(element_dictionary.get("ChildFrames", []))

    @staticmethod
    def parse_multiple(element_list: list) -> List["UiFrame"]:
        """ Parse multiple UiFrame objects and return them as a list

        :param list element_list: List containing several elements. These should be translated to UiFrame objects.
        :return: List of the UiListItem objects parsed from the input list.
        :rtype: List["UiFrame"]
        """
        frames = None

        if element_list is not None:
            frames = []
            for element in element_list:
                frame = UiFrame()
                frame.parse(element)
                frames.append(frame)
        return frames

    @property
    def virtual_receipt(self) -> UiReceiptListWindow:
        """
        Get all the first list window on the receipt frame
        """
        return self._virtual_receipt[0]


@wrap_all_methods_with_log_trace
class MenuFrame(UiFrame):
    
    def has_button(self, pos_button: POSButton):
        """Checks if a given button is present on a frame"""
        button_found = False
        for button in self.buttons:
            if button.name == pos_button.value:
                button_found = True
                logger.debug("Frame with a {0} button detected".format(pos_button.value))
                break
        if not button_found:
            logger.debug("Button {0} not found, checking child frames".format(pos_button.value))
            for child_frame in self.frames:
                for button in child_frame.buttons:
                    if button.name == pos_button.value:
                        button_found = True
                        logger.debug("Frame with a {0} button detected".format(pos_button.value))
                        break
        return button_found

    def has_go_back(self) -> bool:
        """Checks if Go back button is present on a frame"""
        return self.has_button(POSButton.GO_BACK)


    def has_cancel(self) -> bool:
        """Checks if Cancel button is present on a frame"""
        return self.has_button(POSButton.CANCEL)

    def has_done(self) -> bool:
        """Checks if Done button is present on a frame"""
        return self.has_button(POSButton.DONE)

@wrap_all_methods_with_log_trace
class FuelPumpsFrame(UiFrame):
    def __init__(self, instance_id=0, obj_id=0, name=None, ab=0, bp=0):
        super().__init__(instance_id, obj_id, name, ab, bp)
        self._pumps = []

    @property
    def pumps(self) -> List[UiPumpDisplay]:
        """
         Get all pumps from the fuel pumps frame.

         :return: List of all pumps..
         :rtype: List[UiPumpDisplay]
         """
        return self._pumps

    def parse(self, element_dictionary: dict) -> None:
        """ Parse FuelPumpsFrame

        :param dict element_dictionary: Dictionary which should be used to fill FuelPumpsFrame's internal members
        """
        super().parse(element_dictionary)
        if element_dictionary is not None:
            self._pumps = UiPumpDisplay.parse_multiple(element_dictionary.get("Pumps", []))

    def find_pump(self, pump_number: int) -> Optional[UiPumpDisplay]:
        """
        Find pump by its number.

        :param int pump_number: Number of the pump which should be found on the frame.
        :return: Pump if found, otherwise None.
        :rtype: UiPumpDisplay or None
        """
        if self._pumps is not None:
            for pump in self.pumps:
                if pump.pump_number == pump_number:
                    return pump
