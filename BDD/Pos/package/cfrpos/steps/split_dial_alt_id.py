import json
import time
from behave import *
from behave.runner import Context
from cfrpos.core.bdd_utils.poscache_utils import POSCacheUtils
from cfrpos.core.bdd_utils.timeouter import timeouter
from cfrpos.core.pos.ui_metadata import POSButton, POSFrame


# region Given clauses (configuration)
@given('the POS has following loyalty programs configured')
def step_impl(context: Context):
    context.pos.relay_catalog.clear_existing_loyalty_programs()
    for row in context.table:
        card_definition_id = row["card_definition_id"]
        external_id = row["external_id"]
        program_name = row["program_name"]
        context.pos.relay_catalog.create_loyalty_program(external_id, program_name)
        context.pos.relay_catalog.assign_card_to_loyalty_program(card_definition_id, program_name)


@given('the POS has following cards assigned to loyalty programs')
def step_impl(context: Context):
    for row in context.table:
        card_definition_id = row["card_definition_id"]
        program_name = row["program_name"]
        context.pos.relay_catalog.assign_card_to_loyalty_program(card_definition_id, program_name)


@given("a customer presses the Alt ID button")
def step_impl(context: Context):
    context.execute_steps('''
        when a customer presses the Alt ID button
    ''')


@given("the pinpad displays a list of available loyalty programs after Alt ID button was pressed")
def step_impl(context: Context):
    context.execute_steps('''
        given a customer presses the Alt ID button
        and the POS sends GETPICKLISTEX request
    ''')


@given("the customer selected a loyalty program with name {name} from the picklist and entered valid Alt ID {alt_id}")
def step_impl(context: Context, name: str, alt_id: str):
    data = context.epc_sim.poscache.get_poscache_data()
    picklist = timeouter(context.epc_sim.poscache.wait_for_picklist_received, 3)
    id = POSCacheUtils.find_program_id_in_picklist(name, picklist)
    assert id is not None
    context.epc_sim.poscache.update_loyalty_pick_list(picklist)
    context.execute_steps('''
        given the POS sent GETMANUAL request after customer selected a loyalty program with id {id:d}
        and the customer enters a valid Alt ID {alt_id} on the pinpad
    '''.format(id=id, alt_id=alt_id))


@given("the pinpad displays Enter alt ID frame after the customer chose {name} loyalty program")
def step_impl(context: Context, name: str):
    context.execute_steps('''
        given the pinpad displays a list of available loyalty programs after Alt ID button was pressed
        and the customer selected a loyalty program with name {name} from the picklist
        then the pinpad displays Enter alt ID frame
    '''.format(name=name))


@given("the pinpad displays Enter loyalty pin frame after cashier selected cash tender button")
def step_impl(context: Context):
    context.execute_steps('''
        when the cashier presses the cash tender button
        then the pinpad displays Enter loyalty pin frame
    ''')


@given("the customer selected a loyalty program with name {name} from the picklist")
def step_impl(context: Context, name: str):
    data = context.epc_sim.poscache.get_poscache_data()
    picklist = timeouter(context.epc_sim.poscache.wait_for_picklist_received, 3)
    id = POSCacheUtils.find_program_id_in_picklist(name, picklist)
    assert id is not None
    context.epc_sim.poscache.update_loyalty_pick_list(picklist)
    context.execute_steps('''
        given the POS sent GETMANUAL request after customer selected a loyalty program with id {id:d}
    '''.format(id=id))


@given("a customer selected loyalty with id {id:d} from the picklist")
def step_impl(context: Context, id: int):
    context.execute_steps('''
        when a customer selected loyalty with id {id:d} from the picklist
    '''.format(id=id))


@given("the POS sent GETMANUAL request after customer selected a loyalty program with id {id:d}")
def step_impl(context: Context, id: int):
    context.execute_steps('''
        given a customer selected loyalty with id {id:d} from the picklist
        then the pinpad displays Enter alt ID frame
    '''.format(id=id))


@given("the POS sends {request} request")
def step_impl(context: Context, request: str):
    context.execute_steps('''
        then the POS sends {request} request
    '''.format(request=request))


@given("the customer enters a valid Alt ID {alt_id} on the pinpad")
def step_impl(context: Context, alt_id: str):
    context.execute_steps('''
        when the customer enters a valid Alt ID {alt_id} on the pinpad
    '''.format(alt_id=alt_id))


@given("the POS sent GETNUMERIC request after customer selected a loyalty program with id {id:d} and entered valid Alt ID {alt_id}")
def step_impl(context: Context, id: int, alt_id: str):
    context.execute_steps('''
        given the POS sent GETMANUAL request after customer selected a loyalty program with id {id:d}
        and the customer enters a valid Alt ID {alt_id} on the pinpad
        and the POS sends GETNUMERIC request
    '''.format(id=id, alt_id=alt_id))
# endregion


# region When clauses
@when("a customer presses the Alt ID button")
def step_impl(context: Context):
    context.epc_sim.poscache.create_transaction()
    context.epc_sim.poscache.post_complete_with_message(message_name="AltIdPressed", message_id=context.epc_sim.poscache.POS_CACHE_EVENT_MESSAGE_ID)


@when("a customer selected loyalty with id {id:d} from the picklist")
def step_impl(context: Context, id: int):
    context.epc_sim.poscache.update_loyalty_pick_list_result(id)
    context.epc_sim.poscache.post_complete_with_message(message_id=context.epc_sim.poscache.BASE_POS_CACHE_MESSAGE_ID)


@when("a customer selected loyalty program with name {name} from the picklist")
def step_impl(context: Context, name: str):
    data = context.epc_sim.poscache.get_poscache_data()
    picklist = timeouter(context.epc_sim.poscache.wait_for_picklist_received, 3)
    id = POSCacheUtils.find_program_id_in_picklist(name, picklist)
    assert id is not None
    context.epc_sim.poscache.update_loyalty_pick_list(picklist)
    context.epc_sim.poscache.update_loyalty_pick_list_result(id)
    context.epc_sim.poscache.post_complete_with_message(message_id=context.epc_sim.poscache.BASE_POS_CACHE_MESSAGE_ID)


@when("the customer enters a valid Alt ID {alt_id} on the pinpad")
def step_impl(context: Context, alt_id: str):
    context.epc_sim.poscache.set_poscache_message("GetManualResponse")
    context.epc_sim.poscache.update_poscache_nvp("GetManualResponse", "smRAWCARDDATA", alt_id)
    context.epc_sim.poscache.post_complete_with_message(message_id=context.epc_sim.poscache.BASE_POS_CACHE_MESSAGE_ID)
    time.sleep(1)


@when("the customer enters a valid PIN {pin} on the pinpad")
def step_impl(context: Context, pin: str):
    context.epc_sim.poscache.set_poscache_message("GetNumericResponse")
    context.epc_sim.poscache.update_poscache_nvp("GetNumericResponse", "smRAWCARDDATA", pin)
    context.epc_sim.poscache.post_complete_with_message(message_id=context.epc_sim.poscache.BASE_POS_CACHE_MESSAGE_ID)
# endregion


# region Then clauses
@then("the POS sends {request} request")
def step_impl(context: Context, request: str):
    assert timeouter(context.epc_sim.poscache.wait_for_data_received, 3, request)


@then("the pinpad displays a list of available loyalty programs")
def step_impl(context: Context):
    context.execute_steps('''
        then the POS sends GETPICKLISTEX request
    ''')


@then("the pinpad displays following list of available loyalty programs")
def step_impl(context: Context):
    data = context.epc_sim.poscache.get_poscache_data()
    picklist = timeouter(context.epc_sim.poscache.wait_for_picklist_received, 3)
    for row in context.table.rows:
        name = row.get('program_description')
        assert POSCacheUtils.find_program_id_in_picklist(name, picklist), 'Program {} not found'.format(name)


@then("the pinpad displays Enter alt ID frame")
def step_impl(context: Context):
    context.execute_steps('''
        then the POS sends GETMANUAL request
    ''')


@then("the pinpad displays Enter loyalty pin frame")
def step_impl(context: Context):
    context.execute_steps('''
        then the POS sends GETNUMERIC request
    ''')


@then("the POS displays Unknown Alt ID frame")
def step_impl(context: Context):
    context.pos.wait_for_frame_open(POSFrame.ASK_ALTERNATE_ID)
    assert context.pos._control.check_frame_title('Unknown Alt ID')
# endregion