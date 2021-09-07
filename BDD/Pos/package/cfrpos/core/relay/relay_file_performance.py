from cfrpos.core.bdd_utils.performance_stats import PerfomanceCounter, PerformanceStats

class RelayFilePerformance(PerformanceStats):
    def reset(self):
        self.searching_config_data = PerfomanceCounter()
        self.updating_config_data_in_memory = PerfomanceCounter()
        self.sorting_config_data = PerfomanceCounter()
        self.checking_last_data_update = PerfomanceCounter()
        self.serializing_config_data = PerfomanceCounter()
        self.initializing_config_data = PerfomanceCounter()
        self.resetting_config_data = PerfomanceCounter()
