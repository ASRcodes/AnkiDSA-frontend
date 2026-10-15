"""Build ignored Android release configuration from Firebase's downloaded files.

Only allowlisted public client values enter the app configuration. The Admin SDK
key is checked for the matching project and never copied into the APK settings.
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = 'app.ankidsa.mobile'


def client_config(android, base, service_account):
    project = android['project_info']
    project_id = project['project_id']
    number = str(project['project_number'])
    if not project_id or not number.isdigit():
        raise ValueError('Firebase project identifiers are incomplete.')
    clients = [client for client in android.get('client', [])
               if client.get('client_info', {}).get('android_client_info', {})
               .get('package_name') == PACKAGE]
    if len(clients) != 1:
        raise ValueError('Register exactly one matching Android app: ' + PACKAGE)
    client = clients[0]
    app_id = client['client_info']['mobilesdk_app_id']
    keys = [key['current_key'] for key in client.get('api_key', [])
            if key.get('current_key')]
    if not app_id.startswith('1:' + number + ':android:') or len(keys) != 1:
        raise ValueError('Android app ID or public client API key is invalid.')
    if (service_account.get('type') != 'service_account'
            or service_account.get('project_id') != project_id
            or service_account.get('token_uri') != 'https://oauth2.googleapis.com/token'
            or not isinstance(service_account.get('private_key'), str)
            or not service_account['private_key'].strip()):
        raise ValueError('Use the Admin SDK service-account key for the same Firebase project.')
    config = {key: base[key] for key in
              ('APP_ENV', 'API_BASE_URL', 'APP_PUBLIC_URL', 'DEMO_MODE')}
    config.update({
        'PUSH_NOTIFICATIONS_ENABLED': 'true',
        'FIREBASE_API_KEY': keys[0],
        'FIREBASE_APP_ID': app_id,
        'FIREBASE_MESSAGING_SENDER_ID': number,
        'FIREBASE_PROJECT_ID': project_id,
    })
    return config


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--android-config', type=Path,
                        default=ROOT / '.work/firebase/google-services.json')
    parser.add_argument('--service-account', type=Path,
                        default=ROOT / '.work/firebase/firebase-service-account.json')
    parser.add_argument('--base', type=Path,
                        default=ROOT / 'config/study-beta.example.json')
    parser.add_argument('--output', type=Path,
                        default=ROOT / 'config/production.local.json')
    args = parser.parse_args()
    if not args.output.name.endswith('.local.json'):
        parser.error('Output must end in .local.json so it stays out of source control.')
    try:
        inputs = [json.loads(path.read_text(encoding='utf-8-sig')) for path in
                  (args.android_config, args.base, args.service_account)]
        config = client_config(*inputs)
    except FileNotFoundError:
        parser.error('Save the Firebase Android config and Admin SDK key in .work/firebase first.')
    except (KeyError, ValueError, TypeError):
        parser.error('Firebase files do not contain a matching Android app and service-account project.')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(config, indent=2) + '\n', encoding='utf-8')
    print('Prepared Android push configuration for ' + config['FIREBASE_PROJECT_ID'])
    print('Output: ' + str(args.output))
    print('No Admin SDK key or other server secrets were copied to the app configuration.')


if __name__ == '__main__':
    main()
