from cfrpos.core.bdd_utils.errors import ProductError
from typing import Type, Union, List
import bs4


class ComparableTag:
    """
    Tag which allows sorting based on subsect of elements.
    """
    def __init__(self, tag: Type[bs4.Tag], compare_fields: List):
        self.tag = tag
        self.compare_key = [converter(self._find_child(tag, field).text) for field, converter in compare_fields]

    def _find_child(self, tag: Type[bs4.Tag], name: str) -> Union[None, Type[bs4.Tag]]:
        for tag_child in tag.contents:
            if tag_child.name == name:
                return tag_child
        raise ProductError('Element [{}] not found in tag [{}]. This could indicate corruted format.'.format(
                name,
                tag))

    def __lt__(self, other: Union[None, Type['ComparableTag']]):
        return other is not None \
                and isinstance(other, ComparableTag) \
                and self.compare_key < other.compare_key
