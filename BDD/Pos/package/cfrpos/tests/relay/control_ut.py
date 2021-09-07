import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import ControlRelay


class TestControlRelay(unittest.TestCase):
    def setUp(self):
        self.relay = ControlRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_set_pos_option_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.set_option(1111, 2)
        self.relay.set_option(1111, 3) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ControlRecs>'
                    '<record>'
                        '<Id>1111</Id>'
                        '<Node>0</Node>'
                        '<Value>3</Value>'
                    '</record>'
                '</ControlRecs>',
                self.extract_tag(self.relay.to_xml(), 'ControlRecs'))

    def test_set_parameter_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.set_parameter(222, 'foo')
        self.relay.set_parameter(222, 'bar') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<ParameterRecs>'
                    '<record>'
                        '<Id>222</Id>'
                        '<Value>bar</Value>'
                    '</record>'
                '</ParameterRecs>',
                self.extract_tag(self.relay.to_xml(), 'ParameterRecs'))

if __name__ == '__main__':
    unittest.main()
