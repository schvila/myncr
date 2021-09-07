import os
import unittest
from cfrpos.core.relay import DllRelay

class TestDllRelay(unittest.TestCase):
    def setUp(self):
        self.relay = DllRelay.load(os.path.dirname(os.path.abspath(__file__)), True)

    def tearDown(self):
        del self.relay

    def test_dataset(self):
        self.assertTrue(self.relay.update_required)
        self.relay.notify_applied()
        self.assertFalse(self.relay.update_required)
        self.assertEqual([
            'DbAbsObj.dll',
            'EpsilonClient.dll',
            'GCMClient.dll',
            'PCSTranMan.dll',
            'PosBDD.dll',
            'POSSigmaClient.dll']
                , self.relay.get_dlls())

    def test_enable_feature__enabled_feature(self):
        self.relay.notify_applied()
        self.relay.enable_feature('loyalty')
        self.assertFalse(self.relay.update_required)
        self.assertEqual([
            'DbAbsObj.dll',
            'EpsilonClient.dll',
            'GCMClient.dll',
            'PCSTranMan.dll',
            'PosBDD.dll',
            'POSSigmaClient.dll']
                , self.relay.get_dlls())

    def test_enable_feature__disabled_feature(self):
        self.relay.notify_applied()
        self.relay.enable_feature('PosApiServer')
        self.assertTrue(self.relay.update_required)
        self.assertEqual([
            'DbAbsObj.dll',
            'EpsilonClient.dll',
            'GCMClient.dll',
            'PCSTranMan.dll',
            'PosAPI.dll',
            'PosAPIServer.dll',
            'PosBDD.dll',
            'POSSigmaClient.dll']
                , self.relay.get_dlls())


if __name__ == '__main__':
    unittest.main()
