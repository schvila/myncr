__all__ = [
    "DllRelay"
]

import re
import yattag
from typing import List
from cfrpos.core.bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile
from . invariant_ascii_string import InvariantAsciiString
from cfrpos.core.bdd_utils.errors import ProductError

@wrap_all_methods_with_log_trace
class DllRelay(RelayFile):
    """
    Representation of the dll relay file.
    """
    _pos_name = "dll"
    _pos_reboot_required = True
    _filename = "dll.xml"
    _default_version = 3
    _sort_rules = [
        ("DLLs", [
            ("Name", InvariantAsciiString)
        ])
    ]

    _features = {
        'loyalty': [ 'EpsilonClient.dll', 'POSSigmaClient.dll', 'GCMClient.dll' ],
        'posapiserver': [ 'PosAPI.dll', 'PosAPIServer.dll' ],
        'pes': [ 'PesClient.dll' ],
        }

    def _find_dll_tag(self, dll):
        return self._soup.RelayFile.DLLs.find('Name', string=re.compile(dll, re.IGNORECASE))

    def _get_required_dlls(self, feature):
        if feature is not None and feature.lower() in self._features:
            return self._features[feature.lower()]
        else:
            return None

    def enable_feature(self, feature: str) -> None:
        """
        Enable a feature.
        :param feature: Feature name.
        """
        required_dlls = self._get_required_dlls(feature)
        if required_dlls is None:
            raise ProductError('Feature [{}] not found.'.format(feature))
        missing_dlls = [dll for dll in required_dlls if self._find_dll_tag(dll) is None]
        if len(missing_dlls) > 0:
            for dll in missing_dlls:
                name_tag = self._soup.new_tag('Name')
                name_tag.string = dll
                record_tag = self._soup.new_tag('record')
                record_tag.append(name_tag)
                self._soup.RelayFile.DLLs.append(record_tag)
            self.mark_dirty()

    def disable_feature(self, feature: str) -> None:
        """
        Disable a feature.
        :param feature: Feature name.
        """
        required_dlls = self._get_required_dlls(feature)
        if required_dlls is None:
            raise ProductError('Feature [{}] not found.'.format(feature))
        extra_dlls = [self._find_dll_tag(dll) for dll in required_dlls]
        if len(extra_dlls) > 0:
            for dll in extra_dlls:
                if dll is not None:
                    dll.parent.decompose()
            self.mark_dirty()

    def get_dlls(self) -> List[str]:
        """
        Get all DLLs which are being listed.
        :return: List of DLLs.
        """
        dlls = []
        for dll in self._soup.RelayFile.DLLs.find_all('Name'):
            dlls.append(dll.string)
        dlls.sort(key=lambda dll: dll.lower())
        return dlls

    def modify_dll_tag(self, old_dll: str, new_dll: str) -> None:
        """
        Modify dll tag. E.g. this method will be used to modify dll tags needed for switching to Shell Vantage mode.

        :param old_dll: Old dll that is going to be replaced.
        :param new_dll: New dll that is going to be used.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("Name", new_dll)

        if not self._find_dll_tag(old_dll) and not self._find_dll_tag(new_dll):
            raise ProductError("Wrong dll files are provided.")

        if self._find_dll_tag(old_dll):
            parent = self._find_parent('DLLs', 'Name', old_dll)
            self._modify_tag(parent, doc)