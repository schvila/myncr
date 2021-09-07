__all__ = [
    "PromotionsRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class PromotionsRelay(RelayFile):
    """
    Representation of the Promotions relay file.
    """
    _pos_name = "Promotions"
    _filename = "Promotions.xml"
    _default_version = 4
    _sort_rules = [
        ("Promotions", [
            ("ItemId", str)
        ])
    ]

    def create_promotion(self, item_id: int, modifier1_id: str, promotion_price: float, promotion_id: str, start_date: str = '1900-01-01T00:00:00', end_date: str = '2099-01-01T00:00:00') -> None:
        """
        Create or modify promotion record.

        :param item_id: Item ID.
        :param modifier1_id: The Modifier1 ID.
        :param start_date: Date when the promotion starts to usable.
        :param end_date: Date when promotion stops to be usable.
        :param promotion_price: Item price with applied promotion.
        :param promotion_id: Promotion ID.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ItemId", item_id)
            line("Modifier1Id", modifier1_id)
            line("PromotionStartTime", start_date)
            line("PromotionEndTime", end_date)
            line("PromotionPrice", promotion_price)
            line("PromotionId", promotion_id)

        match_combo_id = getattr(self._soup.RelayFile, 'Promotions').find('ItemId', string=item_id)
        if match_combo_id is not None:
            parent = self._find_parent('Promotions', 'ItemId', item_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.Promotions, doc)

    def get_new_promotion_id(self) -> int:
        """
        Generate a new promotion id for each new promotion record.
        """
        promotion_id = 10000000003
        while self.contains_id_in_section('Promotions', 'PromotionId', promotion_id):
            promotion_id = promotion_id + 1
        return promotion_id
