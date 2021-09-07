__all__ = [
    "RelayFile"
]

from typing import Any, Callable, Sequence, Tuple, Type, TypeVar, Union
import os
import bs4
import yattag
from . comparable_tag import ComparableTag
from . relay_file_performance import RelayFilePerformance

from .. bdd_utils.logging_utils import get_ev_logger, log_trace, wrap_all_methods_with_log_trace
from cfrpos.core.bdd_utils.errors import ProductError

_logger = get_ev_logger()
T = TypeVar("T", bound="RelayFile")


@wrap_all_methods_with_log_trace
class RelayFile:
    """
    Base class for relay file manipulation. This is only intended to be used
    for inheritance and type checking.
    """

    # Subclasses should override these.
    _pos_name = None
    _pos_reboot_required = False
    _filename = "NA"
    _default_description = "BDD;0.0.0.000;0"
    _default_version = 0
    _sort_rules = []  # type: Sequence[Tuple[str, Sequence[Tuple[str, Callable[[str], Any]]]]]

    def __init__(self, xml: Union[str, bs4.BeautifulSoup], pos_name: str, pos_reboot_required: bool):
        """
        :param xml: XML of the relay file.
        """
        self._pos_name = pos_name
        self._pos_reboot_required = pos_reboot_required
        self._last_applied_xml = None
        self._last_generated_xml = None
        self._dirty = None
        self._performance = RelayFilePerformance()
        with self._performance.initializing_config_data:
            if isinstance(xml, bs4.BeautifulSoup):
                self._soup = xml
            else:
                self._soup = bs4.BeautifulSoup(xml, "xml")
            self._initial_xml = self.to_xml()

    def _sort(self) -> None:
        """
        Mutate the XML representation to sort based on the `_sort_rules`.
        """
        sorted_sections = []
        for section_name, compared_fields in self._sort_rules:
            for section in self._soup.RelayFile.contents:
                if section.name != section_name \
                        or len(section.contents) == 0 \
                        or len(compared_fields) == 0:
                    continue
                section = section.extract()
                sorted_section = [ComparableTag(tag, compared_fields) for tag in section.contents if isinstance(tag, bs4.Tag)]
                sorted_section.sort()
                sorted_sections.append((section.name, sorted_section))
        for section_name, section_tags in sorted_sections:
            section = self._soup.new_tag(section_name)
            for tag in section_tags:
                section.append(tag.tag.extract())
            self._soup.RelayFile.append(section)

    @classmethod
    @log_trace
    def load(cls: Type[T], data_folder: str, prefer_file: bool = True) -> T:
        """
        Instantiate the class using either a blank template or a
        user-customizable file.

        :param str data_folder: The path to the folder with the default configuration files
        :param prefer_file: If true, try to load the user's custom override
            before loading the built-in empty template.
        :return: Class instance
        """

        if prefer_file:
            relay_file = os.path.join(data_folder, cls._filename)
            if os.path.isfile(relay_file):
                _logger.debug("Using relay file [{0}] from library directory.".format(cls._filename))
                with open(relay_file, encoding="utf-8") as file:
                    xml = bs4.BeautifulSoup(file.read(), "xml")
                    xml.RelayFile.FileHeader.Description.string = cls._default_description
                    return cls._create_instance(xml)
            else:
                _logger.debug("Defaulting to relay template since file [{0}] was not found.".format(relay_file))

        return cls._from_template()

    @classmethod
    @log_trace
    def _from_template(cls: Type[T]) -> T:
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("RelayFile"):
            with tag("FileHeader"):
                line("Description", cls._default_description)
                line("Version", cls._default_version)
            for section_name, _ in cls._sort_rules:
                with tag(section_name):
                    pass
        return cls._create_instance(doc.getvalue())

    @classmethod
    @log_trace
    def _create_instance(cls: Type[T], xml: str) -> T:
        return cls(xml, cls._pos_name, cls._pos_reboot_required)

    def mark_dirty(self) -> None:
        """
        Mark content as modified.
        """
        self._dirty = True
        self._last_generated_xml = None

    def reset(self) -> None:
        """
        Reset the XML representation to its initial state
        and clear the dirty status.
        """
        with self._performance.resetting_config_data:
            self._soup = bs4.BeautifulSoup(self._initial_xml, 'xml')
            self._dirty = None
            self._last_generated_xml = self._initial_xml

    def to_xml(self, pretty=False) -> str:
        """
        Convert the internal state to XML.

        :param pretty: If true, indent the output for human readability.
        :return: XML
        """

        if self._last_generated_xml is None:
            with self._performance.sorting_config_data:
                self._sort()
            with self._performance.serializing_config_data:
                if pretty:
                    self._last_generated_xml = self._soup.prettify()
                else:
                    self._last_generated_xml = str(self._soup)
        return self._last_generated_xml

    def _append_tag(self, location: bs4.Tag, new_tag: yattag.Doc) -> None:
        """
        Append a tag to an existing tag's content.

        :param location: Existing tag in which to append.
        :param new_tag: New tag to append.
        """
        with self._performance.updating_config_data_in_memory:
            location.append(bs4.BeautifulSoup(new_tag.getvalue(), "xml").find())
        self.mark_dirty()

    def _modify_tag(self, location: bs4.Tag, new_tag: yattag.Doc) -> None:
        """
        Modify a preexisting tag with updated content.
        :param location: Existing tag to be modified.
        :param new_tag: New tag to replace the original one.
        """
        with self._performance.updating_config_data_in_memory:
            location.replace_with(bs4.BeautifulSoup(new_tag.getvalue(), "xml").find())
            self.mark_dirty()

    def _remove_tag(self, location: bs4.Tag) -> None:
        """
        Remove a preexisting tag.
        :param location: Existing tag to be removed.
        """
        with self._performance.updating_config_data_in_memory:
            location.decompose()
            self.mark_dirty()

    def _find_tag(self, identifier_name: str, section_name: str=None, **find_args) -> bs4.Tag:
        """
        Returns the given unique element

        :param identifier_name: Name of the element which will be used for identification.
        :return: Found tag.
        """
        with self._performance.searching_config_data:
            search_root = self._soup.RelayFile if section_name is None else getattr(self._soup.RelayFile, section_name)
            match = search_root.find(identifier_name, **find_args)
            return match

    def _find_parent(self, relay_section: str, identifier_name: str, identifier: Union[str, int]) -> bs4.Tag:
        """
        Returns the parent tag of a given unique element

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections
        :param identifier_name: Name of the element which will be used for identification.
        :param identifier: Unique ID to identify a specific item.
        :return: Parent tag.
        """

        with self._performance.searching_config_data:
            match = getattr(self._soup.RelayFile, relay_section).find(identifier_name, string=str(identifier))
            return match.parent

    @property
    def pos_name(self) -> str:
        """
        POS name of the relay file.
        """

        if self._pos_name is None:
            raise ProductError("POS name not defined for type '{0}'.".format(type(self)))
        return self._pos_name

    def notify_applied(self) -> bool:
        """
        Notify the relay file was applied at the node.
        :return: bool True if reboot is required.
        """

        self._last_applied_xml = self.to_xml(False)
        self._dirty = False
        return self._pos_reboot_required

    @property
    def _was_update_applied(self) -> bool:
        with self._performance.checking_last_data_update:
            return self._last_applied_xml == self.to_xml(False)

    @property
    def update_required(self) -> bool:
        """
        True if update should be applied for this relay file.
        """

        update_required = True
        if self._last_applied_xml is None:
            update_required = True
        elif self._dirty is not None and not self._dirty:
            update_required = False
        elif self._was_update_applied:
            self._dirty = False
            update_required = False
        else:
            update_required = True
        return update_required

    @property
    def performance_stats(self) -> RelayFilePerformance:
        return self._performance

    def contains_id_in_section(self, relay_section: str, find_in: str, id: Union[str, int]) -> bool:
        """
        Check whether the relay file contains an ID.

        :param relay_section: This specifies the section of the relay to search, it is necessary because a relay file
        can reuse the same column names through multiple sections.
        :param find_in: column name of the IDS.
        :param id: ID to check.
        :return: Whether the given ID is present.
        """
        match = getattr(self._soup.RelayFile, relay_section).find(find_in, string=str(id))
        return match is not None
