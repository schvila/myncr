import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import DestinationRelay


class TestDestinationRelay(unittest.TestCase):
    def setUp(self):
        self.relay = DestinationRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_destination_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_destination(1, 2, 'dest desc', 3, 4, 5)
        self.relay.create_destination(1, 6, 'desc dest', 7, 8, 9) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<DestRecs>'
                    '<record>'
                        '<DestinationId>1</DestinationId>'
                        '<DescriptionId>0</DescriptionId>'
                        '<RequiredSecurity>8</RequiredSecurity>'
                        '<DeviceListId>6</DeviceListId>'
                        '<DeviceControl>0</DeviceControl>'
                        '<Description>desc dest</Description>'
                        '<KDSDestID>7</KDSDestID>'
                    '</record>'
                '</DestRecs>',
                self.extract_tag(self.relay.to_xml(), 'DestRecs'))
        self.assertEqual(
            '<DestinationExternalIds>'
                '<record>'
                    '<DestinationId>1</DestinationId>'
                    '<ExternalId>9</ExternalId>'
                '</record>'
            '</DestinationExternalIds>',
            self.extract_tag(self.relay.to_xml(), 'DestinationExternalIds'))

    def test_create_destination_external_id_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_destination_ext_id(2, 3)
        self.relay.create_destination_ext_id(2, 4) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
            '<DestinationExternalIds>'
                '<record>'
                    '<DestinationId>2</DestinationId>'
                    '<ExternalId>4</ExternalId>'
                '</record>'
            '</DestinationExternalIds>',
            self.extract_tag(self.relay.to_xml(), 'DestinationExternalIds'))

if __name__ == '__main__':
    unittest.main()
