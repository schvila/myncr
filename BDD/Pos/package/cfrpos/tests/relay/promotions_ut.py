import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import PromotionsRelay


class TestPromotionsRelay(unittest.TestCase):
    def setUp(self):
        self.relay = PromotionsRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_promotion_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_promotion(123, 234, 1.55, 'test prom id', '1990-01-01T00:00:00', '2050-01-01T00:00:00')
        self.relay.create_promotion(123, 345, 5.11, 'test prom id 2') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<Promotions>'
                    '<record>'
                        '<ItemId>123</ItemId>'
                        '<Modifier1Id>345</Modifier1Id>'
                        '<PromotionStartTime>1900-01-01T00:00:00</PromotionStartTime>'
                        '<PromotionEndTime>2099-01-01T00:00:00</PromotionEndTime>'
                        '<PromotionPrice>5.11</PromotionPrice>'
                        '<PromotionId>test prom id 2</PromotionId>'
                    '</record>'
                '</Promotions>',
                self.extract_tag(self.relay.to_xml(), 'Promotions'))

if __name__ == '__main__':
    unittest.main()
