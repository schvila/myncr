__all__ = [
    "FuelPumpsRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from .. bdd_utils.errors import ProductError
from . import RelayFile

@wrap_all_methods_with_log_trace
class FuelPumpsRelay(RelayFile):
    """
    Representation of the FuelPumps relay file.
    """
    _pos_name = "FuelPumps"
    _pos_reboot_required = True
    _filename = "FuelPumps.xml"
    _default_version = 3
    _sort_rules = [
        ("TimeRecords", [
            ("FuelingPoint", int)
        ]),
        ("ConfigurationRecords", [
            ("FuelingPoint", int)
        ])
    ]

    def create_pump_time_record(self, fueling_point: int, day_of_week: int = 0, start_hour: int = 0, start_minute: int = 0, end_hour: int = 23,
                          end_minute: int = 59, mode_mask: int = 775) -> None:
        """
        Allows to assign pump configuration based on a day and time.

        :param fueling_point: Fuel point number.
        :param day_of_week: Day in week, can be (0-6), 0-Sunday, 1-Monday...
        :param start_hour: Start hour.
        :param start_minute: Start minute.
        :param end_hour: End hour.
        :param end_minute: End minute.
        :param mode_mask: Mode mask. Specifies the configuration a pump will be using.
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("FuelingPoint", fueling_point)
            line("DayOfWeek", day_of_week)
            line("StartHour", start_hour)
            line("StartMinute", start_minute)
            line("EndHour", end_hour)
            line("EndMinute", end_minute)
            line("ModeMask", mode_mask)

        if getattr(self._soup.RelayFile, 'TimeRecords').find('FuelingPoint', string=fueling_point) is not None:
            match_day = self._is_pump_configured_for_day(fueling_point, day_of_week)
            if match_day is not None:
                parent = match_day.parent
                self._modify_tag(parent, doc)
            else:
                self._append_tag(self._soup.RelayFile.TimeRecords, doc)
        else:
            self._append_tag(self._soup.RelayFile.TimeRecords, doc)


    def create_pump_week_time_records(self, fueling_point: int) -> None:
        """
        Allows to assign pump configuration based on a day and time, for a week long schedule.

        :param fueling_point: Fuel point number.
        """
        for day in range(0,7):
            self.create_pump_time_record(fueling_point=fueling_point, day_of_week=day)


    def _is_pump_configured_for_day(self, fueling_point: int, day_of_week: int):
        """
        Method to check if pump is already configured for given day of a week.

        :param fueling_point: Fuel point number.
        :param day_of_week: Day in week, can be (0-6), 0-Sunday, 1-Monday...
        """

        match_day = None
        if getattr(self._soup.RelayFile, 'TimeRecords').find('FuelingPoint', string=fueling_point) is not None:
            match_fuel_point = getattr(self._soup.RelayFile, 'TimeRecords').find_all('FuelingPoint', string=fueling_point)
            for el in match_fuel_point:
                if el.parent.find('DayOfWeek', string=day_of_week) is not None:
                    match_day = el.parent.find('DayOfWeek', string=day_of_week)
                    return match_day
        return match_day

    def create_pump_configuration_record(self, fueling_point: int, drive_off_seconds: int = 300, auto_auth_seconds: int = 1, max_auth_amount: int = 20000, max_auth_volume: int = 200000,
                          max_stuck: int = 2, manual_sale_type: int = 0, volume_per_liter: int = 0, nonintegrated_pump_flag: int = 0) -> None:
        """
        Allows to create or modify a pump configuration.

        :param fueling_point: Fuel point number.
        :param drive_off_seconds: Time delay in seconds after the pump is hung-up before alert is displayed to cashier that the transaction was not paid.
        :param auto_auth_seconds: Time delay after which the client can start fueling.
        :param max_auth_amount: Maximum amount that can be authenticated and depleted by a customer in one transaction.
        :param max_auth_volume: Maximum volume that can be authenticated and depleted by a customer in one transaction.
        :param max_stuck: The maximum number of untendered sales that can be done at pump, usually (1,2).
        :param manual_sale_type: 0- No manual sale, 1- Token, 2- Oil-Fuel, 3- Oil-Blended, 4-Volume
        :param volume_per_liter: Used only if manual_sale_type is set to token.
        :param nonintegrated_pump_flag: 1- if non integrated pump (manual), 0- integrated pump
        """

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("FuelingPoint", fueling_point)
            line("DriveOffSeconds", drive_off_seconds)
            line("AutoAuthSeconds", auto_auth_seconds)
            line("MaxAuthAmount", max_auth_amount)
            line("MaxAuthVolume", max_auth_volume)
            line("MaxStack", max_stuck)
            line("ManualSaleType", manual_sale_type)
            line("VolumePerLiter", volume_per_liter)
            line("NonIntegratedPumpFlag", nonintegrated_pump_flag)

        if getattr(self._soup.RelayFile, 'ConfigurationRecords').find('FuelingPoint', string=fueling_point) is not None:
            parent = self._find_parent('ConfigurationRecords', 'FuelingPoint', fueling_point)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.ConfigurationRecords, doc)

