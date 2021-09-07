__all__ = [
    "DevSetRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.errors import ProductError
from . import RelayFile

@wrap_all_methods_with_log_trace
class DevSetRelay(RelayFile):
    """
    Representation of the DevSet relay file.
    """
    _pos_name = "DevSet"
    _pos_reboot_required = True
    _filename = "DevSet.xml"
    _default_version = 4
    _sort_rules = [
        ("SetupRecords", [
            ("Device_Name", str)
        ])
    ]

    def create_device_record(self, device_type: str, logical_name: str, device_name: str, port_name: str, data_info: int, station_number: int = 1,
                      parameters: int = 'None', location: str = 'Local') -> None:
        """
        Allows to create a new record in DevSet relay file.

        :param station_number: Station number.
        :param device_type: Device type.
        :param parameters: Number of parameters.
        :param logical_name: Logical name.
        :param device_name: Device name.
        :param port_name: Port name.
        :param data_info: Data info.
        :param location: Location, can be (Local, Primary, Virtual).
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("Station_Number", station_number)
            line("Device_Type", device_type)
            line("Parameters", parameters)
            line("Logical_Name", logical_name)
            line("Device_Name", device_name)
            line("Port_Name", port_name)
            line("DataInfo", data_info)
            line("Location", location)

        if not self.is_device_present(logical_name=logical_name, data_info=data_info):
            self._append_tag(self._soup.RelayFile.SetupRecords, doc)

    def is_device_present(self, logical_name: str, data_info: str) -> bool:
        """
        Allows checking if device with given logical name and data info is already included in relay file.

        :param logical_name: Logical name of the device to be checked if exists in relay file
        :param data_info: Data info of the device. Will be used if device with logical name exists in relay file
        """
        nodes = getattr(self._soup.RelayFile, 'SetupRecords').find_all('Logical_Name', string=logical_name)
        for node in nodes or []:
            if node.parent.find('DataInfo', string=data_info) is not None:
                return True
        return False

    def is_device_record_added(self, device_name: str) -> bool:
        """
        Allows checking if record is already included in relay file.

        :param device_name: Device name of the record to be checked if exists in relay file.
        """
        match_device_type = getattr(self._soup.RelayFile, 'SetupRecords').find('Device_Name', string=device_name)
        if match_device_type is not None:
            return True
        else:
            return False