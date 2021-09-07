__all__ = [
    "FuelDispenserRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile

@wrap_all_methods_with_log_trace
class FuelDispenserRelay(RelayFile):
    """
    Representation of the Fuel_Dispenser relay file.
    """
    _pos_name = "Fuel_Dispenser"
    _pos_reboot_required = True
    _filename = "Fuel_Dispenser.xml"
    _default_version = 6
    _sort_rules = [
        ("FuelingPointRecords", [
            ("FuelingPointNumber", int)
        ])
    ]

    def create_fueling_point_record(self, fueling_point: int, enabled: int = 1, default_tier: int = 1, service_mode: int = 1, volume_multiplier: int =1000,
                          price_per_multiplier: int = 1000, money_multiplier: int = 100, max_auth_amount: int = 20000, max_auth_volume: int = 20000,
                          non_integrated_pump: int = 0, pump_ppu_precision: int = 3, pump_money_precision: int = 2,
                          pump_volume_precision: int = 3, max_stack: int = 2, hose_count: int = 4, hose_records: str = '') -> None:
        """
        Allows to create or modify a pump.

        :param fueling_point: Fuel point number.
        :param enabled: It is 1 if enabled fuel point, 0 otherwise.
        :param default_tier: Default pricing tier.
        :param service_mode: Default servise mode.
        :param volume_multiplier: Volume multiplier.
        :param price_per_multiplier: Price per multiplier.
        :param money_multiplier: Money multiplier.
        :param max_auth_amount: Maximum amount that can be authenticated and depleted  by customer in one transaction.
        :param max_auth_volume: Maximum volume that can be authenticated and depleted by customer in one transaction.
        :param non_integrated_pump: It is 1 if pump is not integrated (manual), 0 if pump is integrated.
        :param pump_ppu_precision: Pump PPU precision.
        :param pump_money_precision: Pump money precision.
        :param pump_volume_precision: Pump volume precision.
        :param max_stack: The maximum number of untendered sales that can be done at pump, usually (1,2).
        :param hose_count: Number of pump hoses.
        :param hose_records: Pump hose records.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("FuelingPointNumber", fueling_point)
            line("Enabled", enabled)
            line("DefaultTier", default_tier)
            line("ServiceMode", service_mode)
            line("VolumeMultiplier", volume_multiplier)
            line("PricePerUnitMultiplier", price_per_multiplier)
            line("MoneyMultiplier", money_multiplier)
            line("MaxAuthAmount", max_auth_amount)
            line("MaxAuthVolume", max_auth_volume)
            line("NonIntegratedPump", non_integrated_pump)
            line("PumpPPUPrecision", pump_ppu_precision)
            line("PumpMoneyPrecision", pump_money_precision)
            line("PumpVolumePrecision", pump_volume_precision)
            line("MaxStack", max_stack)
            line("HoseCount", hose_count)
            line("HoseRecords", hose_records)

        if getattr(self._soup.RelayFile, 'FuelingPointRecords').find('FuelingPointNumber', string=fueling_point) is not None:
            parent = self._find_parent('FuelingPointRecords', 'FuelingPointNumber', fueling_point)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.FuelingPointRecords, doc)


    def create_hose_record(self, fueling_point: int, hose_number: int, product_number: int, primary_tank: int, enabled: int = 1,
                           secondary_tank: int = 0, blend_percentage: int = 100, tier_service_mode_price: str = '') -> None:
        """
        Allows to create or modify a hose. Each of the hoses contains product number defining fuel type.

        :param fueling_point: Fuel point number.
        :param hose_number: Hose number.
        :param enabled: It is 1 if enabled fuel point, 0 otherwise.
        :param product number: Hose product number.
        :param primary_tank: Primary tank number.
        :param secondary_tank: Secondary tank number.
        :param blend_percentage: Primary fuel grade percentage.
        :param tier_service_mode_price: Fuel price records.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("HoseNumber", hose_number)
            line("Enabled", enabled)
            line("ProductNumber", product_number)
            line("PrimaryTank", primary_tank)
            line("SecondaryTank", secondary_tank)
            line("PrimaryBlendPercentage", blend_percentage)
            line("TierServiceModePrices", tier_service_mode_price)


        match = getattr(self._soup.RelayFile, 'FuelingPointRecords').find('FuelingPointNumber', string=fueling_point).parent.find('HoseRecords')

        if match.find('HoseNumber', string=hose_number) is not None:
            parent = match.find('HoseNumber', string=hose_number).parent
            self._modify_tag(parent, doc)
        else:
            self._append_tag(match, doc)


    def create_tier_service_mode_prices(self, fueling_point: int, hose_number: int, unit_price: int) -> None:
        """
        Allows to create or modify prices of fuel.

        :param fueling_point: Fuel point number.
        :param hose_number: Hose number.
        :param unit_price: Fuel price.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("UnitPrice", unit_price)

        match_hoses = getattr(self._soup.RelayFile, 'FuelingPointRecords').find('FuelingPointNumber', string=fueling_point).parent.find('HoseRecords')
        match_prices = match_hoses.find("HoseNumber", string=hose_number).parent.find("TierServiceModePrices")

        if match_prices.find('UnitPrice', string=unit_price) is not None:
            parent = match_prices.find('UnitPrice', string=unit_price).parent
            self._modify_tag(parent, doc)
        else:
            self._append_tag(match_prices, doc)


    def is_pump_configured(self, fueling_point: int) -> bool:
        """
        Checks whether the pump is already configured and relay file contains fueling point number.

        :param fueling_point: Fuel point number.
        """
        match = getattr(self._soup.RelayFile, 'FuelingPointRecords').find('FuelingPointNumber', string=fueling_point)
        return match is not None