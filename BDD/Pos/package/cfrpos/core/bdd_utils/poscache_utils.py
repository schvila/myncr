from .logging_utils import wrap_all_methods_with_log_trace
from cfrpos.core.bdd_utils.comparers import contains_dict_subset
import xml.etree.ElementTree as ET
from enum import Enum
from collections import defaultdict, OrderedDict

class PromptType(Enum):
    BOOLEAN = 1,
    NUMERIC = 2,
    FREETEXT = 3,
    MULTISELECT = 4

@wrap_all_methods_with_log_trace
class POSCacheUtils():
    """Contains only static methods for POSCache data parsing.
    Operates on a dictionary requested from simulator with POSCache data.

    Here is an example of such data:
{
    "Result": "Success",
    "requests": [
        [
            "DEVICEREQUEST",
            -300000001,
            0,
            {
                "smDEVICECMD": "CLOSELANE",
                "smDEVICETARGET": "PINPAD",
                ...
            }
        ],
        [
            ...
        ],
        ...
    ],
    "transactions": {
        "-300000001": {
            "id": -300000001,
            "message_id": 0,
            "nvps": {
                "smDEVICECMD": "CLOSELANE",
                "smDEVICETARGET": "PINPAD",
                ...
            }
        },
        "-300000002": {
            ...
        },
        ...
    }
}
    """
    @staticmethod
    def _get_transactions(poscache_data: dict) -> dict:
        """Returns transactions dictionary from POSCache data.
        """
        return poscache_data.get('transactions', {})

    @staticmethod
    def _get_requests(poscache_data: dict) -> dict:
        """Returns requests list from POSCache data.
        The list has tuples with four elements: (post_point, tran_id, message_id, NVPs) 
        """
        return poscache_data.get('requests', [('', 0, 0, {})])

    @staticmethod
    def _check_poscache_transactions_for_nvps(poscache_data: dict, nvps: dict) -> bool:
        """Checks that poscache received a transaction with given NVPs.
        """
        transactions = POSCacheUtils._get_transactions(poscache_data)
        not_found = contains_dict_subset(nvps, transactions)
        return not not_found

    @staticmethod
    def _find_picklist_xml(poscache_data: dict) -> str:
        """
        Gets picklist xml representation from the received poscache request from POS.

        :param poscache_data: Data from the POSCache, a dictionary containing received transactions and requests.
        """
        requests = POSCacheUtils._get_requests(poscache_data)
        for post_point,_,_,nvps in requests:
            if post_point == 'DEVICEREQUEST' and nvps.get('smDEVICECMD', '') == 'GETPICKLISTEX':
                return nvps.get('toPROMPT', '')
        return ''

    @staticmethod
    def get_displayed_items(poscache_data: dict) -> dict:
        """Returns a dictionary of items that are displayed on pinpad

        :param poscache_data: Data from the POSCache, a dictionary containing received transactions and requests.
        """
        transactions = POSCacheUtils._get_transactions(poscache_data)
        result = {}
        int_list = [int(i) for i in list(transactions.keys())]
        sorted_key_list = sorted(int_list, key=abs)
        for key in sorted_key_list:
            value = transactions.get(str(key))
            if (value.get('nvps').get('smDEVICECMD') == 'ADDDISPITEM') or (value.get('nvps').get('smDEVICECMD') == 'REMDISPITEM'):
                item_tag_list_number = value.get('nvps').get('toDISPITEMTAGLIST')
                disp_item = 'toDISPITEM' + item_tag_list_number
                if value.get('nvps').get('smDEVICECMD') == 'ADDDISPITEM':
                    full_desc = value.get('nvps').get(disp_item).split('\x1c', 1)[0].split('=', 1)[1]
                    result[item_tag_list_number] = full_desc
                elif value.get('nvps').get('smDEVICECMD') == 'REMDISPITEM':
                    del result[item_tag_list_number]
        return result
        
    
    @staticmethod
    def _parse_pick_list(picklist_root: ET.ElementTree) -> list:
        """
        Parse pick list from given request.

        :param list_data: String representation of the request containing pick list.
        """
        item_list = []
        picklist_elements = picklist_root.findall("PicklistItem")
        for element in picklist_elements:
            id = element.attrib['ID']
            program_name = element.attrib['Text']
            item_list.append((id, program_name))
        return item_list

    @staticmethod
    def was_loyalty_card_added(poscache_data: dict) -> bool:
        """Checks that poscache received a transaction with NVPs according to:
        https://confluence.ncr.com/display/epsilon/NVP+transaction+-+Device+DECODECOMPLETE
        """
        # Define the transaction with NVPs we are looking for
        transaction = {"nvps": {"smCARDCATEGORY": "L", "smDEVICECMD": "DECODECOMPLETE", "smDEVICETARGET": "PINPAD",
                               "smLOCATIONID": "*", "smTRANTYPE": "DEVICEREQUEST", "*": "*"}}

        return POSCacheUtils._check_poscache_transactions_for_nvps(poscache_data, transaction)

    @staticmethod
    def was_message_displayed(poscache_data: dict, message: str) -> bool:
        """Checks that poscache received the provided message set to be displayed by pinpad.
        """
        # Define the transaction with NVPs we are looking for
        transaction = {'nvps': {'scPROMPT': message, 'smDEVICECMD': 'DISPLAYMESSAGE',
                               'smDEVICETARGET': 'PINPAD', 'smLOCATIONID': 'POS1', 'smLOCATIONIDDEVICE': 'POS1',
                              'smTRANTYPE': 'DEVICEREQUEST', 'soFEPCOMMAND': 'DeviceDisplayMessage', '*': '*'}}
        return POSCacheUtils._check_poscache_transactions_for_nvps(poscache_data, transaction)

    @staticmethod
    def was_request_with_command_sent(poscache_data: dict, device_command: str) -> bool:
        """Checks that poscache received the provided request with specific smDEVICECMD from POS.
        :param poscache_data: Dictionary containing the poscache simulator data received from POS
        :param device_command: String containing the device command from POS
        :return: True if successfull, false if the command was not sent
        """
        requests = poscache_data['requests']
        for _,_,_,nvps in requests:
           if nvps.get('smDEVICECMD', None) == device_command:
               return True
        return False

    @staticmethod
    def was_prompt_request_sent(poscache_data: dict, prompt_type: PromptType, prompt_title: str = None, prompt_message: str = None) -> bool:
        PROMPT_CMDS = {
            PromptType.BOOLEAN: 'GETBOOLEAN',
            PromptType.NUMERIC: 'GETNUMERIC',
            PromptType.FREETEXT: 'GETFREETEXT',
            PromptType.MULTISELECT: 'GETMULTISELECT'
        }
        requests = poscache_data['requests']
        for _,_,_,nvps in requests:
            if nvps.get('smDEVICECMD', None) == PROMPT_CMDS[prompt_type]:
                if prompt_title is not None and nvps.get('scTITLE', None) != prompt_title:
                    continue
                if prompt_message is not None and nvps.get('scPROMPT', None) != prompt_message:
                    continue
                return True
        return False

    @staticmethod
    def was_picklist_sent(poscache_data: dict, text: str, items: list = None) -> bool:
        """Checks that poscache received a prompt request.
        :param poscache_data: Dictionary containing the poscache simulator data received from POS
        :param text: Text on prompt
        :param items: Items to select from in case of Picklist
        :return: True if successfull, false if the prompt was not sent
        """
        picklist_xml = POSCacheUtils._find_picklist_xml(poscache_data)
        if picklist_xml == '':
            return False
        
        picklist_root = ET.fromstring(picklist_xml)
        picklist = POSCacheUtils._parse_pick_list(picklist_root)
        
        if len(picklist) == len(items):
            for _,text in picklist:
                if not text in items:
                    break
            else:
                return True

        return False

    @staticmethod
    def get_pick_list(poscache_data: dict) -> list:
        """
        Get the pick list displayed on pinpad.
        """
        picklist_xml = POSCacheUtils._find_picklist_xml(poscache_data)
        if picklist_xml == '':
            return []
        picklist_root = ET.fromstring(picklist_xml)
        return POSCacheUtils._parse_pick_list(picklist_root)

    @staticmethod
    def find_program_id_in_picklist(program_name: str, picklist: list) -> int:
        """
        Find the ID of loyalty program with given name.

        :param program_name: Name of the loyalty program.
        :param picklist: Pick list to be checked if program with name is part of.
        """
        for element in picklist:
            if element[1] == program_name:
                return int(element[0])
        else:
            return None
