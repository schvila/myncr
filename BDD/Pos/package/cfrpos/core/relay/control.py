__all__ = [
    "ControlRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class ControlRelay(RelayFile):
    """
    Representation of the control relay file.
    """
    _pos_name = "control"
    _pos_reboot_required = True
    _filename = "Control.xml"
    _default_version = 5
    _sort_rules = [
        ("ControlRecs", [
            ("Id", int)
        ]),
        ("ParameterRecs", [
            ("Id", int)
        ])
    ]

    def set_option(self, option: int, value: int) -> None:
        """
        Create or update a control option.

        :param option: Option to change.
        :param value: Value to set.
        """

        section = "ControlRecs"
        existing_tag = self._soup.find(section).find(
            lambda elem:
            elem.name == "record" and
            elem.Id.text == str(option) and
            elem.Node.text == "0"
        )

        if existing_tag:
            if existing_tag.Value.text == str(value):
                # No change needed
                return
            else:
                existing_tag.Value.string.replace_with(str(value))
        else:
            doc, tag, text, line = yattag.Doc().ttl()
            with tag("record"):
                line("Id", option)
                line("Node", 0)
                line("Value", value)
            self._append_tag(self._soup.find(section), doc)

        self.mark_dirty()

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
