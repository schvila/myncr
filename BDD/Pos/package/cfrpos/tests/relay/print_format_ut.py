import os
import unittest
from typing import List
from cfrpos.core.relay import PrintFormatRelay

class PrintFormatRelayHelper(PrintFormatRelay):
    """Class shows how to use the PrintFormatRelay. Check the create_default_receipt() method.
    """
    def _append_token_records_fuel(self, token_records: List[PrintFormatRelay.TokenRecs], line_number: int, conditions: str, header: str) -> int:
        """Appends new fuel token record to token_records
        Returns current line number.
        :param token_records: List of TokenRecs
        :param line_number: Current line number
        :param conditions: String with condition
        :param header: String of this fuel tokens section header
        """
        token_records.append(self._prepare_token(line_number=line_number, sequence=1, conditions=conditions, line=header))
        line_number += 1
        token_records.append(self._prepare_token(line_number=line_number, sequence=1, conditions=conditions, line='Pump #', width=6))
        token_records.append(self._prepare_token(line_number=line_number, sequence=2, conditions=conditions, variable='$P_FUEL_PUMP_NUMBER', width=4, leading_spaces=1))
        token_records.append(self._prepare_token(line_number=line_number, sequence=3, conditions=conditions, variable='$P_FUEL_GRADE', width=20))
        line_number += 1
        token_records.append(self._prepare_token(line_number=line_number, sequence=1, conditions=conditions, variable='$P_FUEL_ITEM_DESCRIPTION', width=31))
        token_records.append(self._prepare_token(line_number=line_number, sequence=2, conditions=conditions, variable='$P_ITEM_PRICE', width=9, justification=self.JustificationType.right))
        line_number += 1

        return line_number

    def _append_token_records_subitem(self, token_records: List[PrintFormatRelay.TokenRecs], line_number: int, conditions: str, descriptor: str, price: bool) -> None:
        """Appends new fuel token record to token_records
        :param token_records: List of TokenRecs
        :param line_number: Current line number
        :param conditions: String with condition
        :param descriptor: Item descriptor for identifying the subitem type
        :param price: Bool, true if subitem has price
        """
        token_records.append(self._prepare_token(line_number=line_number, sequence=1, conditions=conditions, line=descriptor, width=2))
        token_records.append(self._prepare_token(line_number=line_number, sequence=2, conditions=conditions, variable='$P_SUB_ITEM_QUANTITY', width=3))
        if price:
            token_records.append(self._prepare_token(line_number=line_number, sequence=3, conditions=conditions, variable='$P_SUB_ITEM_DESCRIPTION', width=25, leading_spaces=1))
            token_records.append(self._prepare_token(line_number=line_number, sequence=4, conditions=conditions, variable='$P_SUB_ITEM_PRICE', width=10))
        else:
            token_records.append(self._prepare_token(line_number=line_number, sequence=3, conditions=conditions, variable='$P_SUB_ITEM_DESCRIPTION', width=35, leading_spaces=1))

    def _append_token_records_combo(self, token_records: List[PrintFormatRelay.TokenRecs], line_number: int, conditions: str, descriptor: str, price: bool) -> None:
        """Appends new fuel token record to token_records
        :param token_records: List of TokenRecs
        :param line_number: Current line number
        :param conditions: String with condition
        :param descriptor: Item descriptor for identifying the combo type
        :param price: Bool, true if combo has price
        """
        token_records.append(self._prepare_token(line_number=line_number, sequence=1, conditions=conditions, variable='$P_SUB_ITEM_QUANTITY', width=5, leading_spaces=2, hide_single_quantity=True))
        token_records.append(self._prepare_token(line_number=line_number, sequence=2, conditions=conditions, line=descriptor, width=2))
        if price:
            token_records.append(self._prepare_token(line_number=line_number, sequence=3, conditions=conditions, variable='$P_SUB_ITEM_DESCRIPTION', width=20, leading_spaces=1))
            token_records.append(self._prepare_token(line_number=line_number, sequence=4, conditions=conditions, variable='$P_SUB_ITEM_PRICE', width=9, hide_single_quantity=True))
        else:
            token_records.append(self._prepare_token(line_number=line_number, sequence=3, conditions=conditions, variable='$P_SUB_ITEM_DESCRIPTION', width=29, leading_spaces=1))

    def _add_receipt_section_header(self, group_id: int, sequence: int) -> int:
        """Creates and appends default receipt header section with description and address.
        Returns updated sequence number.
        :param group_id: For which receipt ID should be section created
        :param sequence: Sequence number for the group
        """
        # Store description
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, justification=self.JustificationType.center, bold=True, variable='$P_STORE_DESCRIPTION'))
        token_records.append(self._prepare_token(line_number=2, sequence=1, justification=self.JustificationType.center, bold=True, variable='$P_STORE_ADDRESS'))
        token_records.append(self._prepare_token(line_number=3, sequence=1, justification=self.JustificationType.center, bold=True, variable='$P_STORE_ADDRESS_2'))

        self._add_receipt_section_with_tokens(group_id, self.SectionType.HEADER, sequence, token_records)
        sequence += 1

        # Duplicate info in case of ICR sale
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, conditions='FUEL_SALE_ICR', line='(DUPLICATE RECEIPT)'))
        self._add_receipt_section_with_tokens(group_id, self.SectionType.HEADER, sequence, token_records)
        sequence += 1

        # Receipt type info
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, conditions='FUEL_DRIVE_OFF'))
        token_records.append(self._prepare_token(line_number=2, sequence=1, conditions='FUEL_DRIVE_OFF', line='* * DRIVE OFF * *', justification=self.JustificationType.center, bold=True, double_width=True, double_height=True))
        token_records.append(self._prepare_token(line_number=3, sequence=1, conditions='FUEL_PUMP_TEST'))
        token_records.append(self._prepare_token(line_number=4, sequence=1, conditions='FUEL_PUMP_TEST', line='* * PUMP TEST * *', justification=self.JustificationType.center, bold=True, double_width=True, double_height=True))
        token_records.append(self._prepare_token(line_number=5, sequence=1, conditions='VOIDED'))
        token_records.append(self._prepare_token(line_number=6, sequence=1, conditions='VOIDED', line='* * VOID RECEIPT * *', justification=self.JustificationType.center, bold=True, double_width=True, double_height=True))
        token_records.append(self._prepare_token(line_number=7, sequence=1, conditions='REFUND_TRAN', line='* * REFUND * *', justification=self.JustificationType.center, bold=True, double_width=True, double_height=True))
        token_records.append(self._prepare_token(line_number=8, sequence=1, conditions='RETRIEVED_REFUNDED'))
        token_records.append(self._prepare_token(line_number=9, sequence=1, conditions='RETRIEVED_REFUNDED', line='* * REFUND * *', justification=self.JustificationType.center, bold=True, double_width=True, double_height=True))
        token_records.append(self._prepare_token(line_number=10, sequence=1, conditions='DUPLICATED_RECEIPT'))
        token_records.append(self._prepare_token(line_number=11, sequence=1, conditions='DUPLICATED_RECEIPT', line='(DUPLICATE RECEIPT)', justification=self.JustificationType.center))
        token_records.append(self._prepare_token(line_number=12, sequence=1, line='------------------------------------------------------------------------', justification=self.JustificationType.center))

        # Date and time
        token_records.append(self._prepare_token(line_number=13, sequence=1, variable='$P_DATE', justification=self.JustificationType.right, width=19))
        token_records.append(self._prepare_token(line_number=13, sequence=2, width=2))
        token_records.append(self._prepare_token(line_number=13, sequence=3, variable='$P_TIME', justification=self.JustificationType.left, width=19))
        token_records.append(self._prepare_token(line_number=14, sequence=1))

        # Transaction info
        token_records.append(self._prepare_token(line_number=15, sequence=1, line='Register:', width=9))
        token_records.append(self._prepare_token(line_number=15, sequence=2, variable='$P_REGISTER', width=8, leading_spaces=1))
        token_records.append(self._prepare_token(line_number=15, sequence=3, line='Tran Seq No:', width=13))
        token_records.append(self._prepare_token(line_number=15, sequence=4, variable='$P_ORDER_NUM', width=10, justification=self.JustificationType.right))

        # Store and operator
        token_records.append(self._prepare_token(line_number=16, sequence=1, line='Store No:', width=9))
        token_records.append(self._prepare_token(line_number=16, sequence=2, variable='$P_STORE_NAME', width=6, leading_spaces=1))
        token_records.append(self._prepare_token(line_number=16, sequence=3, variable='$P_OPERATOR_NAME', width=25, justification=self.JustificationType.right))
        token_records.append(self._prepare_token(line_number=17, sequence=1))

        # Merchant or customer receipt
        token_records.append(self._prepare_token(line_number=18, sequence=1, conditions='MERCHANT_RECEIPT', line='(MERCHANT RECEIPT)', justification=self.JustificationType.center))
        token_records.append(self._prepare_token(line_number=19, sequence=1, conditions='CUSTOMER_RECEIPT', line='(CUSTOMER RECEIPT)', justification=self.JustificationType.center))

        self._add_receipt_section_with_tokens(group_id, self.SectionType.HEADER, sequence, token_records)
        sequence += 1

        return sequence

    def _add_receipt_section_detail_fuel(self, group_id: int, sequence: int) -> int:
        """Adds receipt section with fuel item details.
        Returns updated sequence number.
        :param group_id: For which receipt ID should be section created
        :param sequence: Sequence number for the group
        """
        token_records = []
        line_number = self._append_token_records_fuel(token_records, 1, 'FUEL_SALE_ICR', 'Fuel Sale')
        line_number = self._append_token_records_fuel(token_records, line_number, 'FUEL_SALE_POST_PAY', 'Fuel Sale PostPay')
        line_number = self._append_token_records_fuel(token_records, line_number, 'FUEL_SALE_PRE_PAY_START', 'Fuel Sale PrePay')
        line_number = self._append_token_records_fuel(token_records, line_number, 'FUEL_SALE_PRE_PAY_ADJUST', 'Fuel Sale PrePay Adjust')
        line_number = self._append_token_records_fuel(token_records, line_number, 'FUEL_SALE_PRE_PAY_COMPLETE', 'Fuel Sale PrePay Complete')

        self._add_receipt_section_with_tokens(group_id, self.SectionType.DETAIL, sequence, token_records)
        sequence += 1

        return sequence

    def _add_receipt_section_detail_items(self, group_id: int, sequence: int) -> int:
        """Adds receipt section with items details.
        Returns updated sequence number.
        :param group_id: For which receipt ID should be section created
        :param sequence: Sequence number for the group
        """
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, conditions='ITEM', line='I', width=1))
        token_records.append(self._prepare_token(line_number=1, sequence=2, conditions='ITEM', variable='$P_ITEM_QUANTITY', width=4))
        token_records.append(self._prepare_token(line_number=1, sequence=3, conditions='ITEM', variable='$P_ITEM_DESCRIPTION', width=25, leading_spaces=1))
        token_records.append(self._prepare_token(line_number=1, sequence=4, conditions='ITEM', variable='$P_ITEM_PRICE', width=10, leading_spaces=1, justification=self.JustificationType.right))

        self._append_token_records_subitem(token_records, 2, 'SUBITEM', 'X', True)
        self._append_token_records_subitem(token_records, 3, 'SUBITEM_PRICE', 'Y', True)
        self._append_token_records_subitem(token_records, 4, 'SUBITEM_ADDED_PRICE', 'A', True)
        self._append_token_records_subitem(token_records, 5, 'SUBITEM_ADDED_NOPRICE', 'AN', False)
        self._append_token_records_subitem(token_records, 6, 'SUBITEM_DELETED_PRICE', 'D', True)
        self._append_token_records_subitem(token_records, 7, 'SUBITEM_DELETED_NOPRICE', 'DN', False)

        token_records.append(self._prepare_token(line_number=8, sequence=1, conditions='CARWASH_ITEM', line='**************************', leading_spaces=4))
        token_records.append(self._prepare_token(line_number=9, sequence=1, conditions='CARWASH_ITEM', line='Wash Code:', width=19, leading_spaces=5))
        token_records.append(self._prepare_token(line_number=9, sequence=2, conditions='CARWASH_ITEM', variable='$P_CARWASH_CODE', width=21, leading_spaces=1))
        token_records.append(self._prepare_token(line_number=10, sequence=1, conditions='CARWASH_ITEM', line='Valid For 14 Days', leading_spaces=4))
        token_records.append(self._prepare_token(line_number=11, sequence=1, conditions='CARWASH_ITEM', line='**************************', leading_spaces=4))

        self._append_token_records_combo(token_records, 12, 'COMBOITEM_ADDED_PRICE', '+', True)
        self._append_token_records_combo(token_records, 13, 'COMBOITEM_DELETED_PRICE', '-', True)
        self._append_token_records_combo(token_records, 14, 'COMBOITEM_ADDED_NOPRICE', '+', False)
        self._append_token_records_combo(token_records, 15, 'COMBOITEM_DELETED_NOPRICE', '+', False)

        self._add_receipt_section_with_tokens(group_id, self.SectionType.DETAIL, sequence, token_records)
        sequence += 1

        return sequence

    def _add_receipt_section_detail_tender(self, group_id: int, sequence: int) -> int:
        """Adds default detail section to the receipt. 
        Returns updated sequence number.
        :param group_id: For which receipt ID should be section created
        :param sequence: Sequence number for the group
        """
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, conditions='TENDER', variable='$P_TENDER_DESCRIPTION', width=30))
        token_records.append(self._prepare_token(line_number=1, sequence=2, conditions='TENDER', variable='$P_TENDER_AMOUNT', width=10, justification=self.JustificationType.right))

        self._add_receipt_section_with_tokens(group_id, self.SectionType.DETAIL, sequence, token_records)
        sequence += 1

        return sequence

    def _add_receipt_section_total(self, group_id: int, sequence: int) -> int:
        """Adds default total section. 
        Returns updated sequence number.
        :param group_id: For which receipt ID should be section created
        :param sequence: Sequence number for the group
        """
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, line='-----------', justification=self.JustificationType.right))
        token_records.append(self._prepare_token(line_number=2, sequence=1, line='Sub. Total:', width=30))
        token_records.append(self._prepare_token(line_number=2, sequence=2, variable='$P_SUB_TOTAL', width=10, justification=self.JustificationType.right))
        token_records.append(self._prepare_token(line_number=3, sequence=1, line='Tax:', width=30))
        token_records.append(self._prepare_token(line_number=3, sequence=2, variable='$P_TAX', width=10, justification=self.JustificationType.right))
        token_records.append(self._prepare_token(line_number=4, sequence=1, line='Total:', width=30))
        token_records.append(self._prepare_token(line_number=4, sequence=2, variable='$P_TOTAL', width=10, justification=self.JustificationType.right))
        token_records.append(self._prepare_token(line_number=5, sequence=1, line='Discount Total:', width=30))
        token_records.append(self._prepare_token(line_number=5, sequence=2, variable='$P_DISCOUNT_TOTAL', width=10, justification=self.JustificationType.right))
        token_records.append(self._prepare_token(line_number=6, sequence=1))

        self._add_receipt_section_with_tokens(group_id, self.SectionType.TOTAL, sequence, token_records)
        sequence += 1

        # Tender (f.e. Cash)
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, conditions='TENDER', variable='$P_TENDER_DESCRIPTION', width=30))
        token_records.append(self._prepare_token(line_number=1, sequence=2, conditions='TENDER', variable='$P_TENDER_AMOUNT', width=10, justification=self.JustificationType.right))

        # The SectionType is DETAIL, yet the BDD test expects the TENDER info in TOTAL section of the receipt
        self._add_receipt_section_with_tokens(group_id, self.SectionType.DETAIL, sequence, token_records)
        sequence += 1

        # Change
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, conditions='CHANGE', line='Change', width=30))
        token_records.append(self._prepare_token(line_number=1, sequence=2, conditions='CHANGE', variable='$P_BALANCE', width=10, justification=self.JustificationType.right))

        self._add_receipt_section_with_tokens(group_id, self.SectionType.TOTAL, sequence, token_records)
        sequence += 1

        return sequence

    def _add_receipt_section_footer_drive_off_pump_test(self, group_id: int, sequence: int) -> int:
        """Adds default footer for drive off and pump test. 
        Returns updated sequence number.
        :param group_id: For which receipt ID should be section created
        :param sequence: Sequence number for the group
        """
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, conditions='FUEL_DRIVE_OFF', line='DRIVE OFF INFO:', justification=self.JustificationType.center, bold=True, double_width=True))
        token_records.append(self._prepare_token(line_number=2, sequence=1, conditions='FUEL_DRIVE_OFF'))
        token_records.append(self._prepare_token(line_number=3, sequence=1, conditions='FUEL_DRIVE_OFF', line='Plate Number:', width=13, bold=True))
        token_records.append(self._prepare_token(line_number=3, sequence=2, conditions='FUEL_DRIVE_OFF', line='________________________________________________________', width=27))
        token_records.append(self._prepare_token(line_number=4, sequence=1, conditions='FUEL_DRIVE_OFF', line='Make/Model:', width=11, bold=True))
        token_records.append(self._prepare_token(line_number=4, sequence=2, conditions='FUEL_DRIVE_OFF', line='________________________________________________________', width=29))
        token_records.append(self._prepare_token(line_number=5, sequence=1, conditions='FUEL_DRIVE_OFF', line='Color:', width=6, bold=True))
        token_records.append(self._prepare_token(line_number=5, sequence=2, conditions='FUEL_DRIVE_OFF', line='________________________________________________________', width=34))
        token_records.append(self._prepare_token(line_number=6, sequence=1, conditions='FUEL_DRIVE_OFF'))

        token_records.append(self._prepare_token(line_number=7, sequence=1, conditions='FUEL_PUMP_TEST', line='PUMP TEST INFO:', justification=self.JustificationType.center, bold=True, double_width=True))
        token_records.append(self._prepare_token(line_number=8, sequence=1, conditions='FUEL_PUMP_TEST'))
        token_records.append(self._prepare_token(line_number=9, sequence=1, conditions='FUEL_PUMP_TEST', line='Employee:', width=10, bold=True))
        token_records.append(self._prepare_token(line_number=9, sequence=2, conditions='FUEL_PUMP_TEST', variable='$P_OPERATOR_NAME', width=30))
        token_records.append(self._prepare_token(line_number=10, sequence=1, conditions='FUEL_PUMP_TEST'))
        token_records.append(self._prepare_token(line_number=11, sequence=1, conditions='FUEL_PUMP_TEST', line='Signature:', width=10, bold=True))
        token_records.append(self._prepare_token(line_number=11, sequence=2, conditions='FUEL_PUMP_TEST', line='________________________________________________________________________________', width=30))
        token_records.append(self._prepare_token(line_number=12, sequence=1, conditions='FUEL_PUMP_TEST'))

        self._add_receipt_section_with_tokens(group_id, self.SectionType.FOOTER, sequence, token_records)
        sequence += 1

        return sequence

    def _add_receipt_section_footer_message(self, group_id: int, sequence: int) -> int:
        """Adds default footer message. 
        Returns updated sequence number.
        :param group_id: For which receipt ID should be section created
        :param sequence: Sequence number for the group
        """
        token_records = []
        token_records.append(self._prepare_token(line_number=1, sequence=1, line='Thanks', width=40, bold=True, double_height=True, justification=self.JustificationType.center))
        token_records.append(self._prepare_token(line_number=2, sequence=1, line='For Your Business', width=40, bold=True, double_height=True, justification=self.JustificationType.center))
        token_records.append(self._prepare_token(line_number=3, sequence=1, variable='$IMG_SIGNATURE'))

        self._add_receipt_section_with_tokens(group_id, self.SectionType.FOOTER, sequence, token_records)
        sequence += 1

        return sequence

    def create_default_receipt(self):
        """This is an example that will generate the default receipt XML
        This shows how the PrintFormat.xml works and should be used in case of modification to the receipt is needed.
        :param save: Save the generated XML
        """
        # Clear the loaded data from PrintFormat.xml of all records with the exception of VariableRec, these are needed
        getattr(self._soup.RelayFile, 'GroupRec').clear()
        getattr(self._soup.RelayFile, 'SectionRec').clear()
        getattr(self._soup.RelayFile, 'SectionTokenRec').clear()
        getattr(self._soup.RelayFile, 'TokenRecs').clear()

        # Fill with data
        group_id = self.get_new_group_id()
        sequence = 1

        # Header
        sequence = self._add_receipt_section_header(group_id, sequence)
        # Credit header
        self._add_receipt_section_without_token(group_id, self.SectionType.CREDIT_HEADER, sequence)
        sequence += 1
        # Loyalty header
        self._add_receipt_section_without_token(group_id, self.SectionType.LOYALTY_HEADER, sequence)
        sequence += 1

        # Detail
        sequence = self._add_receipt_section_detail_fuel(group_id, sequence)
        sequence = self._add_receipt_section_detail_items(group_id, sequence)

        # Total
        sequence = self._add_receipt_section_total(group_id, sequence)

        # Footer
        sequence = self._add_receipt_section_footer_drive_off_pump_test(group_id, sequence)
        # Credit footer
        self._add_receipt_section_without_token(group_id, self.SectionType.CREDIT_FOOTER, sequence)
        sequence += 1
        # Loyalty footer
        self._add_receipt_section_without_token(group_id, self.SectionType.LOYALTY_FOOTER, sequence)
        sequence += 1
        sequence = self._add_receipt_section_footer_message(group_id, sequence)


class TestPrintFormatRelay(unittest.TestCase):
    @classmethod
    def setUp(self):
        self.relay = PrintFormatRelayHelper.load(os.path.dirname(os.path.abspath(__file__)), True)

    @classmethod
    def tearDown(self):
        del self.relay

    def test_generate_default(self):
        # Test the generation of PrintFormat.xml
        self.relay.create_default_receipt()

        # Save the XML data to file
        if False:
            path = os.path.dirname(os.path.abspath(__file__)) + '\\PrintFormatNew.xml'
            with open(path, 'w') as file:
                file.write(str(self.relay._soup))

        token_record_first = self.relay._find_tag('PrintTokenId', 'TokenRecs', string='70000001400')
        token_record_last = self.relay._find_tag('PrintTokenId', 'TokenRecs', string='70000001538')
        self.assertTrue(token_record_first is not None)
        self.assertTrue(token_record_last is not None)


if __name__ == '__main__':
    unittest.main()