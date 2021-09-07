import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import EmployeeRelay


class TestEmployeeRelay(unittest.TestCase):
    def setUp(self):
        self.relay = EmployeeRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_employee_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_employee(123, 'Bregovic', 'Goran', 'M', 1, 0)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<EmployeeRecords>'
                    '<record>'
                        '<FirstName>Goran</FirstName>'
                        '<LastName>Bregovic</LastName>'
                        '<MiddleInitial>M</MiddleInitial>'
                        '<EmployeeId>123</EmployeeId>'
                        '<OperatorMode>1</OperatorMode>'
                        '<OperatorActive>0</OperatorActive>'
                    '</record>'
                '</EmployeeRecords>',
                self.extract_tag(self.relay.to_xml(), 'EmployeeRecords'))

    def test_find_employee_record_by_id(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.assertFalse(self.relay.contains_employee_id(321))
        self.relay.create_employee(321, 'asd', 'fgh')
        self.assertTrue(self.relay.contains_employee_id(321))

if __name__ == '__main__':
    unittest.main()
