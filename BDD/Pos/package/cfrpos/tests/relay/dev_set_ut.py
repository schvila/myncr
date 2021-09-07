import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import DevSetRelay


class TestDevSetRelay(unittest.TestCase):
    def setUp(self):
        self.relay = DevSetRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_device_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_device_record('Printer', 'Logical printer', 'Epson', '1', 2, 3, 4, 'Remote')
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<SetupRecords>'
                    '<record>'
                        '<Station_Number>3</Station_Number>'
                        '<Device_Type>Printer</Device_Type>'
                        '<Parameters>4</Parameters>'
                        '<Logical_Name>Logical printer</Logical_Name>'
                        '<Device_Name>Epson</Device_Name>'
                        '<Port_Name>1</Port_Name>'
                        '<DataInfo>2</DataInfo>'
                        '<Location>Remote</Location>'
                    '</record>'
                '</SetupRecords>',
                self.extract_tag(self.relay.to_xml(), 'SetupRecords'))

    def test_find_device_record_by_logical_name(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.assertFalse(self.relay.is_device_present('logical name', 5))
        self.relay.create_device_record('asd', 'logical name', 'Epson', '1', 5, 3, 4, 'Remote')
        self.assertTrue(self.relay.is_device_present('logical name', 5))

    def test_find_device_record_by_device_name(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.assertFalse(self.relay.is_device_record_added('device name 1'))
        self.relay.create_device_record('asd', 'logical name', 'device name 1', '1', 5, 3, 4, 'Remote')
        self.assertTrue(self.relay.is_device_record_added('device name 1'))


if __name__ == '__main__':
    unittest.main()
