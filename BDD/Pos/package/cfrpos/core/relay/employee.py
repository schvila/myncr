__all__ = [
    "EmployeeRelay"
]

import yattag

from .. bdd_utils.logging_utils import wrap_all_methods_with_log_trace
from . import RelayFile


@wrap_all_methods_with_log_trace
class EmployeeRelay(RelayFile):
    """
    Representation of the employee relay file.
    """
    _pos_name = "employee"
    _filename = "Employee.xml"
    _default_version = 4
    _sort_rules = [
        ("EmployeeRecords", [
            ("EmployeeId", int)
        ])
    ]

    def contains_employee_id(self, employee_id: int) -> bool:
        """
        Check whether the relay file contains an employee ID.

        :param employee_id: ID to check.
        :return: Whether the ID is present.
        """
        match = self._soup.find("EmployeeId", string=str(employee_id))
        return match is not None

    def create_employee(
            self,
            employee_id: int,
            last_name: str,
            first_name: str,
            middle_initial: str = "",
            operator_mode: int = 2,
            operator_active: int = 1
    ) -> None:
        """
        Create an employee record.

        :param employee_id: Employee ID.
        :param last_name: Last name.
        :param first_name: First name.
        :param middle_initial: Middle initial.
        :param operator_mode: Operator mode.
        :param operator_active: Operator active.
        """
        doc, tag, text, line = yattag.Doc().ttl()
        with tag("record"):
            line("FirstName", first_name)
            line("LastName", last_name)
            line("MiddleInitial", middle_initial)
            line("EmployeeId", employee_id)
            line("OperatorMode", operator_mode)
            line("OperatorActive", operator_active)

        if self.contains_employee_id(employee_id):
            parent = self._find_parent('EmployeeRecords', 'EmployeeId', employee_id)
            self._modify_tag(parent, doc)
        else:
            self._append_tag(self._soup.RelayFile.EmployeeRecords, doc)
