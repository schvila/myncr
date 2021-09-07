from os import path, environ
from urllib.error import HTTPError

from cfrpos.core.pos.pos_product import POSProduct
from cfrpos.core.pos_connect.pos_connect_client import POSConnectClient
from sim4cfrpos.api.scan_sim.scan_sim_control import ScanSimControl
from sim4cfrpos.api.swipe_sim.swipe_sim_control import SwipeSimControl
from sim4cfrpos.api.print_sim.print_sim_control import PrintSimControl
from sim4cfrpos.api.epc_sim.electronic_payments_control import ElectronicPaymentsControl
from sim4cfrpos.api.fcs_sim.fuel_control import FuelControl
from sim4cfrpos.api.stmapi_sim.stmapi_control import StmapiControl
from sim4cfrpos.api.kps_sim.kps_sim_control import KPSSimControl
from sim4cfrpos.api.dc_host.dc_host_control import DCHostControl
from sim4cfrpos.api.checkreader_sim.check_reader_control import CheckReaderSimControl
from sim4cfrpos.api.wincor_sim.wincor_sim_control import WincorSimControl
from sim4cfrpos.api.nepsvcs_sim.nepsvcs_sim_control import NepSvcsSimControl
from cfrpos.core.simulators.sc_sim.pos_services_control import PosServicesControl
from cfrpos.pos_configuration import initialize_context
from cfrpos.core.bdd_utils import bdd_environment
from cfrpos.core.bdd_utils import logging_utils
from cfrpos.core.bdd_utils.screenshotter import take_screenshot
from cfrpos.core.bdd_utils.performance_stats import PerformanceStats
from cfrpos.core.bdd_utils.pes_utils import PesNepSimFacade
from cfrpos.core.bdd_utils.ulp_utils import UlpNepSimFacade
import asyncio
import winreg
import sys

def before_all(context):
    sys.stdout.reconfigure(encoding='utf-8')
    context.pes_feature = False
    context.ulp_feature = False
    context.performance = PerformanceStats()


def after_all(context):
    print('Performance Stats')
    context.performance.report()


def before_feature(context, feature):
    print('Preparing feature')
    context.background_steps = feature.background.steps if feature.background is not None else []

    # timeout in seconds to wait for screen updates, increase for debugging
    context.screen_wait_timeout = 1

    bdd_dir = path.dirname(path.realpath(__file__))
    bdd_config_user = bdd_environment.read_bdd_config(context.config.userdata.get('bdd_config', None))
    if bdd_config_user is None:
        default_config_dir = path.abspath(path.join(bdd_dir, '..', '..', 'config'))
        bdd_config_path = path.join(bdd_dir, 'config.user.json')
        if not path.isfile(bdd_config_path):
            bdd_config_path = path.join(default_config_dir, 'config.user.json')
        if not path.isfile(bdd_config_path):
            print("WARNING: User defined BDD configuration not found, path: {}...".format(bdd_config_path))
            print("Trying to use default configuration file (not recommended)...")
            bdd_config_path = path.abspath(path.join(bdd_dir, 'config', 'config.json'))
            if not path.isfile(bdd_config_path):
                bdd_config_path = path.abspath(path.join(default_config_dir, 'config.json'))
            if not path.isfile(bdd_config_path):
                raise Exception('The BDD configuration file not found, path: {}.'.format(bdd_config_path))
        print("BDD config: {}".format(bdd_config_path))
        bdd_config_user = bdd_environment.read_bdd_config(bdd_config_path)
    else:
        print("BDD config: defined by user online")
    context.bdd_config = bdd_config_user
    assert context.bdd_config is not None
    context.bdd_config['bdd_dir'] = bdd_dir

    logging_utils.configure_ev_logger(
        log_file=context.bdd_config.get('log_file', None),
        log_console=context.bdd_config.get('log_console', False),
        log_level=context.bdd_config.get('log_level', None))
    logging_utils.get_ev_logger().info('FEATURE: {}'.format(feature.name))

    api_config = context.bdd_config.get('api', {})
    rpos_env = context.bdd_config.get('rpos_env', environ.copy())

    try:
        winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r'Software\RadiantSystems\RadGCM')
    except:
        raise Exception("RadGCM PlugInDLLs registry entries do not exist.")

    # POSServices (Site Controller) Simulator
    context.sc = PosServicesControl({**context.bdd_config, **api_config.get('sc_sim', {})})
    assert context.sc is not None, "SC sim not available."
    if not context.sc.is_active():
        try:
            bdd_environment.start_binary(context.sc, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start SC simulator. Start it manually if required...")

    # Scan Simulator
    context.scan_sim = ScanSimControl({**context.bdd_config, **api_config.get('scan_sim', {})})
    assert context.scan_sim is not None, "Scan simulator not available."
    if not context.scan_sim.is_active():
        try:
            bdd_environment.start_script(context.scan_sim, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start Scanner simulator! Start it manually if required...")

    # Swipe Simulator
    context.swipe_sim = SwipeSimControl({**context.bdd_config, **api_config.get('swipe_sim', {})})
    assert context.swipe_sim is not None, "Swipe simulator not available."
    if not context.swipe_sim.is_active():
        try:
            bdd_environment.start_script(context.swipe_sim, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start Swipe simulator! Start it manually if required...")

    # Print Simulator
    context.print_sim = PrintSimControl({**context.bdd_config, **api_config.get('print_sim', {})})
    assert context.print_sim is not None, "Print simulator not available."
    if not context.print_sim.is_active():
        try:
            bdd_environment.start_script(context.print_sim, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start Print simulator! Start it manually if required...")

    # EPC Simulator (EPS + PosCache + Sigma)
    context.epc_sim = ElectronicPaymentsControl({**context.bdd_config, **api_config.get('epc_sim', {})})
    assert context.epc_sim is not None, "Electronic Payments simulator simulator not available."
    if not context.epc_sim.is_active():
        try:
            bdd_environment.start_script(context.epc_sim, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start Electronic payments simulator! Start it manually if required...")

    # STMAPI Simulator
    context.stmapi_sim = StmapiControl({**context.bdd_config, **api_config.get('stmapi_sim', {})})
    assert context.stmapi_sim is not None, "StmAPI simulator not available."
    if not context.stmapi_sim.is_active():
        try:
            bdd_environment.start_script(context.stmapi_sim, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start StmAPI simulator! Start it manually if required...")

    # Wincor Simulator
    context.wincor_sim = WincorSimControl({**context.bdd_config, **api_config.get('wincor_sim', {})})
    assert context.wincor_sim is not None, "Wincor simulator not available."

    # DCServer Simulator
    context.dc_server = DCHostControl({**context.bdd_config, **api_config.get('dc_server', {})})
    assert context.dc_server is not None, "DCHost simulator not available."

    # CheckReader Simulator
    context.checkreader_sim = CheckReaderSimControl({**context.bdd_config, **api_config.get('checkreader_sim', {})})
    assert context.checkreader_sim is not None, "CheckReader simulator not available."
    if not context.checkreader_sim.is_active():
        try:
            bdd_environment.start_script(context.checkreader_sim, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start Checkreader simulator! Start it manually if required...")

    # Run NEPServicesSimulator
    context.nepsvcs_sim = NepSvcsSimControl({**context.bdd_config, **api_config.get('nepsvcs_sim', {})})
    assert context.nepsvcs_sim is not None, "NEP Services simulator not available."
    if not context.nepsvcs_sim.is_active():
        try:
            bdd_environment.start_script(context.nepsvcs_sim, rpos_env)
        except HTTPError as e:
            print("WARNING: Could not start NEPServicesSimulator simulator! Start it manually if required...")
    context.pes_nep_sim = PesNepSimFacade(context.nepsvcs_sim)
    context.ulp_nep_sim = UlpNepSimFacade(context.nepsvcs_sim)
    context.last_pes_messages = []
    context.last_ulp_messages = []

    # Fuel Simulator
    context.fuel_sim = FuelControl({**context.bdd_config, **api_config.get('fuel_sim', {})})
    assert context.fuel_sim is not None, "Fuel simulator not available."

    # KPS Simulator
    context.kps_sim = KPSSimControl({**context.bdd_config, **api_config.get('kps_sim', {})})
    assert context.kps_sim is not None, "KPS simulator not available."

    # POSEngine
    context.pos = POSProduct({**context.bdd_config, **api_config.get('pos', {})}, context.scan_sim, context.swipe_sim, context.print_sim, context.checkreader_sim, context.sc)
    context.pos.verify_ready()

    context.pos_connect = POSConnectClient({**context.bdd_config, **api_config.get('pos_connect', {})})

    if not context.fuel_sim.is_active():
        print("WARNING: Something is wrong with Fuel simulator, it indicates itself as offline.")

    initialize_context(context)


def before_tag(context, tag):
    if tag == "pes":
        context.pes_feature = True
    elif tag == "ulp":
        context.ulp_feature = True


def after_feature(context, feature):
    context.performance.add(context.pos.collect_performance())
    context.pes_feature = False
    context.ulp_feature = False
    asyncio.get_event_loop().close()
    asyncio.set_event_loop(asyncio.new_event_loop())


def before_scenario(context, scenario):
    context.pos.receipts_available.clear()
    context.pos.receipt_sections.clear()
    context.pos.verify_ready()


def after_scenario(context, scenario):
    if context.pes_feature or context.ulp_feature:
        context.nepsvcs_sim.dispose_traps()
    if 'pos_connect' in scenario.effective_tags:
        context.pos_connect.finalize_flow(context.pos)


def before_step(context, step):
    if (context.pes_feature or context.ulp_feature) and step.step_type == 'when':
        context.nepsvcs_sim.dispose_traps(leave_delays=True)
        context.nepsvcs_sim.create_traps()
        context.last_pes_messages = []
        context.last_ulp_messages = []


def after_step(context, step):
    if step.status == 'failed' and context.bdd_config.get('take_screenshots', False):
        take_screenshot(context.config.junit_directory)
