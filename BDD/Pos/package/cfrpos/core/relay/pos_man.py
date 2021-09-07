__all__ = [
    "POSManRelay",
    "OperatorSecurityRights"
]

import datetime as dt
import yattag

from typing import Sequence
from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from cfrpos.core.bdd_utils.errors import ProductError
from . import RelayFile
from enum import Enum


class OperatorSecurityRights(Enum):
    CASHIER = 0x00000000
    MANAGER = 0x700FF000

@wrap_all_methods_with_log_trace
class POSManRelay(RelayFile):
    """
    Representation of the POSMan relay file.
    """
    _pos_name = "posman"
    _filename = "PosMan.xml"
    _default_version = 15
    _sort_rules = [
        ("OperatorRecords", [
            ("OperatorId", int)
        ]),
        ("JobDescriptionRecords", []),
        ("SecurityGroupRecords", [
            ("GroupId", int)
        ]),
        ("SecurityExceptionRecords", [
            ("OperatorId", int)
        ]),
        ("SecurityMappings", [
            ("SecurityApplicationId", int)
        ]),
        ("UserSettingListRecs", [
            ("OperatorId", int),
            ("UserSettingId", int)
        ]),
        ("UserSettingRecs", []),
        ("OperatorSecurityGroupDefinitionRecs", [
            ("OperatorId", int)
        ]),
        ("OrderSourceIdRecords", [
            ("OrderSourceId", str)
        ]),
        ("EndOfFileNumber", [])
    ]

    def contains_job_code(self, job_code: int) -> bool:
        """
        Check whether the relay file contains a job code.

        :param job_code: Job code to check.
        :return: Whether the job code is present.
        """
        match = self._soup.find("JobCode", string=str(job_code))
        return match is not None

    def contains_operator_password(self, password: int) -> bool:
        """
        Check if there is a matching operator.

        :param password: Password to match.
        :return: Whether such an operator exists.
        """
        match = self._soup.find("Password", string=str(password))
        return match is not None

    def contains_operator_id(self, operator_id: int) -> bool:
        """
        Check if there is a matching operator.

        :param operator_id: Operator ID to match.
        :return: Whether such an operator exists.
        """
        match = self._soup.find("OperatorId", string=str(operator_id))
        return match is not None

    def get_operators_id(self, password: int) -> int:
        """
        Translate operator's pin into his ID

        :param int password: The password of the searched operator
        :return: The id the operator with the given password. -1 if operator does not exist.
        """
        password_element = getattr(self._soup.RelayFile, 'OperatorRecords').find("Password", string=str(password))
        try:
            return int(password_element.parent.OperatorId.text)
        except Exception:
            return -1

    def get_operators_pin(self, operator_id: int) -> int:
        """
        Translate operator's ID into his pin

        :param operator_id: The ID of the searched operator
        :return: The pin of the operator with the given ID. -1 if operator does not exist.
        """
        pin_element = getattr(self._soup.RelayFile, 'OperatorRecords').find("OperatorId", string=str(operator_id))
        try:
            return int(pin_element.parent.Password.text)
        except Exception:
            return -1

    def contains_security_group(self, security_group_id: int) -> bool:
        """
        Check if there is a matching security group.

        :param security_group_id: Security group ID to match.
        :return: Whether such a security group exists.
        """
        match = self._soup.find("SecurityGroupRecords").find("GroupId", string=str(security_group_id))
        return match is not None

    def create_operator(
            self,
            operator_id: int,
            password: int,
            last_name: str,
            first_name: str,
            handle: str,
            external_id: str = "",
            clockin_password: int = 0,
            middle_initial: str = "",
            operator_mode: int = 2,
            language_id: int = 1033,
            msr_number: int = 0,
            job_codes: Sequence[int] = tuple()
    ) -> None:
        """
        Create or modify an operator record.

        :param operator_id: Operator ID.
        :param password: Password.
        :param last_name: Last name.
        :param first_name: First name.
        :param handle: Handle.
        :param external_id: External ID of operator.
        :param clockin_password: Clock-in password.
        :param middle_initial: Middle initial.
        :param operator_mode: Operator mode.
        :param language_id: Language ID.
        :param msr_number: MSR number.
        :param job_codes: Job codes.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("ClockInPassword", clockin_password)
            line("FirstName", first_name)
            line("Handle", handle)
            line("OperatorExternalId", external_id)
            line("LanguageId", language_id)
            line("LastName", last_name)
            line("MiddleInitial", middle_initial)
            line("MSRNumber", msr_number)
            line("OperatorId", operator_id)
            line("OperatorMode", operator_mode)
            line("Password", password)
            line("PasswordLastModifiedTimestamp", dt.datetime.now().isoformat()[:-3])
            with tag("JobCodes"):
                for code in job_codes:
                    with tag("record"):
                        line("JobCode", code)

        if self.contains_operator_id(operator_id):
            parent = self._find_parent('OperatorRecords', 'OperatorId', operator_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.OperatorRecords, doc)

    def create_job_description(self, job_code: int, job_code_flags: int, description: str) -> None:
        """
        Create job description record.

        :param job_code: Job code.
        :param job_code_flags: Job coed flags.
        :param description: Description.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("JobCode", job_code)
            line("JobCodeFlags", job_code_flags)
            line("Description", description)

        self._append_tag(self._soup.RelayFile.JobDescriptionRecords, doc)

    def create_security_group(self, group_id: int, security_application_id: int, permission_set: int = None, operator: str = 'Cashier') -> None:
        """
        Create or modify security group record.

        :param group_id: Group ID.
        :param security_application_id: Security application ID.
        :param permission_set: Permission set.
        :param operator: Operator role, cashier/manager.
        """
        if permission_set is None:
            if operator.upper() == 'CASHIER':
                permission_set = OperatorSecurityRights.CASHIER.value
            elif operator.upper() == 'MANAGER':
                permission_set = OperatorSecurityRights.MANAGER.value
            else:
                raise ProductError("Incorrect operator name is provided.")

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("GroupId", group_id)
            line("SecurityApplicationId", security_application_id)
            line("PermissionSet", permission_set)

        match_security_id = getattr(self._soup.RelayFile, 'SecurityGroupRecords').find_all("SecurityApplicationId", string=str(security_application_id))
        for el in match_security_id:
            if el.parent.find("GroupId").string == str(group_id):
                parent = el.parent
                self._modify_tag(parent, doc)
                break
        else:
            self._append_tag(self._soup.RelayFile.SecurityGroupRecords, doc)

    def create_security_group_assignment(self, operator_id: int, security_group_id: int) -> None:
        """
        Create security group assigment record.

        :param operator_id: Operator ID.
        :param security_group_id: Security group ID.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("OperatorId", operator_id)
            line("SecurityGroupId", security_group_id)

        self._append_tag(self._soup.RelayFile.OperatorSecurityGroupDefinitionRecs, doc)

    def create_order_source_id_record(self, order_source_id: str, operator_id: int = 70000000014) -> None:
        """
        Creates or modifies an Order source id record.
        order_source_id: Order source ID.
        operator_id: Operator ID.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("OrderSourceId", order_source_id)
            line("OperatorId", operator_id)

        match = self._soup.find("OrderSourceId", string=order_source_id)
        if match is not None:
            parent = self._find_parent('OrderSourceIdRecords', "OrderSourceId", order_source_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.OrderSourceIdRecords, doc)

    def find_order_source_id(self, order_source_id: str):
        """
        Finds an Order source id record containing given order_source_id.
        order_source_id: Order source ID.
        """
        if order_source_id is None:
            return None

        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("OrderSourceId", order_source_id)

        match = self._soup.find("OrderSourceId", string=order_source_id)
        return match