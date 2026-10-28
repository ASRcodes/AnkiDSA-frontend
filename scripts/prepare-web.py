"""Apply deploy-time headers to build/web after Flutter build. No dependencies."""
import argparse, pathlib, json
from importlib.util import spec_from_file_location, module_from_spec
root = pathlib.Path(__file__).resolve().parents[1]
spec = spec_from_file_location('packager', root / 'scripts/package-extension.py')
packager = module_from_spec(spec)
spec.loader.exec_module(packager)
parser = argparse.ArgumentParser()
parser.add_argument('--api', required=True)
parser.add_argument('--validation-only', action='store_true')
args = parser.parse_args()
api = packager.origin(args.api, args.validation_only)
output = root / 'build/web'
assert (output / 'main.dart.js').is_file(), 'Run flutter build web first'
index = output / 'index.html'
html = index.read_text(encoding='utf-8')
html = html.replace('<!-- ANKIDSA_API_ORIGIN -->',
                    '<meta name="ankidsa-api" content="' + api + '">')
index.write_text(html, encoding='utf-8')
for file in output.rglob('*'):
    if file.is_file() and file.stat().st_size > 25 * 1024 * 1024:
        raise ValueError('Asset exceeds the static hosting file-size budget: ' + file.name)
assert sum(f.is_file() for f in output.rglob('*')) <= 20000
csp = "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' " + api + "; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; form-action 'self'"
(output / '_headers').write_text('/*\n  Cache-Control: no-cache\n  X-Content-Type-Options: nosniff\n  X-Frame-Options: DENY\n  Referrer-Policy: no-referrer\n  Permissions-Policy: camera=(), microphone=(), geolocation=()\n  Strict-Transport-Security: max-age=31536000\n  Content-Security-Policy: ' + csp + '\n', encoding='utf-8')
(output / '_redirects').write_text('/.well-known/assetlinks.json /assetlinks.json 200\n/* /index.html 200\n', encoding='utf-8')
(output / 'build-info.json').write_text(json.dumps({'validationOnly': args.validation_only, 'api': api}), encoding='utf-8')
print('Prepared Netlify-compatible headers, SPA fallback and asset-budget checks.')
