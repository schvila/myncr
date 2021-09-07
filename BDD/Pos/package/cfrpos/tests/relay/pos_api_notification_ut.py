import os
import unittest
import bs4
from typing import Union
from cfrpos.core.relay import POSAPINotificationRelay


class TestPOSAPINotificationRelay(unittest.TestCase):
    def setUp(self):
        self.relay = POSAPINotificationRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

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

    def test_create_notification_uri_record(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_notification_uri(1, 2, 'test uri', 'test device name')
        self.relay.create_notification_uri(1, 3, 'test uri2', 'test device name2') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<POSAPINotification>'
                    '<record>'
                        '<NotificationID>1</NotificationID>'
                        '<TerminalNode>3</TerminalNode>'
                        '<NotificationURI>test uri2</NotificationURI>'
                        '<DeviceName>test device name2</DeviceName>'
                    '</record>'
                '</POSAPINotification>',
                self.extract_tag(self.relay.to_xml(), 'POSAPINotification'))

    def test_create_notification_topic(self):
        '''
        Resulting XML is ordered ascending regardless whether new records were added.
        '''
        self.relay.create_notification_topic(1, 2, 'test topic')
        self.relay.create_notification_topic(1, 3, 'test topic 2') # This record should override the last one
        self.assertTrue(self.relay.update_required)
        self.assertEqual(
                '<POSAPINotificationTopic>'
                    '<record>'
                        '<TopicNotificationID>1</TopicNotificationID>'
                        '<NotificationID>3</NotificationID>'
                        '<TopicID>test topic 2</TopicID>'
                    '</record>'
                '</POSAPINotificationTopic>',
                self.extract_tag(self.relay.to_xml(), 'POSAPINotificationTopic'))

if __name__ == '__main__':
    unittest.main()
