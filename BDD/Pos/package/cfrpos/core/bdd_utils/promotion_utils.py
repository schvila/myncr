import jmespath
import json
import itertools
from enum import Enum
from sim4cfrpos.api.nepsvcs_sim.nepsvcs_sim_control import PromotionsSim

class MessageComparator(Enum):
    EXACT_MATCH = 1
    ANY_VALUE = 2

class MessageAndElementsComparator:
    def __init__(self):
        pass

    def get_matching_message(self, elements: dict, messages: list) -> dict:
        for message in messages:
            if self.elements_in_message(elements, message):
                return message

    def elements_in_message(self, elements: dict, message: dict) -> bool:
        """
        Check whether a message contains elements
        :param elements: Required elements
        :param message: A message to compare

        :return: True, if the elements are in the message
        :rtype: bool
        """
        message_valid = True
        for element_path, value in elements.items():
            message_valid = self._compare_values(jmespath.search(element_path, message), value)
            if not message_valid:
                break

        return message_valid


    def report_message_was_not_found(self, messages: list, elements: dict):
        """
        Report that no message was found
        :param messages: Compared messages
        :param elements: Required elements
        """
        for index, message in enumerate(messages):
            for element_path, value in elements.items():
                if not self._compare_values(jmespath.search(element_path, message), value):
                    self._print_message(index, element_path, value, message)

    def _print_message(self, index: int, element_path: str, element_value: str, message: dict):
        pass

    def _compare_values(self, element_path: str, message: dict) -> bool:
        return False

class ExactValueComparator(MessageAndElementsComparator):
    def _compare_values(self, jsonValue: any, bddValue: str) -> bool:
        if str(jsonValue) == bddValue:
            return True
        try:
            if float(jsonValue) == float(bddValue):
                return True
        except (ValueError, TypeError):
            return False
        return False

    def _print_message(self, index: int, element_path: str, element_value: str, message: dict):
        print("message #{}, path: {}, {} != {}\r".format(index, element_path, str(jmespath.search(element_path, message)), element_value))

class AnyValueComparator(MessageAndElementsComparator):
    def _compare_values(self, jsonValue: any, bddValue: str) -> bool:
        return jsonValue != None

    def _print_message(self, index: int, element_path: str, element_value: str, message: dict):
        print("message #{}, path: {} does not exist".format(index, element_path))

class ComparatorFactory:
    @staticmethod
    def get_comparator(comparator_type: MessageComparator):
        if comparator_type == MessageComparator.EXACT_MATCH:
            return ExactValueComparator()
        elif comparator_type == MessageComparator.ANY_VALUE:
            return AnyValueComparator()
        else:
            return None

class HelperFunctions:
    @staticmethod
    def convert_action_type(action_type: str, promotions_sim: PromotionsSim):
        action_types: dict = {
            'GetPromotions': {
                PromotionsSim.PES: 'get',
                PromotionsSim.ULP: 'get'
            },
            'FinalizePromotions': {
                PromotionsSim.PES: 'sync-finalize',
                PromotionsSim.ULP: 'finalize'
            },
            'VoidPromotions': {
                PromotionsSim.PES: 'void',
                PromotionsSim.ULP: 'void'
            }
        }

        return action_types.get(action_type, {}).get(promotions_sim, action_type)

    @staticmethod
    def convert_status(status: str):
        statuses: dict = {
            'success': 'success',
            'offline': 'offline',
            'pending action': 'pending-action',
            'voided': 'voided',
            'missing credentials': 'missing-credentials',
            'process error': 'process-error'
        }

        return statuses.get(status, status)

    @staticmethod
    def elements_in_message(elements: dict, message: dict, message_comparator: MessageComparator) -> bool:
        """
        Check whether a message contains elements
        :param elements: Required elements
        :param message: A message to compare
        :param message_comparator: Any value of the MessageComparator enum

        :return: True, if the elements are in the message
        :rtype: bool
        """
        comparator = ComparatorFactory.get_comparator(message_comparator)

        return HelperFunctions.get_message(elements, [message], comparator) != None

    @staticmethod
    def get_message(elements: dict, messages: list, comparator) -> dict:
        """
        Find a message in a list of messages
        :param elements: Required elements
        :param messages: A message to compare
        :param comparator: An instance of a comparator

        :return: The first matching message
        :rtype: dict
        """
        if not comparator:
            return None

        message = comparator.get_matching_message(elements, messages)

        if message:
            return message

        # The message was not found, report it
        comparator.report_message_was_not_found(messages, elements)
        return None

    @staticmethod
    def check_pumps_ext_data(response: dict) -> bool:
        """Check response from fuel simulator containing external stored data from PES
        :param response: Response from fuel simulator
        :return: True if correct
        """
        sync_finalize = dict()
        try:
            data = response.get('Data', list())
            sync_finalize_string = ""
            for character in data:
                sync_finalize_string += chr(character)
            sync_finalize = json.loads(sync_finalize_string)
        except:
            return False
        if sync_finalize.get('sellingEngineNotifications', '') == '':
            return False
        return True

    @staticmethod
    def check_pumps_user_ids(response: dict, user_id: str) -> bool:
        """Check response from fuel simulator containing user credentials from PES saved during prepay transaction
        :param response: Response from fuel simulator
        :param user_id: Identifier to compare in the response data
        :return: True if correct
        """
        ids = dict()
        try:
            data = response.get('Data', list())
            ids_string = ""
            for character in data:
                if character != 0:
                    ids_string += chr(character)
            ids = json.loads(ids_string)
        except:
            return False
        if len(ids) >= 1:
            if ids[-1].get('identifier', '') == user_id:
                return True
        return False

    @staticmethod
    def _parse_codes(codes: str) -> list:
        """Parse string codes to list of lists
        '1, 2; 3; 4, 5' -> [['1', '2'], ['3'], ['4', '5']]
        :param codes: string with item or category codes
        :return: list of lists with integers
        """
        codes_without_spaces = codes.replace(' ', '')
        groups = codes_without_spaces.split(';')
        list_of_lists = []
        for group_codes in groups:
            codes = group_codes.split(',')
            list_of_codes = []
            for code in codes:
                list_of_codes.append(code)
            if len(list_of_codes) > 0:
                list_of_lists.append(list_of_codes)
        return list_of_lists

    @staticmethod
    def _process_codes(list_of_list: list) -> list:
        """ Flatten the list of lists, remove duplicates and sorts it
        ([['1', '2', '3'], '1', '2']) --> ['1', '2', '3']
        """
        flatten = itertools.chain.from_iterable(list_of_list)
        return sorted(set(flatten))

    @staticmethod
    def prepare_discounts(context_table_rows: list) -> dict:
        """ Prepare discounts from behave context table rows
        Use context.table with columns:
        * 'category_codes': comma or semicollon seperated values with category codes that are required in the transaction for the discount 
        * 'item_codes': comma or semicollon seperated values with item codes that are required in the transaction for the discount
        A semicollon separates group of items separated by a comma. 
        This specifies all possible combinations of items that will trigger the discount, examples:
        - 1; 2; 3 - Any item from 1, 2, 3 will trigger the discount
        - 1, 2, 3 - All items 1,2,3 must be in transaction to trigger the discount
        - 1; 2, 3 - Either item 1 or both items 2 and 3 will trigger the discount
        Note that for item discounts it will apply the discount for all the listed items 
        * 'discount_description'
        * 'discount_value'
        * 'discount_level'
        * 'promotion_id'

        :param Context_table_rows: list containing table rows from behave step
        :return: Dictionary with discounts to be passed to the nep simulator
        """
        types = {'item': 'basicItem', 'transaction': 'basicOrder'}
        approvals = {'cashier': 'CASHIER', 'consumer': 'CONSUMER', 'cashier_and_consumer': 'CASHIER_AND_CONSUMER'}
        discounts = []

        for row in context_table_rows:
            discount = {}
            if row.get('category_codes'):
                discount['requires_category_codes'] = HelperFunctions._parse_codes(row['category_codes'])
                discount['applies_to_category_codes'] = HelperFunctions._process_codes(discount['requires_category_codes'])
            if row.get('item_codes'):
                discount['requires_item_codes'] = HelperFunctions._parse_codes(row['item_codes'])
                discount['applies_to_item_codes'] = HelperFunctions._process_codes(discount['requires_item_codes'])
            discount['receipt_text'] = row.get('discount_description', '')
            discount['discount'] = row.get('discount_value')
            discount['type'] = types.get(row.get('discount_level'))
            discount['promotion_id'] = row.get('promotion_id')
            # Prompts
            discount['prompt_approval'] = approvals.get(row.get('prompt_approval', '').lower())
            discount['prompt_id'] = row.get('prompt_id')
            discount['prompt_type'] = row.get('prompt_type', 'BOOLEAN')
            discount['unit_type'] = row.get('unit_type', 'SIMPLE_QUANTITY')
            discount['reward_limit'] = row.get('reward_limit', 0)
            discount['is_apply_as_tender'] = row.get('is_apply_as_tender', 'False') == 'True'
            discount['timeout'] = int(row.get('timeout', 0))
            # Rewards
            discount['reward_approval_notification_for'] = approvals.get(row.get('approval_for', '').lower())
            discount['reward_approval_promotion_name'] = row.get('approval_name')
            discount['reward_approval_promotion_description'] = row.get('approval_description')
            discount['reward_approval_promotion_description_key'] = row.get('approval_description_key')

            assert discount.get('requires_category_codes') or discount.get('requires_item_codes'), 'Error, key is None'
            assert discount.get('applies_to_category_codes') or discount.get('applies_to_item_codes'), 'Error, key is None'
            assert discount['discount'], 'Error, key is None'
            assert discount['type'], 'Error, key is None'
            assert discount['promotion_id'], 'Error, key is None'
            if discount['is_apply_as_tender']:
                assert discount['type'] == types.get('transaction'), 'Error, loyalty tender must be a transaction discount'
            discounts.append(discount)

        return discounts

    @staticmethod
    def prepare_referenced_promotion(context_table_rows: list) -> dict:
        """ Prepare referenced promotion from behave context table rows
        Use context.table with columns:
        * 'promotion_id'
        * 'description'
        * 'locale': Default is 'en-us'
        * 'fuel_limit': Maximum volume of fuel that should be given the discount of type GALLON_US_LIQUID

        :param Context_table_rows: list containing table rows from behave step
        :return: Dictionary with discounts to be passed to the nep simulator
        """
        promotions = []

        for row in context_table_rows:
            promotion = {}
            promotion['promotionId'] = row.get('promotion_id')
            promotion['description'] = [ {"key": row.get('locale', 'en-us'), "value": row.get('description', '')} ]
            if row.get('fuel_limit', False):
                promotion['rewardLimit'] = row.get('fuel_limit')

            assert promotion['promotionId'], 'Error, key is None'

            promotions.append(promotion)

        return promotions
