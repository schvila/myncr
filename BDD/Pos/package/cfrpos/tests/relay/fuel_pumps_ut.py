import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import FuelPumpsRelay


class TestFuelPumpsRelay(unittest.TestCase):
    def setUp(self):
        self.relay = FuelPumpsRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_pump_time_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_pump_time_record(2, 3, 4, 5, 6, 7, 8)
        self.relay.create_pump_time_record(2, 3) # This record should override the last one
        self.relay.create_pump_time_record(2, 2, 4, 5, 6, 7, 8)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<TimeRecords>'
                    '<record>'
                        '<FuelingPoint>2</FuelingPoint>'
                        '<DayOfWeek>3</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                    '<record>'
                        '<FuelingPoint>2</FuelingPoint>'
                        '<DayOfWeek>2</DayOfWeek>'
                        '<StartHour>4</StartHour>'
                        '<StartMinute>5</StartMinute>'
                        '<EndHour>6</EndHour>'
                        '<EndMinute>7</EndMinute>'
                        '<ModeMask>8</ModeMask>'
                    '</record>'
                '</TimeRecords>',
                self.extract_tag(self.relay.to_xml(), 'TimeRecords'))

    def test_create_pump_week_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_pump_week_time_records(3)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<TimeRecords>'
                    '<record>'
                        '<FuelingPoint>3</FuelingPoint>'
                        '<DayOfWeek>0</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                    '<record>'
                        '<FuelingPoint>3</FuelingPoint>'
                        '<DayOfWeek>1</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                    '<record>'
                        '<FuelingPoint>3</FuelingPoint>'
                        '<DayOfWeek>2</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                    '<record>'
                        '<FuelingPoint>3</FuelingPoint>'
                        '<DayOfWeek>3</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                    '<record>'
                        '<FuelingPoint>3</FuelingPoint>'
                        '<DayOfWeek>4</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                    '<record>'
                        '<FuelingPoint>3</FuelingPoint>'
                        '<DayOfWeek>5</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                    '<record>'
                        '<FuelingPoint>3</FuelingPoint>'
                        '<DayOfWeek>6</DayOfWeek>'
                        '<StartHour>0</StartHour>'
                        '<StartMinute>0</StartMinute>'
                        '<EndHour>23</EndHour>'
                        '<EndMinute>59</EndMinute>'
                        '<ModeMask>775</ModeMask>'
                    '</record>'
                '</TimeRecords>',
                self.extract_tag(self.relay.to_xml(), 'TimeRecords'))

    def test_create_pump_configuration_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_pump_configuration_record(4, 100, 2, 3000, 4000, 1, 1, 2, 1)
        self.relay.create_pump_configuration_record(4) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ConfigurationRecords>'
                    '<record>'
                        '<FuelingPoint>4</FuelingPoint>'
                        '<DriveOffSeconds>300</DriveOffSeconds>'
                        '<AutoAuthSeconds>1</AutoAuthSeconds>'
                        '<MaxAuthAmount>20000</MaxAuthAmount>'
                        '<MaxAuthVolume>200000</MaxAuthVolume>'
                        '<MaxStack>2</MaxStack>'
                        '<ManualSaleType>0</ManualSaleType>'
                        '<VolumePerLiter>0</VolumePerLiter>'
                        '<NonIntegratedPumpFlag>0</NonIntegratedPumpFlag>'
                    '</record>'
                '</ConfigurationRecords>',
                self.extract_tag(self.relay.to_xml(), 'ConfigurationRecords'))

if __name__ == '__main__':
    unittest.main()
