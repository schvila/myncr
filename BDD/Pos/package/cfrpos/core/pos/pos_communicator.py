__all__ = [
    "POSCommunicator"
]

from typing import Union, Optional
from .. bdd_utils.http_communicator import HTTPCommunicator
from .. bdd_utils.logging_utils import get_ev_logger, wrap_all_methods_with_log_trace
from .. import relay as relay_mod

logger = get_ev_logger()


@wrap_all_methods_with_log_trace
class POSCommunicator(HTTPCommunicator):
    """
    This class is the communication layer between EVCore and the POS product.
    """

    def __init__(self, hostname: str, port: int = None):
        """
        :param hostname: Hostname without protocol
        :param port: Port number
        """

        super().__init__(hostname, port)
        self.base_url = self._expand_url("v1/posengine")

    def get_state(self, timeout: Union[float, None] = 15) -> dict:
        """
        Get state.
        :param timeout: Timeout in seconds.
        :return: Response to this request
        """
        return self.get("state", timeout=timeout)

    def get_operator(self, timeout: Union[float, None] = 15) -> dict:
        """
        Get the current operator.
        :param timeout: Timeout in seconds.
        :return: Response to this request
        """
        return self.get("operator", timeout=timeout)

    def get_transaction(self, number: Union[str, int], timeout: Union[float, None] = 15) -> dict:
        """
        Get transaction.
        :param number: Transaction number or current or previous.
        :param timeout: Timeout in seconds. If the call does not complete within the timeout, it will fail.
        :return: Response to this request
        """
        data = {
            "number": number
        }
        return self.get("transaction", query=data, timeout=timeout)

    def get_frame(self, frame_type: str, timeout: Union[float, None] = 15) -> dict:
        """
        Get frame.
        :param frame_type: Frame type.
        :param timeout: Timeout in seconds. If the call does not complete within the timeout, it will fail.
        :return: Response to this request
        """
        data = {
            "type": frame_type
        }
        return self.get("opened-frame", query=data, timeout=timeout)

    def press_button(self, frame: int, button: str) -> dict:
        """
        Press button.

        :param frame: Instance ID of the frame which should contain the button.
        :param button: Description of the button which should be pressed.
        :return: Response to this request
        """
        data = {
            "frame": frame,
            "button": button
        }
        return self.post("button", query=data, json={})

    def wait_for_frame_close(self, frame_instance: int, timeout: float = 3) -> dict:
        """
        Wait until the required frame is closed.

        :param frame_instance: Instance ID of the frame which should be closed.
        :param timeout: Timeout in seconds. If the call does not complete within the timeout, the frame did not close.
        :return: Response to this request
        """
        data = {
            "current-instance": frame_instance,
            "timeout": int(timeout * 1000)
        }
        return self.get("next-opened-frame", query=data)

    def wait_for_frame(self, use_description: str, timeout: float = 3) -> dict:
        """
        Wait until the required frame is opened.

        :param frame: Usage description of the frame which should be opened.
        :param timeout: Timeout in seconds. If the call does not complete within the timeout, the frame did not open.
        :return: Response
        """
        data = {
            "use-description": use_description,
            "timeout": int(timeout * 1000)
        }
        return self.get("specific-frame", query=data)

    def wait_for_transaction_end(self, timeout: Optional[float] = 3) -> dict:
        """
        Wait until the transaction is ended.

        :param timeout: Timeout in seconds. If the call does not complete within the timeout, the transaction did not close.
        :return: Response to this request
        """
        used_timeout = int(timeout * 1000 if timeout else 3000)
        data = {
            "timeout": used_timeout
        }
        return self.get("closed-transaction", query=data)

    def begin_waiting_for_event(self, event: str):
        """Prepare event trap for the event."""
        data = {
            "event": event
        }
        return self.post("begin-waiting-for-event", query=data, json={})

    def end_waiting_for_events(self):
        """Deactivate all event traps."""
        return self.post("end-waiting-for-events", query={}, json={})

    def wait_for_complete_prepay_finalization(self, pump: int, amount: float, timeout: float = 3) -> dict:
        """
        Wait until finalization of the prepay with given amount is completed at the given pump.

        :param pump_id: Id
        :param amount: Fuel price of the prepay transaction.
        :param timeout: Timeout in seconds. If the call does not complete within the timeout, the transaction did not close.
        :return: Response to this request
        """
        data = {
            "pump": pump,
            "amount": amount,
            "timeout": int(timeout * 1000)
        }
        return self.get("completed-prepay-finalization", query=data)

    def wait_for_tender_added(self, tender_type: str, transaction_number: Union[str, int], timeout: float = 0.1) -> dict:
        """
        Wait until a tender is added to transaction.

        :param transaction_number: Transaction number or current.
        :param timeout: Timeout in seconds.
        :param tender_type: Type of the tender.
        :return: Response to this request
        """
        data = {
            "filter": tender_type,
            "transaction_number": transaction_number,
            "timeout": int(timeout * 1000)
        }
        return self.get("tender-added", query=data)

    def wait_for_refund_on_pump(self, pump: int, amount: float, timeout: float = 3) -> dict:
        """
        Wait until given amount is refunded at the given pump.

        :param pump_id: Id
        :param amount: Fuel price of the prepay transaction.
        :param timeout: Timeout in seconds. If the call does not complete within the timeout, the transaction did not close.
        :return: Response to this request
        """
        data = {
            "pump": pump,
            "amount": amount,
            "timeout": int(timeout * 1000)
        }
        return self.get("displayed-prepay-refund", query=data)

    def wait_for_item_added(self, filter: str, timeout: float) -> dict:
        """
        Wait until an item is added.

        :param filter: Filter
        :param timeout: Timeout in seconds. If the call does not complete within the timeout, the transaction did not close.
        :return: Response to this request
        """
        data = {
            "filter": filter,
            "timeout": int(timeout * 1000)
        }
        return self.get("item-added", query=data)

    def wait_for_pes_response(self, call_type: str, call_result: str, timeout: float) -> dict:
        """
        Waits until a pes response is received.

        :param call_type: PES call type, allowed values are: get, finalize, sync-finalize, void
        :param call_result: PES call result, allowed values are: success, offline, pending-action, voided, missing-credentials, process-error
        :param timeout: Timeout in seconds
        :return: Response to this request
        """
        data = {
            "call-type": call_type,
            "call-result": call_result,
            "timeout": int(timeout * 1000)
        }
        return self.get("pes-response-processed", query=data)

    def restart(self) -> dict:
        """
        Restart the POS application.

        :return: Response.
        """
        return self.post("system", json={})

    def reload_config(self) -> dict:
        """
        Reload configuration files not requiring a restart.

        :return: Response.
        """
        return self.post("config", json={})

    def send_relay(self, relay: relay_mod.RelayFile) -> dict:
        """
        Submit updated relay file configuration.

        :param relay: Relay file to send.
        :return: Response.
        """
        name = relay.pos_name
        if name is None:
            raise ValueError("Cannot send this relay type: {}".format(type(relay)))

        return self.put("config", query={"relay": name}, body=relay.to_xml().encode("utf-8"))

    def select_item(self, instance_id: int, list_item: int, only_highlighted: bool) -> dict:
        """
        Select item in VR.

        :param instance_id: Id of an instance, where the item si going to be selected
        :param list_item: Item number, which is going to be selected.
        :param only_highlighted: Force the item to be only marked as selected in UI.
        :return: Response to this request
        """
        data = {
            "frame": instance_id,
            "list-item": list_item,
            'only-highlighted': only_highlighted
        }
        return self.post("list-item", query=data, json={})

    def delete_all_stored_transactions(self) -> dict:
        """
        Delete all stored transactions.

        :return: Response to this request
        """
        data = {
        }
        return self.delete("stored-transactions", query=data, json={})
