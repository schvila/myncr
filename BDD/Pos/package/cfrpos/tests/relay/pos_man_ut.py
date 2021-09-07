import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import POSManRelay


class TestPOSManRelay(unittest.TestCase):
    def setUp(self):
        self.relay = POSManRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_operator_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_operator(1, 1234, 'Schwartznegger', 'Arnold', 'Terminator', 'ext id', 1234, 'T', 1, 1028, 1, [0])
        self.relay.create_operator(1, 2345, 'Stallone', 'Silvester', 'Rambo') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        start, tag1, timestamp = self.extract_tag(self.relay.to_xml(), 'OperatorRecords').partition('<PasswordLastModifiedTimestamp>')
        _, tag2, end = timestamp.partition('</PasswordLastModifiedTimestamp>')
        operator_no_timestamp = start + tag1 + tag2 + end
        self.assertEqual(
                '<OperatorRecords>'
                    '<record>'
                        '<ClockInPassword>0</ClockInPassword>'
                        '<FirstName>Silvester</FirstName>'
                        '<Handle>Rambo</Handle>'
                        '<OperatorExternalId/>'
                        '<LanguageId>1033</LanguageId>'
                        '<LastName>Stallone</LastName>'
                        '<MiddleInitial/>'
                        '<MSRNumber>0</MSRNumber>'
                        '<OperatorId>1</OperatorId>'
                        '<OperatorMode>2</OperatorMode>'
                        '<Password>2345</Password>'
                        '<PasswordLastModifiedTimestamp></PasswordLastModifiedTimestamp>'
                        '<JobCodes/>'
                    '</record>'
                '</OperatorRecords>',
                operator_no_timestamp)

    def test_create_job_description_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_job_description(123, 321, 'Test job')
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<JobDescriptionRecords>'
                    '<record>'
                        '<JobCode>123</JobCode>'
                        '<JobCodeFlags>321</JobCodeFlags>'
                        '<Description>Test job</Description>'
                    '</record>'
                '</JobDescriptionRecords>',
                self.extract_tag(self.relay.to_xml(), 'JobDescriptionRecords'))

    def test_create_security_group_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_security_group(111, 222, None, 'Manager')
        self.relay.create_security_group(222, 333, None, 'Cashier')
        self.relay.create_security_group(222, 333, 56789, 'Manager') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<SecurityGroupRecords>'
                    '<record>'
                        '<GroupId>111</GroupId>'
                        '<SecurityApplicationId>222</SecurityApplicationId>'
                        '<PermissionSet>1880092672</PermissionSet>'
                    '</record>'
                    '<record>'
                        '<GroupId>222</GroupId>'
                        '<SecurityApplicationId>333</SecurityApplicationId>'
                        '<PermissionSet>56789</PermissionSet>'
                    '</record>'
                '</SecurityGroupRecords>',
                self.extract_tag(self.relay.to_xml(), 'SecurityGroupRecords'))

    def test_create_security_group_assignment_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_security_group_assignment(11, 22)
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<OperatorSecurityGroupDefinitionRecs>'
                    '<record>'
                        '<OperatorId>11</OperatorId>'
                        '<SecurityGroupId>22</SecurityGroupId>'
                    '</record>'
                '</OperatorSecurityGroupDefinitionRecs>',
                self.extract_tag(self.relay.to_xml(), 'OperatorSecurityGroupDefinitionRecs'))

    def test_create_order_source_id_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_order_source_id_record(1, 22)
        self.relay.create_order_source_id_record(1) # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<OrderSourceIdRecords>'
                    '<record>'
                        '<OrderSourceId>1</OrderSourceId>'
                        '<OperatorId>70000000014</OperatorId>'
                    '</record>'
                '</OrderSourceIdRecords>',
                self.extract_tag(self.relay.to_xml(), 'OrderSourceIdRecords'))

    def test_find_order_source_id_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.assertIsNone(self.relay.find_order_source_id(2))
        self.relay.create_order_source_id_record(2)
        self.assertIsNotNone(self.relay.find_order_source_id(2))

if __name__ == '__main__':
    unittest.main()
