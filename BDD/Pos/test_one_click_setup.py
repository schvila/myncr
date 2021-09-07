import pytest
import one_click_setup

def test_get_initial_dirname():
    assert one_click_setup.get_initial_dirname(
            'C:\\Program Files\\Radiant\\Fastpoint\\Data') == 'C:\\Program Files\\Radiant\\Fastpoint\\Data-initial'
    assert one_click_setup.get_initial_dirname(
            'C:\\Program Files\\Radiant\\Fastpoint\\Data\\') == 'C:\\Program Files\\Radiant\\Fastpoint\\Data-initial'


