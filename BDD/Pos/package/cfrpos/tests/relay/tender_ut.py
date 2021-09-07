import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import TenderRelay


class TestTenderRelay(unittest.TestCase):
    def setUp(self):
        self.relay = TenderRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

    def tearDown(self):
        del self.relay

    def extract_tag(self, xml: str, tag_name: str) -> Union[None, str]:
        xml_tree = bs4.BeautifulSoup(xml, "xml")
        tag = xml_tree.find(tag_name)
        return str(tag) if tag is not None else ''

    def test_dataset(self):
        self.assertTrue(self.relay.update_required)
        self.relay.notify_applied()
        self.assertFalse(self.relay.update_required)

    def test_create_tender(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_tender(123456789, 'UnitTestTender2', 103, 2, 'USD', 123456, 8, 654321, 3)
        self.relay.create_tender(123456789, 'UnitTestTender', 102, 1.5, 'CZK') # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<Tenders>'
                '<record>'
                    '<TenderId>123456789</TenderId>'
                    '<DescriptionId>0</DescriptionId>'
                    '<TenderTypeId>102</TenderTypeId>'
                    '<RequiredSecurity>0</RequiredSecurity>'
                    '<DeviceListId>1</DeviceListId>'
                    '<DeviceControl>131072</DeviceControl>'
                    '<TenderMode>1331912704</TenderMode>'
                    '<TenderModes2>16</TenderModes2>'
                    '<StartingAmount>0</StartingAmount>'
                    '<ItemizerMask>0</ItemizerMask>'
                    '<AccumulatedCashIntake>0</AccumulatedCashIntake>'
                    '<ReconciliationGroupId>70000000030</ReconciliationGroupId>'
                    '<ExchangeRate>1.5</ExchangeRate>'
                    '<CurrencySymbol>CZK</CurrencySymbol>'
                    '<Description>UnitTestTender</Description>'
                    '<TenderBarText>UnitTestTender</TenderBarText>'
                    '<BitmapFileName/>'
                    '<UseChangeTenderId>123456789</UseChangeTenderId>'
                    '<OverridePaymentLimit>0</OverridePaymentLimit>'
                    '<AbsoluteRaymentLimit>0</AbsoluteRaymentLimit>'
                    '<OverrideRefundLimit>0</OverrideRefundLimit>'
                    '<AbsoluteRefundLimit>0</AbsoluteRefundLimit>'
                    '<CardValidationType>0</CardValidationType>'
                '</record>'
            '</Tenders>',
            self.extract_tag(self.relay.to_xml(), 'Tenders'))

    def test_create_tender_type(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_tender_type(123, 'test tender type', 5, 4, 2)
        self.relay.create_tender_type(123, 'test tender type 2') # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<TenderTypes>'
                '<record>'
                    '<TenderTypeId>123</TenderTypeId>'
                    '<TenderTypeMode>0</TenderTypeMode>'
                    '<TenderRanking>0</TenderRanking>'
                    '<Description>test tender type 2</Description>'
                    '<TierNumber>0</TierNumber>'
                '</record>'
            '</TenderTypes>',
            self.extract_tag(self.relay.to_xml(), 'TenderTypes'))

    def test_create_tender_external_id(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_tender_external_id(123, 321)
        self.relay.create_tender_external_id(123, 456) # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<TenderExternalIds>'
                '<record>'
                    '<TenderId>123</TenderId>'
                    '<ExternalId>456</ExternalId>'
                '</record>'
            '</TenderExternalIds>',
            self.extract_tag(self.relay.to_xml(), 'TenderExternalIds'))

    def test_create_tender_button(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_tender_button(123456789, 'UnitTestTender', 25)
        self.relay.create_tender_button(123456789, 'UnitTestTender', 25, action='EXACT_DOLLAR')
        self.relay.create_tender_button(123456789, 'UnitTestTender', 25, action='NEXT_DOLLAR')
        self.relay.create_tender_button(123456789, 'UnitTestTender', 25, action='QUICK_TENDER_BUTTON',
                                               preset_amount=200000)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<TenderButtons>'
                '<record>'
                    '<TenderId>123456789</TenderId>'
                    '<Position>25</Position>'
                    '<Location>1</Location>'
                    '<Action>1</Action>'
                    '<PresetAmount>0</PresetAmount>'
                    '<ButtonText>UnitTestTender</ButtonText>'
                    '<BitmapFilename/>'
                '</record>'
                '<record>'
                    '<TenderId>123456789</TenderId>'
                    '<Position>25</Position>'
                    '<Location>1</Location>'
                    '<Action>2</Action>'
                    '<PresetAmount>0</PresetAmount>'
                    '<ButtonText>UnitTestTender</ButtonText>'
                    '<BitmapFilename/>'
                '</record>'
                '<record>'
                    '<TenderId>123456789</TenderId>'
                    '<Position>25</Position>'
                    '<Location>1</Location>'
                    '<Action>3</Action>'
                    '<PresetAmount>0</PresetAmount>'
                    '<ButtonText>UnitTestTender</ButtonText>'
                    '<BitmapFilename/>'
                '</record>'
                '<record>'
                    '<TenderId>123456789</TenderId>'
                    '<Position>25</Position>'
                    '<Location>1</Location>'
                    '<Action>0</Action>'
                    '<PresetAmount>200000</PresetAmount>'
                    '<ButtonText>UnitTestTender</ButtonText>'
                    '<BitmapFilename/>'
                '</record>'
            '</TenderButtons>',
            self.extract_tag(self.relay.to_xml(), 'TenderButtons'))

    def test_create_tender_group(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_tender_group(999, 'test tender group', 5)
        self.relay.create_tender_group(999, 'test tender group 2') # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<TenderBarGroupButtonRecords>'
                '<record>'
                    '<TenderBarGroupButtonId>999</TenderBarGroupButtonId>'
                    '<Position>1</Position>'
                    '<ButtonText>test tender group 2</ButtonText>'
                    '<BitmapFileName/>'
                '</record>'
            '</TenderBarGroupButtonRecords>',
            self.extract_tag(self.relay.to_xml(), 'TenderBarGroupButtonRecords'))

    def test_assign_tender_to_group(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.assign_tender_to_group(222, 333)
        self.relay.assign_tender_to_group(444, 333) # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<TenderBarGroupButtonListRecords>'
                '<record>'
                    '<TenderId>333</TenderId>'
                    '<TenderBarGroupButtonId>444</TenderBarGroupButtonId>'
                '</record>'
            '</TenderBarGroupButtonListRecords>',
            self.extract_tag(self.relay.to_xml(), 'TenderBarGroupButtonListRecords'))

if __name__ == '__main__':
    unittest.main()
