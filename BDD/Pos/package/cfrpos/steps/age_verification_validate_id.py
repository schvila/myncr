from behave import *
from behave.runner import Context

from cfrpos.core.pos.ui_metadata import POSFrame, POSButton


# region Given clauses
@given('an age restricted item with barcode {barcode} is present in the transaction after scanning a DL and its secondary validation')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
            given the POS displays ID validation frame after scanning an age restricted item barcode {barcode} and scanning a DL
            when the cashier selects Yes button
        '''.format(barcode=barcode))
    assert context.pos.wait_for_item_added(barcode=barcode)


@given('an age restricted item with barcode {barcode} is present in the transaction after scanning a valid DL')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
            when the cashier scans a barcode {barcode}
            when the cashier scans a driver\'s license {drivers_license}
            then the POS displays main menu frame
        '''.format(barcode=barcode, drivers_license='valid DL'))
    assert context.pos.wait_for_item_added(barcode=barcode)


@given('the POS displays ID validation frame after scanning an age restricted item barcode {barcode} and scanning a DL')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
            when the cashier scans a barcode {barcode}
            when the cashier scans a driver\'s license {drivers_license}
            then the POS displays ID validation frame
        '''.format(barcode=barcode, drivers_license='valid DL'))


@given('an age restricted item with barcode {barcode} is present in the transaction after a scanned DL {license} age verification')
def step_impl(context: Context, barcode: str, license: str):
    context.execute_steps('''
        given the POS displays Age verification frame after scanning an item barcode {barcode}
        when the cashier scans a driver\'s license {drivers_license}
        then the POS displays main menu frame
    '''.format(barcode=barcode, drivers_license=license))
# endregion


# region When clauses
@when('the cashier scans a barcode {barcode} and totals the transaction')
def step_impl(context: Context, barcode: str):
    context.execute_steps('''
    when the cashier scans a barcode {barcode}
    when the cashier presses the cash tender button
    '''.format(barcode=barcode))
# endregion


# region Then clauses

# endregion
