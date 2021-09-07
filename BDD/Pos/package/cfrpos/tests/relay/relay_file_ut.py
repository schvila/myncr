import os
import unittest
import time
from cfrpos.core.relay import RelayFile


class Timer:
    def __init__(self):
        self.start = time.process_time()

    @property
    def duration(self):
        return time.process_time() - self.start


class MockRelayFile(RelayFile):
    _pos_name = "mockrelayfile"
    _pos_reboot_required = True
    _filename = "MockRelayFile.xml"
    _default_version = 2
    _sort_rules = [
        ("SomeRecs", [
            ("ItemNumber", int)
        ]),
        ("OtherRecs", [
            ("ItemNumber", int)
        ])
    ]

    def _find_group(self, group: str):
        root = self._soup.RelayFile
        for child in root.children:
            if child.name == group:
                return child
        return None

    def add_record(self, group: str, number: int, value: str):
        record_tag = self._soup.new_tag('record')

        tag = self._soup.new_tag('ItemNumber')
        tag.string = str(number)
        record_tag.append(tag)

        tag = self._soup.new_tag('ItemValue')
        tag.string = str(value)
        record_tag.append(tag)

        self._find_group(group).append(record_tag)

        self.mark_dirty()


class TestRelayFile(unittest.TestCase):
    def setUp(self):
        self.relay_file = MockRelayFile.load(None, False)
        self.relay_file_initial_xml = '<?xml version="1.0" encoding="utf-8"?>\n' \
                '<RelayFile><FileHeader><Description>BDD;0.0.0.000;0</Description><Version>2</Version></FileHeader><SomeRecs/><OtherRecs/></RelayFile>'
        self.max_items = 2000
        for i in range(self.max_items):
            self.relay_file.add_record('SomeRecs', i + 1, 'some-{}'.format(i))

        for i in range(self.max_items):
            self.relay_file.add_record('OtherRecs', self.max_items - i, 'other-{}'.format(i))

    def tearDown(self):
        del self.relay_file

    def test_to_xml(self):
        timing = Timer()
        self.assertNotEqual('', self.relay_file.to_xml())
        print('to_xml(): {} s'.format(timing.duration))

    def test_sort(self):
        timing = Timer()
        self.relay_file._sort()
        print('_sort(): {} s'.format(timing.duration))

        records = self.relay_file._soup.RelayFile.SomeRecs
        self.assertEqual(self.max_items, len(records))
        last_number = None
        for record in records.children:
            current_number = int(record.ItemNumber.string)
            if last_number is None:
                last_number = current_number
            else:
                self.assertLessEqual(last_number, current_number)

        records = self.relay_file._soup.RelayFile.OtherRecs
        self.assertEqual(self.max_items, len(records))
        last_number = None
        for record in records.children:
            current_number = int(record.ItemNumber.string)
            if last_number is None:
                last_number = current_number
            else:
                self.assertLessEqual(last_number, current_number)

    def test_notify_applied_single(self):
        timing = Timer()
        self.assertTrue(self.relay_file.update_required)
        print('update_required(): {} s'.format(timing.duration))

    def test_notify_applied(self):
        timing = Timer()
        self.assertTrue(self.relay_file.update_required)

        self.assertNotEqual('', self.relay_file.to_xml())
        self.assertTrue(self.relay_file.update_required)

        self.relay_file.notify_applied()
        self.assertFalse(self.relay_file.update_required)
        print('multiple notify_applied(): {} s'.format(timing.duration))

    def test_reset(self):
        self.relay_file.notify_applied()
        self.assertNotEqual(self.relay_file_initial_xml, self.relay_file.to_xml())

        timing = Timer()
        self.relay_file.reset()
        print('reset(): {} s'.format(timing.duration))

        self.assertTrue(self.relay_file.update_required)
        self.assertEqual(self.relay_file_initial_xml, self.relay_file.to_xml())


if __name__ == '__main__':
    unittest.main()
