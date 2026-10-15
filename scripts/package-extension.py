"""Create an allowlisted MV3 release ZIP; no dependencies or secrets required."""
import argparse, json, pathlib, zipfile
from urllib.parse import urlsplit

def origin(value, validation=False):
    url = urlsplit(value)
    if (url.scheme != 'https' or not url.hostname or url.username or url.password
        or url.query or url.fragment or url.path not in ('', '/') or url.port
        or url.hostname in ('localhost', '127.0.0.1')
        or (url.hostname.endswith('.invalid') and not validation)):
        raise ValueError('Provide an allocated public HTTPS origin (no path).')
    return value.rstrip('/')

def package(api, app, validation=False):
    api, app = origin(api, validation), origin(app, validation)
    root = pathlib.Path(__file__).resolve().parents[1]
    source = root / 'extension'
    manifest = json.loads((source / 'manifest.json').read_text(encoding='utf-8'))
    assert manifest['manifest_version'] == 3 and manifest['background']['type'] == 'module'
    manifest['host_permissions'] = ['https://leetcode.com/*', api + '/*']
    manifest.pop('optional_host_permissions', None)
    manifest['content_security_policy']['extension_pages'] += '; connect-src ' + api + '; base-uri \'none\'; frame-ancestors \'none\''
    config = {'baseUrl': api, 'appUrl': app, 'autoSave': True, 'production': True}
    files = ['background.js', 'core.js', 'content.js', 'popup.js', 'popup.html', 'popup.css', 'DMSans.ttf', 'Lora.ttf', 'DMSans-LICENSE.txt', 'Lora-LICENSE.txt', 'PRIVACY.md', 'INSTALL.txt', 'icons/16.png', 'icons/32.png', 'icons/48.png', 'icons/128.png']
    output = root / 'build' / 'extension'
    output.mkdir(parents=True, exist_ok=True)
    target = output / ('ankidsa-validation-only.zip' if validation else 'ankidsa-extension.zip')
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        for file in files: archive.write(source / file, file)
        archive.writestr('manifest.json', json.dumps(manifest, indent=2, ensure_ascii=False))
        archive.writestr('config.js', 'export const defaults = ' + json.dumps(config) + ';\n')
        archive.writestr('BUILD-INFO.txt', ('VALIDATION ONLY — not connected to live services\n' if validation else 'AnkiDSA beta\n') + api + '\n' + app + '\n')
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        assert all('..' not in name for name in archive.namelist())
    print(target)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--api', required=True)
    parser.add_argument('--app', required=True)
    parser.add_argument('--validation-only', action='store_true')
    args = parser.parse_args()
    package(args.api, args.app, args.validation_only)
