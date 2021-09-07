import unittest
from cfrpos.core.bdd_utils.timeouter import timeouter

global_counter = 0


# Helper function using the counter for the unit tests
def tester():
    global global_counter
    global_counter += 1

    if global_counter >= 10:
        return True
    else:
        return False


class TestComparers(unittest.TestCase):
    def test_pass_right_away(self):
        global global_counter
        global_counter = 100
        result = timeouter(tester, 2.0)
        self.assertTrue(result)
        self.assertEqual(global_counter, 101)

    def test_repeating(self):
        global global_counter
        global_counter = 5
        result = timeouter(tester, 2.0)
        self.assertTrue(result)
        self.assertEqual(global_counter, 10)

    def test_timeout(self):
        global global_counter
        global_counter = 0
        result = timeouter(tester, 1.0)
        self.assertFalse(result)
        self.assertGreater(global_counter, 3)

    def test_return_value(self):
        def generate_none_or_dict():
            generate_none_or_dict.counter += 1

            if generate_none_or_dict.counter < 3:
                return None
            else:
                return {'A': 'B'}

        generate_none_or_dict.counter = 0

        result = timeouter(generate_none_or_dict, 1.0)
        self.assertTrue(bool(result))
        self.assertEqual(result, {'A': 'B'})

    def test_expected_result(self):
        def inverted_tester():
            global global_counter
            global_counter += 1

            if global_counter >= 10:
                return False
            else:
                return True
                
        global_counter = 0
        result = timeouter(inverted_tester, 2.0, expected_result=False)
        self.assertEqual(result, False)

    def test_passed_arguments(self):
        def get_none_or_passed_argument(argument: str):
            get_none_or_passed_argument.counter += 1
            if get_none_or_passed_argument.counter < 3:
                return None
            else:
                return argument

        get_none_or_passed_argument.counter = 0
        result = timeouter(get_none_or_passed_argument, 1.0, 'Test')
        self.assertEqual(result, 'Test')

if __name__ == '__main__':
    unittest.main()