"""After web build, publish the PUBLIC release certificate fingerprint for App Links."""
import argparse, json, pathlib, re
parser = argparse.ArgumentParser()
parser.add_argument('--sha256', required=True)
args = parser.parse_args()
fingerprint = args.sha256.upper()
assert re.fullmatch(r'(?:[0-9A-F]{2}:){31}[0-9A-F]{2}', fingerprint), 'Expected SHA-256 certificate fingerprint'
folder = pathlib.Path(__file__).resolve().parents[1] / 'build/web/.well-known'
folder.mkdir(parents=True, exist_ok=True)
content = json.dumps([{'relation': ['delegate_permission/common.handle_all_urls'], 'target': {'namespace': 'android_app', 'package_name': 'app.ankidsa.mobile', 'sha256_cert_fingerprints': [fingerprint]}}], indent=2)
(folder / 'assetlinks.json').write_text(content, encoding='utf-8')
# Netlify's ZIP importer can omit hidden directories. The exact 200 rewrite in
# prepare-web.py serves this identical public file at Android's canonical URL.
(folder.parent / 'assetlinks.json').write_text(content, encoding='utf-8')
print('Public Android App Links association prepared.')
