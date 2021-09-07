import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import TaxRelay, TaxType


class TestTaxRelay(unittest.TestCase):
    def setUp(self):
        self.relay = TaxRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_tax(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_tax_rate(123456, 8.888, 2000, 1, 1)
        self.relay.create_tax(15, 123456, 'Tax1', 70000000004, TaxType.PERCENT)

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<Itemizers>'
            '<record>'
            '<ItemizerNum>15</ItemizerNum>'
            '<TaxControlId>123456</TaxControlId>'
            '<TaxAuthorityId>70000000004</TaxAuthorityId>'
            '<ExternalId>123456</ExternalId>'
            '<Description>Tax1</Description>'
            '<TaxCalcMethod>1</TaxCalcMethod>'
            '<TaxOrder>0</TaxOrder>'
            '<Flags>0</Flags>'
            '</record>'
            '</Itemizers>',
            self.extract_tag(self.relay.to_xml(), 'Itemizers'))

        self.assertEqual(
            '<TaxControls>'
            '<record>'
            '<TaxControlId>123456</TaxControlId>'
            '<DestinationId>0</DestinationId>'
            '<TaxBreakpointId>0</TaxBreakpointId>'
            '<TaxPercentOrAmount>8.888</TaxPercentOrAmount>'
            '<RepeatAmount>0</RepeatAmount>'
            '<RepeatTax>0</RepeatTax>'
            '<RepeatStart>0</RepeatStart>'
            '<DescriptionId>0</DescriptionId>'
            '<Flags>0</Flags>'
            '<ThresholdQuantity>0</ThresholdQuantity>'
            '<ThresholdTaxPercent>0</ThresholdTaxPercent>'
            '<EffectiveYear>2000</EffectiveYear>'
            '<EffectiveMonth>1</EffectiveMonth>'
            '<EffectiveDay>1</EffectiveDay>'
            '</record>'
            '</TaxControls>',
            self.extract_tag(self.relay.to_xml(), 'TaxControls'))


    def test_create_tax_plan_with_tax(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_tax_plan_with_tax(10, 16384, 'tax_plan1', True, 1900, 1, 1)

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<TaxPlanScheduleTimetables>'
            '<record>'
            '<TaxPlanScheduleId>10</TaxPlanScheduleId>'
            '<ItemizerMask>16384</ItemizerMask>'
            '<EffectiveYear>1900</EffectiveYear>'
            '<EffectiveMonth>1</EffectiveMonth>'
            '<EffectiveDay>1</EffectiveDay>'
            '</record>'
            '</TaxPlanScheduleTimetables>',
            self.extract_tag(self.relay.to_xml(), 'TaxPlanScheduleTimetables'))

        self.assertEqual(
            '<ItemizerMasks>'
            '<record>'
            '<ItemizerMask>16384</ItemizerMask>'
            '<Description>tax_plan1</Description>'
            '<AllowTaxChangeAtPosFlag>1</AllowTaxChangeAtPosFlag>'
            '</record>'
            '</ItemizerMasks>',
            self.extract_tag(self.relay.to_xml(), 'ItemizerMasks'))


if __name__ == '__main__':
    unittest.main()
