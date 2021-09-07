import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import QuantityRestrictionRelay


class TestQuantityRestrictionRelay(unittest.TestCase):
    def setUp(self):
        self.relay = QuantityRestrictionRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_sales_quantity_attributes(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_sales_quantity_attributes(123456789, 'Test description')
        self.relay.create_sales_quantity_attributes(123456789, 'UnitTestRestriction') # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<SalesQuantityAttributes>'
            '<record>'
            '<SalesQuantityId>123456789</SalesQuantityId>'
            '<Text>UnitTestRestriction</Text>'
            '</record>'
            '</SalesQuantityAttributes>',
            self.extract_tag(self.relay.to_xml(), 'SalesQuantityAttributes'))

    def test_create_sales_quantity_restrictions(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_sales_quantity_restrictions(9876543210, 987654321, 999)
        self.relay.create_sales_quantity_restrictions(9876543210, 123456789, 150) # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<SalesQuantityRestrictions>'
            '<record>'
            '<RetailItemGroupId>9876543210</RetailItemGroupId>'
            '<SalesQuantityId>123456789</SalesQuantityId>'
            '<TransactionLimit>150</TransactionLimit>'
            '</record>'
            '</SalesQuantityRestrictions>',
            self.extract_tag(self.relay.to_xml(), 'SalesQuantityRestrictions'))

    def test_create_retail_item_sales_quantity_attributes(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_retail_item_sales_quantity_attributes(4567, 10, 11, 12, 987654321, 999)
        self.relay.create_retail_item_sales_quantity_attributes(4567, 10, 11, 12, 123456789, 150) # This record should override the last one

        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<RetailItemSalesQuantityAttributes>'
            '<record>'
            '<ItemId>4567</ItemId>'
            '<Modifier1Id>10</Modifier1Id>'
            '<Modifier2Id>11</Modifier2Id>'
            '<Modifier3Id>12</Modifier3Id>'
            '<SalesQuantityId>123456789</SalesQuantityId>'
            '<Quantity>150</Quantity>'
            '</record>'
            '</RetailItemSalesQuantityAttributes>',
            self.extract_tag(self.relay.to_xml(), 'RetailItemSalesQuantityAttributes'))



if __name__ == '__main__':
    unittest.main()
