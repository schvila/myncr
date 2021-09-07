__all__ = [
    "POSAPINotificationRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class POSAPINotificationRelay(RelayFile):
    """
    Representation of the pos api notification relay file.
    """
    _pos_name = "POSAPINotification"
    _pos_reboot_required = True
    _filename = "POSAPINotification.xml"
    _default_version = 3
    _sort_rules = [
        ("POSAPINotification", [
            ("NotificationID", int),
            ("TerminalNode", int),
            ("NotificationURI", str),
            ("DeviceName", str),
        ]),
        ("POSAPINotificationTopic", [
             ("TopicNotificationID", int),
             ("NotificationID", int),
             ("TopicID", str)
         ])
    ]

    def create_notification_uri(self, notification_id: int, terminal_node: int, notification_uri: str, device_name: str) -> None:
        """
        Create new or update existing pos api notification record which provides notification uri on which message should be sent
        :param notification_id: unique id for configured controller
        :param terminal_node: Pos node on which end points are configured.
        :param notification_uri: Controller end points on which Pos should send the message
        :param device_name: device where the message will be sent by controller
        """
        section = "POSAPINotification"
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("NotificationID", notification_id)
            line("TerminalNode", terminal_node)
            line("NotificationURI", notification_uri)
            line("DeviceName", device_name)

        match_notification_id = getattr(self._soup.RelayFile, section).find('NotificationID', string = notification_id)
        if match_notification_id is not None:
            parent = self._find_parent(section, 'NotificationID', notification_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.find(section), doc)

        self.mark_dirty()

    def create_notification_topic(self, topic_notification_id: int, notification_id: int, topic_id: str):
        """
        Creates notificiation topic which will be part of payload sent to corresponding configured controller
        :param topic_notification_id: Distinct id to each topic configured for notification
        :param notification_id: Maps to controller for which different topics are added
        :param topic_id: topicid as part of payload tells controller what command to be sent on device
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("TopicNotificationID", topic_notification_id)
            line("NotificationID", notification_id)
            line("TopicID", topic_id)

        match_topic_id = getattr(self._soup.RelayFile, 'POSAPINotificationTopic').find('TopicNotificationID', string = topic_notification_id)
        if match_topic_id is not None:
            parent = self._find_parent('POSAPINotificationTopic', 'TopicNotificationID', topic_notification_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.POSAPINotificationTopic, doc)
