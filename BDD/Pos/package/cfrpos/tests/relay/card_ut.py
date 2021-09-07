import os
import unittest
from typing import List
from cfrpos.core.relay import CardRelay


class TestPrintFormatRelay(unittest.TestCase):
    @classmethod
    def setUp(self):
        self.relay = CardRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

    @classmethod
    def tearDown(self):
        del self.relay

    def test_remove_existing_loyalty_programs(self):
        loyalty_program_list = str(self.relay._soup.RelayFile.LoyaltyProgramListRecords)
        self.assertNotEqual(loyalty_program_list, '<LoyaltyProgramListRecords/>')

        self.relay.remove_existing_loyalty_programs()

        loyalty_program_list = str(self.relay._soup.RelayFile.LoyaltyProgramListRecords)
        self.assertEqual(loyalty_program_list, '<LoyaltyProgramListRecords/>')

    def test_create_loyalty_program_list_record(self):
        self.relay.remove_existing_loyalty_programs()
        loyalty_program_list = str(self.relay._soup.RelayFile.LoyaltyProgramListRecords)
        self.assertEqual(loyalty_program_list, '<LoyaltyProgramListRecords/>')

        self.relay.create_loyalty_program(loyalty_program_id=123, external_id='abc', program_name='def', display_order=1,
                                          alternate_id_eligible=1, alternate_id_min_length=2, alternate_id_max_length=8)

        loyalty_program_list = str(self.relay._soup.RelayFile.LoyaltyProgramListRecords)
        self.assertEqual(
            loyalty_program_list,
            '<LoyaltyProgramListRecords><record><LoyaltyProgramId>123</LoyaltyProgramId><ExternalId>abc</ExternalId><PosName>def</PosName><DisplayOrder>1</DisplayOrder><AlternateIdEligible>1</AlternateIdEligible><AlternateIdMinLength>2</AlternateIdMinLength><AlternateIdMaxLength>8</AlternateIdMaxLength></record></LoyaltyProgramListRecords>'
        )

    def test_create_and_alter_loyalty_program_list_record(self):
        self.relay.remove_existing_loyalty_programs()
        loyalty_program_list = str(self.relay._soup.RelayFile.LoyaltyProgramListRecords)
        self.assertEqual(loyalty_program_list, '<LoyaltyProgramListRecords/>')

        self.relay.create_loyalty_program(loyalty_program_id=123, external_id='abc', program_name='def', display_order='1')
        self.relay.create_loyalty_program(loyalty_program_id=123, external_id='abc', program_name='def', display_order='1', alternate_id_eligible=1, alternate_id_min_length=2, alternate_id_max_length=3)

        loyalty_program_list = str(self.relay._soup.RelayFile.LoyaltyProgramListRecords)
        self.assertEqual(
            loyalty_program_list,
            '<LoyaltyProgramListRecords><record><LoyaltyProgramId>123</LoyaltyProgramId><ExternalId>abc</ExternalId><PosName>def</PosName><DisplayOrder>1</DisplayOrder><AlternateIdEligible>1</AlternateIdEligible><AlternateIdMinLength>2</AlternateIdMinLength><AlternateIdMaxLength>3</AlternateIdMaxLength></record></LoyaltyProgramListRecords>'
        )


if __name__ == '__main__':
    unittest.main()