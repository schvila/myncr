import time
from sim4cfrpos.api.nepsvcs_sim.nepsvcs_sim_control import NepSvcsSimControl, PromotionsSim
from .promotion_utils import *
from cfrpos.core.bdd_utils.timeouter import timeouter

class PesNepSimFacade():
    """Helper class for using the NepSvcsSimControl for PES simulation
    """
    simulator: NepSvcsSimControl

    def __init__(self, nep_services_simulator: NepSvcsSimControl):
        self.simulator = nep_services_simulator

    def wait_for_message_with_elements(self, action: str, comparator: MessageComparator, elements: dict, timeout: float) -> dict:
        """Waits for and returns message with given elements in the trapped messages from simulator.
        :param action: Action type, one of the results of HelperFunctions.convert_action_type()
        :param comparator: One of the MessageComparator, either exact match or any value
        :param elements: Dictionary of elements to search for
        :param timeout: Timeout for the wait, after elapsing method returns
        :return: Found message or None
        """
        comparator = ComparatorFactory.get_comparator(comparator)
        message = None
        def get_msg():
            messages = self.simulator.get_trapped_messages(action, PromotionsSim.PES)
            return HelperFunctions.get_message(elements, messages, comparator)

        message = timeouter(get_msg, timeout, result_comparator=lambda message: message is not None)

        return message

    def find_message_with_elements(self, action: str, comparator: MessageComparator, elements: dict) -> dict:
        """Finds and returns message with given elements in the trapped messages from simulator.
        :param action: Action type, one of the results of HelperFunctions.convert_action_type()
        :param comparator: One of the MessageComparator, either exact match or any value
        :param elements: Dictionary of elements to search for
        :return: Found message or None
        """
        messages = self.simulator.get_trapped_messages(action, PromotionsSim.PES)
        comparator = ComparatorFactory.get_comparator(comparator)
        message = HelperFunctions.get_message(elements, messages, comparator)

        return message

    def get_message_and_update(self, action: str, last_messages: dict) -> dict:
        """
        Returns message of given action.
        :param action: Action type, one of the results of HelperFunctions.convert_action_type()
        :param last_messages: Messages previously retrieved and saved from the simulator
        :return: Found message or None
        """
        message = None
        messages = self.simulator.get_trapped_messages(action, PromotionsSim.PES)
        if len(messages) > 0:
            message = messages[-1]
            if not self._check_last_messages(action, message, last_messages):
                last_messages.append({action: message})

        return message, last_messages

    def _check_last_messages(self, action: str, trapped_message: dict, last_messages: dict) -> bool:
        """
        Helper method to check if the request is already added to the list of the received requests.

        :param action: Action type, one of the results of HelperFunctions.convert_action_type()
        :param trapped_message: Last message retrieved on simulator
        :param last_messages: Messages previously retrieved and saved from the simulator
        """
        for message in last_messages:
            if action in message and message[action] == trapped_message:
                return True
        return False

    def find_message_with_elements_and_update(self, action: str, comparator: MessageComparator, last_messages: dict, elements: dict) -> dict:
        """
        Finds and returns message with given elements.
        :param action: Action type, one of the results of HelperFunctions.convert_action_type()
        :param comparator: One of the MessageComparator, either exact match or any value
        :param last_messages: Messages previously retrieved and saved from the simulator
        :param elements: Dictionary of elements to search for
        :return: Found message or None, updated list of received requests on PES
        """
        comparator = ComparatorFactory.get_comparator(comparator)
        # Introduced due to the delay of received requests.
        time.sleep(0.5)
        messages = self.simulator.get_trapped_messages(action, PromotionsSim.PES)
        message = HelperFunctions.get_message(elements, messages, comparator)

        if len(messages) > 0 and not self._check_last_messages(action, messages[-1], last_messages):
            last_messages.append({action: messages[-1]})
        return message, last_messages
