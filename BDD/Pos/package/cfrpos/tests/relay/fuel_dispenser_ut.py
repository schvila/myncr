import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import FuelDispenserRelay


class TestFuelDispenserRelay(unittest.TestCase):
    def setUp(self):
        self.relay = FuelDispenserRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_fueling_point_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_fueling_point_record(1)
        self.relay.create_fueling_point_record(1, 0, 2, 2, 100, 10, 1000, 2000, 30000, 1, 2, 3, 2, 3, 3, 'asd') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<FuelingPointRecords>'
                    '<record>'
                        '<FuelingPointNumber>1</FuelingPointNumber>'
                        '<Enabled>0</Enabled>'
                        '<DefaultTier>2</DefaultTier>'
                        '<ServiceMode>2</ServiceMode>'
                        '<VolumeMultiplier>100</VolumeMultiplier>'
                        '<PricePerUnitMultiplier>10</PricePerUnitMultiplier>'
                        '<MoneyMultiplier>1000</MoneyMultiplier>'
                        '<MaxAuthAmount>2000</MaxAuthAmount>'
                        '<MaxAuthVolume>30000</MaxAuthVolume>'
                        '<NonIntegratedPump>1</NonIntegratedPump>'
                        '<PumpPPUPrecision>2</PumpPPUPrecision>'
                        '<PumpMoneyPrecision>3</PumpMoneyPrecision>'
                        '<PumpVolumePrecision>2</PumpVolumePrecision>'
                        '<MaxStack>3</MaxStack>'
                        '<HoseCount>3</HoseCount>'
                        '<HoseRecords>asd</HoseRecords>'
                    '</record>'
                '</FuelingPointRecords>',
                self.extract_tag(self.relay.to_xml(), 'FuelingPointRecords'))

    def test_create_hose_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_fueling_point_record(11)
        self.relay.create_hose_record(11, 2, 123, 3, 1, 0, 50, 'asd')
        self.relay.create_hose_record(11, 2, 321, 1) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<FuelingPointRecords>'
                    '<record>'
                        '<FuelingPointNumber>11</FuelingPointNumber>'
                        '<Enabled>1</Enabled>'
                        '<DefaultTier>1</DefaultTier>'
                        '<ServiceMode>1</ServiceMode>'
                        '<VolumeMultiplier>1000</VolumeMultiplier>'
                        '<PricePerUnitMultiplier>1000</PricePerUnitMultiplier>'
                        '<MoneyMultiplier>100</MoneyMultiplier>'
                        '<MaxAuthAmount>20000</MaxAuthAmount>'
                        '<MaxAuthVolume>20000</MaxAuthVolume>'
                        '<NonIntegratedPump>0</NonIntegratedPump>'
                        '<PumpPPUPrecision>3</PumpPPUPrecision>'
                        '<PumpMoneyPrecision>2</PumpMoneyPrecision>'
                        '<PumpVolumePrecision>3</PumpVolumePrecision>'
                        '<MaxStack>2</MaxStack>'
                        '<HoseCount>4</HoseCount>'
                        '<HoseRecords>'
                            '<record>'
                                '<HoseNumber>2</HoseNumber>'
                                '<Enabled>1</Enabled>'
                                '<ProductNumber>321</ProductNumber>'
                                '<PrimaryTank>1</PrimaryTank>'
                                '<SecondaryTank>0</SecondaryTank>'
                                '<PrimaryBlendPercentage>100</PrimaryBlendPercentage>'
                                '<TierServiceModePrices/>'
                            '</record>'
                        '</HoseRecords>'
                    '</record>'
                '</FuelingPointRecords>',
                self.extract_tag(self.relay.to_xml(), 'FuelingPointRecords'))

    def test_create_hose_tier_price_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_fueling_point_record(11)
        self.relay.create_hose_record(11, 2, 321, 1)
        self.relay.create_tier_service_mode_prices(11, 2, 1100)
        self.relay.create_tier_service_mode_prices(11, 2, 2100)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<FuelingPointRecords>'
                    '<record>'
                        '<FuelingPointNumber>11</FuelingPointNumber>'
                        '<Enabled>1</Enabled>'
                        '<DefaultTier>1</DefaultTier>'
                        '<ServiceMode>1</ServiceMode>'
                        '<VolumeMultiplier>1000</VolumeMultiplier>'
                        '<PricePerUnitMultiplier>1000</PricePerUnitMultiplier>'
                        '<MoneyMultiplier>100</MoneyMultiplier>'
                        '<MaxAuthAmount>20000</MaxAuthAmount>'
                        '<MaxAuthVolume>20000</MaxAuthVolume>'
                        '<NonIntegratedPump>0</NonIntegratedPump>'
                        '<PumpPPUPrecision>3</PumpPPUPrecision>'
                        '<PumpMoneyPrecision>2</PumpMoneyPrecision>'
                        '<PumpVolumePrecision>3</PumpVolumePrecision>'
                        '<MaxStack>2</MaxStack>'
                        '<HoseCount>4</HoseCount>'
                        '<HoseRecords>'
                            '<record>'
                                '<HoseNumber>2</HoseNumber>'
                                '<Enabled>1</Enabled>'
                                '<ProductNumber>321</ProductNumber>'
                                '<PrimaryTank>1</PrimaryTank>'
                                '<SecondaryTank>0</SecondaryTank>'
                                '<PrimaryBlendPercentage>100</PrimaryBlendPercentage>'
                                '<TierServiceModePrices>'
                                    '<record>'
                                        '<UnitPrice>1100</UnitPrice>'
                                    '</record>'
                                    '<record>'
                                        '<UnitPrice>2100</UnitPrice>'
                                    '</record>'
                                '</TierServiceModePrices>'
                            '</record>'
                        '</HoseRecords>'
                    '</record>'
                '</FuelingPointRecords>',
                self.extract_tag(self.relay.to_xml(), 'FuelingPointRecords'))

    def test_find_fueling_point_by_id(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.assertFalse(self.relay.is_pump_configured(2))
        self.relay.create_fueling_point_record(2)
        self.assertTrue(self.relay.is_pump_configured(2))

if __name__ == '__main__':
    unittest.main()
