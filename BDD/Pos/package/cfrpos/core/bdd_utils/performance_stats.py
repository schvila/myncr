__all__ = [
    "PerformanceCounter",
    "PerformanceStats"
]

import time

class PerfomanceCounter:
    def __init__(self):
        self._period_start = None
        self.total = 0
        self.count = 0

    def __enter__(self):
        self._period_start = time.perf_counter()
        return self

    def __exit__(self, type, value, tb):
        if tb is None:
            self.total = self.total + (time.perf_counter() - self._period_start)
            self.count = self.count + 1

    def add(self, other):
        if other is not None:
            self.total = self.total + other.total
            self.count = self.count + other.count

    @property
    def average(self):
        if self.count > 0:
            return self.total / self.count
        else:
            return 0

    def __str__(self):
        return '{:.3f} s ({:.3f} s / calls {})'.format(
            self.average,
            self.total,
            self.count)


class PerformanceStats:
    def __init__(self):
        self.reset()

    def reset(self):
        pass

    def add(self, other):
        for counter_name in dir(other):
            other_counter = getattr(other, counter_name)
            if isinstance(other_counter, PerfomanceCounter):
                counter = getattr(self, counter_name, None)
                if counter is None:
                    setattr(self, counter_name, other_counter)
                else:
                    counter.add(other_counter)

    def report(self):
        counters = {counter_name: getattr(self, counter_name) for counter_name in dir(self) if isinstance(getattr(self, counter_name), PerfomanceCounter)}
        print('Counters: {}'.format(len(counters)))
        for name, counter in counters.items():
            print('{}: {}'.format(name, counter))
        print()
