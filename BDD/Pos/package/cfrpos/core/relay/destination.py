__all__ = [
    "DestinationRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class DestinationRelay(RelayFile):
    """
    Representation of the destination relay file.
    """
    _pos_name = "Destintn"
    _pos_reboot_required = False
    _filename = "Destintn.xml"
    _default_version = 6
    _sort_rules = [
        ("DestRecs", [
            ("DestinationId", int),
            ("DeviceListId", int),
            ("Description", str),
            ("KDSDestID", int)
        ]),
        ("DestinationExternalIds", [
            ("DestinationId", int),
            ("ExternalId", int)
        ])
    ]

    def create_destination(
                self,
                destination_id: int,
                device_list_id: int,
                description: str,
                kds_dest_id: int,
                required_security: int = 0,
                external_id: int = None
        ) -> int:
            """
            Create or modify a destination record.

            :param int destination_id: Destination ID of created or modified destination.
            :param int device_list_id: .
            :param str description: Name of the destination (e.g. Default Destination, POS Terminal, CSS Inside).
            :param int kds_dest_id: Probably allows mock destination display on KPS, in relay file from real system this field equals destination_id.
            :param int required_security: Security mask; for POS-like devices (POS_Terminal, EatIn, CSS) 0.
            :param int external_id: Destination external ID, usually equals to destination_id.
            :return int: Destination ID of created or modified destination.
            """
            doc, tag, text, line = yattag.Doc().ttl()
            with tag("record"):
                line("DestinationId", destination_id)
                line("DescriptionId", 0)
                line("RequiredSecurity", required_security)
                line("DeviceListId", device_list_id)
                line("DeviceControl", 0)
                line("Description", description)
                line("KDSDestID", kds_dest_id)

            if self.contains_destination_id_in_section('DestRecs', destination_id):
                parent = self._find_parent('DestRecs', 'DestinationId', destination_id)
                self._modify_tag(parent, doc)
            else:
                self._append_tag(self._soup.RelayFile.DestRecs, doc)

            self.create_destination_ext_id(destination_id, external_id)

            return destination_id


    def create_destination_ext_id(
                self,
                destination_id: int,
                external_id: int=None
        ) -> None:
            """
            Create or modify a destination external ID.

            :param int destination_id: Destination ID.
            :param int external_id: Destination external ID.
            """
            doc, tag, text, line = yattag.Doc().ttl()
            with tag("record"):
                line("DestinationId", destination_id)
                line("ExternalId", external_id)

            if self.contains_destination_id_in_section('DestinationExternalIds', destination_id):
                parent = self._find_parent('DestinationExternalIds', 'DestinationId', destination_id)
                self._modify_tag(parent, doc)
            else:
                self._append_tag(self._soup.RelayFile.DestinationExternalIds, doc)


    def contains_destination_id(self, destination_id: int) -> bool:
            """
            Check whether the relay file contains a destination ID.

            :param int destination_id: Destination ID to check.
            :return bool: Whether the destination ID is preseent.
            """

            matches = self._soup.find_all("DestinationId", string=str(destination_id))
            return len(matches) > 0


    def contains_destination_id_in_section(self, relay_section: str, destination_id: int) -> bool:
        """
        Check whether the relay file contains a destination ID in a given section.

        :param str relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param int destination_id: ID to check.
        :return bool: Whether the ID is present.
        """
        match = getattr(self._soup.RelayFile, relay_section).find("DestinationId", string=str(destination_id))
        return match is not None
