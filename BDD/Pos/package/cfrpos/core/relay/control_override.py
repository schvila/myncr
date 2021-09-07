__all__ = [
    "ControlOverrideRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile
from . import ControlRelay


@wrap_all_methods_with_log_trace
class ControlOverrideRelay(ControlRelay):
    """
    Representation of the control override relay file.
    """
    _pos_name = "controloverride"
    _filename = "ControlOverride.xml"

    def find_parameter_rec(self, parameter: int):
        """
        Checks if a record with given POS parameter exists.
        :param parameter: POS parameter number to be checked if set in record.
        """
        match = getattr(self._soup.RelayFile, 'ParameterRecs').find('Id', string=str(parameter))
        return match

    def delete_parameter_rec(self, parameter: int):
        """
        Deletes a Parameter record if exists.
        :param parameter: POS parameter number to be checked if set in record.
        """
        if self.find_parameter_rec(parameter) is not None:
            parent = self._find_parent('ParameterRecs', 'Id', parameter)
            self._remove_tag(parent)
        else:
            pass

    def set_parameter(self, parameter: int, value: str) -> None:
        """
        Create or update a parameter.

        :param parameter: Parameter to change.
        :param value: Value to set.
        """

        section = "ParameterRecs"
        existing_tag = self._soup.find(section).find(
            lambda elem:
            elem.name == "record" and
            elem.Id.text == str(parameter)
        )

        if existing_tag:
            if existing_tag.Value.text == value:
                # No change needed
                return
            else:
                existing_tag.Value.string.replace_with(value)
        else:
            doc, tag, text, line = yattag.Doc().ttl()
            with tag("record"):
                line("Id", parameter)
                line("Value", value)
            self._append_tag(self._soup.find(section), doc)

        self.mark_dirty()