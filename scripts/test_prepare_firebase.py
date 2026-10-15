import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location(
    'firebase_config', pathlib.Path(__file__).with_name('prepare-firebase.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class FirebaseConfigurationTest(unittest.TestCase):
    def setUp(self):
        self.android = {
            'project_info': {'project_id': 'test-project', 'project_number': '12345'},
            'client': [{'client_info': {
                'android_client_info': {'package_name': module.PACKAGE},
                'mobilesdk_app_id': '1:12345:android:test'},
                'api_key': [{'current_key': 'public-client-test-key'}]}],
        }
        self.base = {'APP_ENV': 'production', 'API_BASE_URL': 'https://api.example.test',
                     'APP_PUBLIC_URL': 'https://app.example.test', 'DEMO_MODE': 'false',
                     'JWT_SECRET': 'must-never-enter-client-config'}
        self.admin = {'type': 'service_account', 'project_id': 'test-project',
                      'token_uri': 'https://oauth2.googleapis.com/token',
                      'private_key': 'unit-test-placeholder-not-a-real-key'}

    def test_only_public_client_fields_are_written(self):
        result = module.client_config(self.android, self.base, self.admin)
        self.assertEqual('true', result['PUSH_NOTIFICATIONS_ENABLED'])
        self.assertEqual('1:12345:android:test', result['FIREBASE_APP_ID'])
        self.assertNotIn('JWT_SECRET', result)
        self.assertNotIn(self.admin['private_key'], str(result))

    def test_wrong_android_package_is_rejected(self):
        self.android['client'][0]['client_info']['android_client_info']['package_name'] = 'other.app'
        with self.assertRaises(ValueError):
            module.client_config(self.android, self.base, self.admin)

    def test_different_admin_project_is_rejected(self):
        self.admin['project_id'] = 'different-project'
        with self.assertRaises(ValueError):
            module.client_config(self.android, self.base, self.admin)

    def test_unexpected_credential_endpoint_is_rejected(self):
        self.admin['token_uri'] = 'https://example.test/token'
        with self.assertRaises(ValueError):
            module.client_config(self.android, self.base, self.admin)


if __name__ == '__main__':
    unittest.main()
