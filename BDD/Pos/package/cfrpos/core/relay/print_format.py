__all__ = [
    "PrintFormatRelay"
]

import yattag
from dataclasses import dataclass

from ..bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from ..bdd_utils.errors import ProductError
from . import RelayFile
from bs4 import BeautifulSoup as bs
from enum import Enum
from typing import List


@wrap_all_methods_with_log_trace
class PrintFormatRelay(RelayFile):
    """Representation of the print format relay file.
    """
    _pos_name = "PrintFormat"
    _pos_reboot_required = True
    _filename = "PrintFormat.xml"
    _default_version = 0
    _sort_rules = [
        ("TokenRecs", [
            ("SectionTokenId", int)
        ]),
        ("VariableRec", [
            ("VariableId", int)
        ]),
        ("SectionTokenRec", [
            ("PrintSectionId", int),
            ("LocaleId", int)
        ]),
        ("SectionRec", [
            ("PrintSectionId", int)
        ]),
        ("GroupRec", [
            ("PrintTypeGroupId", int)
        ])
    ]
    class JustificationType(Enum):
        left = 0
        center = 1
        right = 2

    class SectionType(Enum):
        HEADER = 0
        DETAIL = 1
        TOTAL = 2
        FOOTER = 3
        CREDIT_HEADER = 4
        CREDIT_FOOTER = 5
        CREDIT_DATA = 6
        CREDIT_SIGNATURE = 7
        TAX_INCLUDED_ANALYSIS = 8
        TAX_OWNER = 9
        LOYALTY_HEADER = 10
        LOYALTY_FOOTER = 11
        CREDIT_TRAILER = 20

    @dataclass
    class TokenRecs:
        """Class representing a token record. This is the smallest element."""
        print_token_id: int  # Unique ID of the print token.
        section_token_id: int  # ID of a section token the print token belongs to.
        line_number: int = 1  # Each section token can consist of several lines.
        sequence: int = 1  # Each section token line can consists of several parts.
        leading_spaces: int = 0  # Number of leading spaces.
        width: int = 40  # In number of characters.
        justification: int = 0  # See JustificationType enum.
        bold: int = 0  # True = 1, False = 0
        double_width: int = 0  # True = 1, False = 0
        double_height: int = 0  # True = 1, False = 0
        white_black_reverse: int = 0  # True = 1, False = 0
        hide_single_quantity: int = 0  # True = 1, False = 0
        print_variable_id: int = 0  # Links to a variable. Can be used instead of a fixed text in PrinterLine.
        printer_line: str = None  # Fixed text of the token.
        conditions: str = None  # Predefined condition like FUEL_SALE_ICR or CARWASH_ITEM.

    @dataclass
    class SectionTokenRec:
        """Basic information about the tokens. Each receipt section consists of one or more tokens."""
        print_section_id: int  # Unique ID of the section it belongs to.
        section_token_id: int  # ID of a section token from TokenRecs. This can repeat for different languages in different sections.
        locale_id: int = 1033  # Language locale code, for example 1033 is English.

    @dataclass
    class SectionRec:
        """Contains basic properties of receipt sections."""
        print_section_id: int  # Unique ID of the section.
        section_type: int  # One of the SectionType enum.
        items_flag: int = 0  #
        line_separated_flag: int = 0  # True = 1, False = 0

    @dataclass
    class GroupRec:
        """Contains the defined receipts and their sections. It basically puts all the other parts together."""
        print_section_id: int  # ID of a section. Must be unique under GroupRec records for given print_type_group_id.
        print_type_group_id: int  # ID of the receipt. Under this ID it groups several sections.
        sequence: int = 1  # The position in the receipt.

    def create_token_record(self, token_record: TokenRecs) -> None:
        """Appends a print token record or modifies an existing one.
        :param token_record: Data class representing token record.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("SectionTokenId", token_record.section_token_id)
            line("LineNumber", token_record.line_number)
            line("Sequence", token_record.sequence)
            line("PrintTokenId", token_record.print_token_id)
            line("LeadingSpaces", token_record.leading_spaces)
            line("Width", token_record.width)
            line("Justification", token_record.justification)
            line("Bold", token_record.bold)
            line("DoubleWidth", token_record.double_width)
            line("DoubleHeight", token_record.double_height)
            line("WhiteBlackReverse", token_record.white_black_reverse)
            line("HideSingleQuantity", token_record.hide_single_quantity)
            line("PrintVariableId", token_record.print_variable_id)
            if token_record.printer_line is not None and token_record.printer_line is not '':
                line("PrinterLine", token_record.printer_line)
            if token_record.conditions is not None and token_record.conditions is not '':
                line("Conditions", token_record.conditions)

        if self.contains_id_in_section('TokenRecs', 'PrintTokenId', token_record.print_token_id):
            parent = self._find_parent('TokenRecs', 'PrintTokenId', token_record.print_token_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.TokenRecs, doc)

    def create_section_token_record(self, section_token_record: SectionTokenRec) -> None:
        """Appends a print section token or modifies an existing one.
        :param section_token_record: Data class representing section token record.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("PrintSectionId", section_token_record.print_section_id)
            line("LocaleId", section_token_record.locale_id)
            line("SectionTokenId", section_token_record.section_token_id)

        if self.contains_id_in_section('SectionTokenRec', 'PrintSectionId', section_token_record.print_section_id):
            parent = self._find_parent('SectionTokenRec', 'PrintSectionId', section_token_record.print_section_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.SectionTokenRec, doc)

    def create_section_record(self, section_record: SectionRec) -> None:
        """Appends a print section or modifies an existing one.
        :param section_record: Data class representing section record.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("PrintSectionId", section_record.print_section_id)
            line("SectionType", section_record.section_type)
            line("ItemsFlag", section_record.items_flag)
            line("LineSeparatedFlag", section_record.line_separated_flag)

        if self.contains_id_in_section('SectionRec', 'PrintSectionId', section_record.print_section_id):
            parent = self._find_parent('SectionRec', 'PrintSectionId', section_record.print_section_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.SectionRec, doc)

    def create_group_record(self, group_record: GroupRec) -> None:
        """Appends a print group record.
        :param group_record: Data class representing group record.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("PrintTypeGroupId", group_record.print_type_group_id)
            line("PrintSectionId", group_record.print_section_id)
            line("Sequence", group_record.sequence)

        attribute = getattr(self._soup.RelayFile, 'GroupRec')
        records = attribute.find_all('record')
        for record in records:
            PrintTypeGroupId = getattr(record, 'PrintTypeGroupId')
            if PrintTypeGroupId is not None and PrintTypeGroupId.string == str(group_record.print_type_group_id):
                PrintSectionId = getattr(record, 'PrintSectionId')
                if PrintSectionId is not None and PrintSectionId.string == str(group_record.print_section_id):
                    Sequence = getattr(record, 'Sequence')
                    if Sequence is not None and Sequence.string == str(group_record.sequence):
                        break
        else:
            self._append_tag(self._soup.RelayFile.GroupRec, doc)

    def get_new_section_id(self) -> int:
        """Get a new section id for each new receipt.
        """
        section_id = 70000000340
        while self.contains_id_in_section('SectionRec', 'PrintSectionId', section_id):
            section_id = section_id + 1
        return section_id

    def get_new_token_id(self) -> int:
        """Get a new token id for each line in receipt.
        """
        token_id = 70000001400
        while self.contains_id_in_section('TokenRecs', 'PrintTokenId', token_id):
            token_id = token_id + 1
        return token_id

    def get_new_group_id(self) -> int:
        """Generate a new group id for each new receipt.
        """
        group_id = 70000000014
        while self.contains_id_in_section('GroupRec', 'PrintTypeGroupId', group_id):
            group_id = group_id + 1
        return group_id

    def _add_receipt_section_without_token(self, group_id: int, section_type: SectionType, sequence: int):
        """Creates and appends new simple section for given group ID.
        It does not need TokenRecs, since the data is obtained from the loyalty or credit.
        :param group_id: For which receipt ID should be section created
        :param section_type: SectionType LOYALTY_HEADER, LOYALTY_FOOTER, CREDIT_HEADER or CREDIT_FOOTER
        :param sequence: Sequence number for the group
        """
        section_id = self.get_new_section_id()
        self.create_section_record(self.SectionRec(print_section_id=section_id, section_type=section_type.value))
        self.create_section_token_record(self.SectionTokenRec(print_section_id=section_id, section_token_id=section_id))
        self.create_group_record(self.GroupRec(print_type_group_id=group_id, print_section_id=section_id, sequence=sequence))

    def _prepare_token(self,
                       line_number: int,
                       sequence: int,
                       width: int = 40,
                       leading_spaces: int = 0,
                       justification: JustificationType = JustificationType.left,
                       bold: bool = False,
                       double_width: bool = False,
                       double_height: bool = False,
                       hide_single_quantity: bool = False,
                       line: str = None,
                       variable: str = None,
                       conditions: str = None) -> TokenRecs:
        """Convenience function for preparing new token record TokenRecs.
        Should be used for creating tokens for function add_receipt_section_with_tokens.

        :param line_number: Each token section can consist of several lines.
        :param sequence: Each section token line can consists of several parts.
        :param width: Width in number of characters
        :param leading_spaces: Number of leading spaces
        :param justification: [description], defaults to JustificationType.left
        :param bold: Bold text, defaults to False
        :param double_width: Double width text, defaults to False
        :param double_height: Double height text, defaults to False
        :param hide_single_quantity: Hide in case of only one item
        :param line: Static text to be printed, defaults to None
        :param variable: Variable name to be filled with value, defaults to None
        :param conditions: Print condition, defaults to None
        """
        bool_to_int = lambda a: 1 if a else 0
        bold_int = bool_to_int(bold)
        double_width_int = bool_to_int(double_width)
        double_height_int = bool_to_int(double_height)
        hide_single_quantity_int = bool_to_int(hide_single_quantity)
        variable_id = 0
        if variable is not None:
            variable_id = self.find_variable_id(variable)

        return self.TokenRecs(print_token_id=0,
                              section_token_id=0,
                              line_number=line_number,
                              sequence=sequence,
                              width=width,
                              leading_spaces=leading_spaces,
                              justification=justification.value,
                              bold=bold_int,
                              double_width=double_width_int,
                              double_height=double_height_int,
                              hide_single_quantity=hide_single_quantity_int,
                              printer_line=line,
                              print_variable_id=variable_id,
                              conditions=conditions)

    def _add_receipt_section_with_tokens(self, group_id: int, section_type: SectionType, sequence: int, token_records: List[TokenRecs]) -> None:
        """Creates and appends new section for given group ID with list of tokens.
        The tokens will be filled with print_token_id, section_token_id and line_number.

        :param group_id: For which receipt ID should be section created
        :param section_type: Any of SectionType
        :param sequence: Sequence number for the group
        :param token_records: List of token record TokenRecs
        """
        section_id = self.get_new_section_id()
        self.create_section_record(self.SectionRec(print_section_id=section_id, section_type=section_type.value))
        self.create_section_token_record(self.SectionTokenRec(print_section_id=section_id, section_token_id=section_id))
        self.create_group_record(self.GroupRec(print_type_group_id=group_id, print_section_id=section_id, sequence=sequence))

        for token_record in token_records:
            token_record.print_token_id = self.get_new_token_id()
            token_record.section_token_id = section_id
            self.create_token_record(token_record)

    def _check_justification_type_value(self, justification: str) -> int:
        """Convert justification provided as a string, into integer value
        :param justification: Alignment to be used
        """
        for jType in self.JustificationType:
            if jType.name == justification:
                justification = jType.value
                break
            if justification not in self.JustificationType.__members__:
                raise ProductError('Wrong justification parameter is provided.')
        return justification

    def _locale_specification(self, section_id: int, locale: str = 'en-US') -> None:
        """Create a print section for a token, for a given locale parameter.
        :param section_id: Section id.
        :param locale: Locale specification for the token, default 'en-US'.
        """
        section_token_record = self.SectionTokenRec(print_section_id=section_id, section_token_id=section_id)
        if locale == 'fr-CA':
            section_token_record.locale_id = 1252
        elif locale == 'en-US' or locale == '':
            section_token_record.locale_id = 1033
        else:
            raise ProductError('Wrong locale specification parameter is provided.')
        self.create_section_token_record(section_token_record)

    def _parse_text_attributes(self, tag: yattag.Doc.Tag, default_segment_width: int = 40, default_bold: int = 0, default_justification: str = 'left') -> tuple:
        """Parse the tag's attributes: segment_width, bold, justification
        :param tag: Tag whose attributes should be parsed
        :param default_segment_width: Segment width to be used if not specified in tag attributes, allowed values (1-40)
        :param default_bold: Bold parameter to be used if not specified in tag attributes, allowed values (0,1), 0 = not bold, 1 = bold
        :param default_justification: Justification to be used if not specified in tag attributes, 0 = left, 1 = center, 2 = right
        """
        width = default_segment_width
        bold = default_bold
        justification = self._check_justification_type_value(default_justification)
        for attr in tag.attrs['class']:
            if 'width-' in attr:
                width = int(attr[6:])
                continue
            if attr == 'bold':
                bold = 1
                continue
            if attr == 'left':
                justification = self._check_justification_type_value('left')
                continue
            if attr == 'center':
                justification = self._check_justification_type_value('center')
                continue
            if attr == 'right':
                justification = self._check_justification_type_value('right')
                continue
        return width, bold, justification

    def _transform_receipt_line_in_print_token(self, section_id: int, line_number: int, line: str, condition: str, variable_id: int) -> None:
        """Transforms provided receipt line in the print token.
        :param section_id: Section ID
        :param line_number: The number of line in the receipt
        :param line: Line to transform in token
        :param condition: Condition for the token
        :param variable_id:  Variable ID
        """
        receipt_line = bs(line, 'lxml')
        tags = receipt_line.find_all('span')
        sequence_number = 1
        for tag in tags:
            printer_line = tag.text
            width, bold, justification = self._parse_text_attributes(tag)
            token_record = self.TokenRecs(section_token_id=section_id, print_token_id=self.get_new_token_id(), line_number=line_number, sequence=sequence_number, printer_line=printer_line, conditions=condition, width=width, bold=bold, justification=justification)
            if printer_line != '' and printer_line[0] == '{' and printer_line[-1] == '}':
                token_record.print_variable_id = variable_id
            self.create_token_record(token_record)
            sequence_number = sequence_number + 1

    def _create_receipt_print_section(self, print_section_id: int, section_name: str) -> None:
        """Creates a receipt section based on given section_name.
        :param print_section_id: Section ID.
        :param section_name: Name of the receipt section to be created, can be (header, footer...).
        :param section_type: Type of the receipt section to be created, can be (credit, loyalty).
        """
        if section_name.upper() not in self.SectionType.__members__:
            raise ProductError("Wrong section name provided.")

        for receipt_section in self.SectionType:
            if section_name.upper() == receipt_section.name:
                section_type_id = receipt_section.value
                self.create_section_record(self.SectionRec(print_section_id=print_section_id, section_type=section_type_id, line_separated_flag=1))
                break

    def find_variable_id(self, variable_name: str) -> int:
        """Returns the variable id for given variable name or 0 if not found.
        Searches the section VariableRec with variable records. 
        :param variable_name: Name of the variable
        """
        if self.contains_id_in_section('VariableRec', 'VariableName', variable_name):
            variable_id = getattr(self._soup.RelayFile, 'VariableRec').find('VariableName', string=variable_name).find_previous_sibling('VariableId').text
            return int(variable_id)
        elif variable_name == '':
            return 0
        else:
            raise ProductError("Variable name ({}) not defined.".format(variable_name))

    def set_receipt_section_content(self, section_id: int, section: str, line: str, line_number: int, condition: str = '', locale_specification: str = '', variable_id: str = '') -> None:
        """Creates a SectionRec, SectionTokenRec and TokenRecs with defined content.
        :param section_id: Section ID.
        :param section: Name of the receipt section to be created, can be any of SectionType enum.
        :param line: Line to transform in token.
        :param line_number: The number of line in the receipt.
        :param condition: Condition for section creation.
        :param locale_specification: Locale specification for the token, default 'en-US'.
        :param variable_id: Variable ID.
        :param section_type: Type of the receipt section to be created, can be (credit, loyalty).
        """
        self._create_receipt_print_section(print_section_id=section_id, section_name=section)
        self._locale_specification(section_id=section_id, locale=locale_specification)
        if line is not None:
            self._transform_receipt_line_in_print_token(section_id=section_id, line_number=line_number, line=line, condition=condition, variable_id=variable_id)
        else:
            raise ProductError("Line parameter has to be provided.")