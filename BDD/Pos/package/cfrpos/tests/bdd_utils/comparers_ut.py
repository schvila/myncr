import unittest
import json
import copy
from cfrpos.core.bdd_utils.comparers import contains_dict_subset, relax_dict_subset


class TestComparers(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.TESTING_JSON = \
'''
{
    "TransactionData": {
        "ItemList": [
            {
                "Description": "Sale Item A",
                "ExtendedPriceAmount": 0.99,
                "ExternalId": "ITT-099999999990-0-1",
                "ItemNumber": 1,
                "POSItemId": 990000000002,
                "POSModifier1Id": 990000000007,
                "POSModifier2Id": 0,
                "POSModifier3Id": 0,
                "Quantity": 1,
                "Type": "Regular",
                "UnitPriceAmount": 0.99
            },
            {
                "Description": "Sale Item B",
                "ExtendedPriceAmount": 1.99,
                "ExternalId": "ITT-08888888880-0-1",
                "ItemNumber": 1,
                "POSItemId": 990000000003,
                "POSModifier1Id": 990000000007,
                "POSModifier2Id": 0,
                "POSModifier3Id": 0,
                "Quantity": 2,
                "Type": "Regular",
                "UnitPriceAmount": 1.99
            }
        ],
        "TransactionBalance": 1.06,
        "TransactionSubTotal": 2.99,
        "TransactionTaxAmount": 0.17,
        "TransactionTotal": 2.06,
        "List": [1, 2, 3]
    },
    "TransactionSequenceNumber": 54
}
'''
        cls.TESTING_DICT = json.loads(cls.TESTING_JSON)

    def test_compare_empty(self):
        not_found = contains_dict_subset({}, {})
        self.assertEqual(not_found, {})

        not_found = contains_dict_subset({}, {'a': 1})
        self.assertEqual(not_found, {})

    def test_compare_equal_or_subset(self):
        not_found = contains_dict_subset({'a': 1, 'b': {'ba': True}, 'c': 'ABC'},
                                         {'a': 1, 'b': {'ba': True}, 'c': 'ABC'})
        self.assertEqual(not_found, {})

        not_found = contains_dict_subset({'a': 1}, {'a': 1, 'b': {'ba': 1, 'bb': 2}, 'c': 3})
        self.assertEqual(not_found, {})

    def test_compare_asterisk(self):
        not_found = contains_dict_subset({'a': '*', 'b': '*', 'c': '*'},
                                         {'a': 1, 'b': {'ba': 1, 'bb': 2}, 'c': 'ABC'})
        self.assertEqual(not_found, {})

        not_found = contains_dict_subset({'a': '*', 'b': {'ba': '*', '*': '*'}, 'c': '*'},
                                         {'a': 1, 'b': {'ba': 1, 'bb': 2}, 'c': 'ABC'})
        self.assertEqual(not_found, {})

    def test_compare_missing_element(self):
        not_found = contains_dict_subset({'a': 1, 'b': {'ba': 1, 'bb': 2}}, {'a': 1, 'b': {'ba': 1}, 'c': 'ABC'})
        self.assertEqual({'b': {'ba': 1, 'bb': 2}}, not_found)

    def test_compare_value_mismatch(self):
        not_found = contains_dict_subset({'a': 1, 'b': {'ba': 1}}, {'a': 2, 'b': {'ba': 1}, 'c': 'ABC'})
        self.assertEqual({'a': 1}, not_found)

    def test_compare_type_mismatch(self):
        not_found = contains_dict_subset({'a': 1, 'b': {'ba': 1}}, {'a': 1, 'b': {'ba': '1'}, 'c': 'ABC'})
        self.assertEqual({'b': {'ba': 1}}, not_found)

    def test_compare_type_numbers(self):
        not_found = contains_dict_subset({'a': 1.00, 'b': 0.00, 'c': 0}, {'a': 1, 'b': 0, 'c': 0.00})
        self.assertEqual({}, not_found)

    def test_compare_json_big_value(self):
        subset = copy.deepcopy(self.TESTING_DICT)
        del subset['TransactionSequenceNumber']

        #print(json.dumps(self.TESTING_DICT, sort_keys=True, indent=4))
        #print(json.dumps(subset, sort_keys=True, indent=4))

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_big_value_fail(self):
        subset = copy.deepcopy(self.TESTING_DICT)
        del subset['TransactionSequenceNumber']
        del subset['TransactionData']['TransactionBalance']

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, subset)

    def test_compare_json_small_asterisk(self):
        subset = json.loads('{"TransactionSequenceNumber": "*"}')

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_big_value_asterisk(self):
        subset = copy.deepcopy(self.TESTING_DICT)
        del subset['TransactionSequenceNumber']
        del subset['TransactionData']['TransactionBalance']
        subset['TransactionData']['*'] = '*'

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_nested_value(self):
        subset = json.loads('{"Description": "Sale Item B"}')

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_nested_list(self):
        subset = json.loads('{"List": [1, 2, 3]}')

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_nested_list_fail(self):
        subset = json.loads('{"List": [2, 3]}')

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, subset)

    def test_compare_json_nested_list_asterisk_1(self):
        subset = json.loads('{"List": ["*", 2, 3]}')

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_nested_list_asterisk_2(self):
        subset = json.loads('{"List": [1, 2, 3, "*"]}')

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_nested_structure(self):
        subset = json.loads('''
{
    "TransactionData": {
        "ItemList": [
            {
                "Description": "Sale Item A",
                "*": "*"
            },
            "*"
        ],
        "*": "*"
    }
}
''')
        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})

    def test_compare_json_nested_structure_relax(self):
        subset = json.loads('''
{
    "TransactionData": {
        "ItemList": [
            {
                "Description": "Sale Item A"
            }
        ]
    }
}
''')

        result = json.loads('''
{
    "TransactionData": {
        "ItemList": [
            {
                "Description": "Sale Item A",
                "*": "*"
            },
            "*"
        ],
        "*": "*"
    }
}
''')
        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, subset)

        relax_dict_subset(subset)
        self.assertEqual(subset, result)

        not_found = contains_dict_subset(subset, self.TESTING_DICT)
        self.assertEqual(not_found, {})


if __name__ == '__main__':
    unittest.main()
