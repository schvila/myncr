import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import ReductionRelay


class TestReductionRelay(unittest.TestCase):
    def setUp(self):
        self.relay = ReductionRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_reduction(self):
        """
        Resulting XML is ordered ascending regardless whether new records were added.
        """
        self.relay.create_reduction(123456789, 'Discount2', 2000, 'FUEL_PRICE_ROLLBACK', 'EMPLOYEE_DISCOUNT_TRANSACTION', 'STACKABLE_AND_ALLOW_ONLY_ONCE',
                                    False, False, True, False, '2015-06-25T00:00:00', '2032-06-25T00:00:00', 5, 6, 7, 'ext id', '8', 9, True)
        self.relay.create_reduction(123456789, 'Discount1', 1000, 'Preset_Amount', 'Single_Item', 'Allow_only_once', reduces_tax=True) # This record should override the last one
        self.relay.create_reduction(-987654321, 'Coupon1', 0, 'Prompted_Percent', 'Whole_Transaction', 'Allow_only_once')


        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<Reductions>'
            '<record>'
            '<ReductionId>-987654321</ReductionId>'
            '<DescriptionId>0</DescriptionId>'
            '<ReductionMode>8388612</ReductionMode>'
            '<DeviceListId>1</DeviceListId>'
            '<DeviceControl>0</DeviceControl>'
            '<RequiredSecurity>0</RequiredSecurity>'
            '<ReductionValue>0</ReductionValue>'
            '<MaxAmount>0</MaxAmount>'
            '<MaxQuantity>1</MaxQuantity>'
            '<ReductionItemizerMask>2147483645</ReductionItemizerMask>'
            '<TaxItemizerMask>0</TaxItemizerMask>'
            '<ValidationGroupId>0</ValidationGroupId>'
            '<DepartmentCategoryId>0</DepartmentCategoryId>'
            '<CardDefinitionGroupId>0</CardDefinitionGroupId>'
            '<StartDate>2012-06-25T00:00:00</StartDate>'
            '<EndDate>1899-01-01T00:00:00</EndDate>'
            '<Description>Coupon1</Description>'
            '<ExternalId/>'
            '<Priority>0</Priority>'
            '</record>'
            '<record>'
            '<ReductionId>123456789</ReductionId>'
            '<DescriptionId>0</DescriptionId>'
            '<ReductionMode>8421376</ReductionMode>'
            '<DeviceListId>1</DeviceListId>'
            '<DeviceControl>0</DeviceControl>'
            '<RequiredSecurity>0</RequiredSecurity>'
            '<ReductionValue>1000</ReductionValue>'
            '<MaxAmount>0</MaxAmount>'
            '<MaxQuantity>1</MaxQuantity>'
            '<ReductionItemizerMask>2147483645</ReductionItemizerMask>'
            '<TaxItemizerMask>4294967295</TaxItemizerMask>'
            '<ValidationGroupId>0</ValidationGroupId>'
            '<DepartmentCategoryId>0</DepartmentCategoryId>'
            '<CardDefinitionGroupId>0</CardDefinitionGroupId>'
            '<StartDate>2012-06-25T00:00:00</StartDate>'
            '<EndDate>1899-01-01T00:00:00</EndDate>'
            '<Description>Discount1</Description>'
            '<ExternalId/>'
            '<Priority>0</Priority>'
            '</record>'
            '</Reductions>',
            self.extract_tag(self.relay.to_xml(), 'Reductions'))

    def test_create_reduction_item_reqs(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_reduction_item_requirements(111, 222, True)
        self.relay.create_reduction_item_requirements(111, 333, False) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ReductionItemRequirements>'
                    '<record>'
                        '<ReductionId>111</ReductionId>'
                        '<RetailItemGroupId>333</RetailItemGroupId>'
                        '<FreeItemFlag>0</FreeItemFlag>'
                    '</record>'
                '</ReductionItemRequirements>',
                self.extract_tag(self.relay.to_xml(), 'ReductionItemRequirements'))

    def test_create_reduction_target(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_reduction_target(444, 555, 666, 777, 888, 999)
        self.relay.create_reduction_target(555, 666, 777)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ReductionTargets>'
                    '<record>'
                        '<ReductionId>444</ReductionId>'
                        '<ItemId>555</ItemId>'
                        '<Modifier1Id>777</Modifier1Id>'
                        '<Modifier2Id>888</Modifier2Id>'
                        '<Modifier3Id>999</Modifier3Id>'
                        '<ItemType>666</ItemType>'
                    '</record>'
                    '<record>'
                        '<ReductionId>555</ReductionId>'
                        '<ItemId>666</ItemId>'
                        '<Modifier1Id>1</Modifier1Id>'
                        '<Modifier2Id>1</Modifier2Id>'
                        '<Modifier3Id>1</Modifier3Id>'
                        '<ItemType>777</ItemType>'
                    '</record>'
                '</ReductionTargets>',
                self.extract_tag(self.relay.to_xml(), 'ReductionTargets'))

if __name__ == '__main__':
    unittest.main()
