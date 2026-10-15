"""Prepare Chrome Web Store artwork and an upload ZIP from the verified release.

Requires Pillow and the screenshots produced by tests/extension.spec.cjs.
This does not submit to Google or modify the unpacked beta extension.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
GREEN, PAPER, MINT, MUTED = '#234F40', '#F7F6F0', '#B8DCBD', '#DCE7D8'
parser = argparse.ArgumentParser()
parser.add_argument('--screenshots-dir', type=Path, default=ROOT / '.work')
args = parser.parse_args()
assets = ROOT / 'store/chrome/assets'
assets.mkdir(parents=True, exist_ok=True)
release = ROOT / 'build/chrome-web-store'
release.mkdir(parents=True, exist_ok=True)

def font(size, bold=False):
    result = ImageFont.truetype(str(ROOT / 'assets/fonts/DMSans.ttf'), size)
    if bold:
        result.set_variation_by_axes([14, 650])
    return result

def text(canvas, xy, value, size, color=PAPER, bold=False, spacing=10):
    ImageDraw.Draw(canvas).multiline_text(xy, value, font=font(size, bold), fill=color, spacing=spacing)

icon = Image.open(ROOT / 'branding/ankidsa-icon.png').convert('RGBA')
store_icon = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
store_icon.alpha_composite(icon.resize((96, 96), Image.Resampling.LANCZOS), (16, 16))
store_icon.save(assets / 'icon-128.png')

promo = Image.new('RGB', (440, 280), GREEN)
inverse = Image.open(ROOT / 'branding/ankidsa-icon-inverse.png').convert('RGBA')
promo.paste(inverse.resize((112, 112), Image.Resampling.LANCZOS), (164, 36), inverse.resize((112, 112), Image.Resampling.LANCZOS))
draw = ImageDraw.Draw(promo)
draw.text((220, 171), 'AnkiDSA', font=font(38, True), fill=PAPER, anchor='mt')
draw.text((220, 226), 'Keep what you learn.', font=font(19), fill=MINT, anchor='mt')
promo.save(assets / 'small-promo-440x280.png')

capture = Image.new('RGB', (1280, 800), GREEN)
capture.paste(inverse.resize((64, 64), Image.Resampling.LANCZOS), (64, 48), inverse.resize((64, 64), Image.Resampling.LANCZOS))
text(capture, (148, 57), 'AnkiDSA', 36, bold=True)
text(capture, (68, 194), 'FOR YOUR LEETCODE PRACTICE', 17, MINT, bold=True)
text(capture, (64, 241), 'Save the idea\nbehind each\nsolution.', 65, bold=True, spacing=0)
text(capture, (68, 505), 'Capture a problem.\nWrite what clicked.\nKeep it for your next review.', 27, MUTED, spacing=13)
text(capture, (68, 714), 'The AnkiDSA Chrome extension', 18, MINT)
popup = Image.open(args.screenshots_dir / 'extension-saved.png').convert('RGB')
popup.thumbnail((385, 744), Image.Resampling.LANCZOS)
capture.paste(popup, (1280 - popup.width - 52, 28))
capture.save(assets / 'screenshot-1-capture-1280x800.png')

for number, source, title, filename in [
    (2, 'app-captured-queue.png', 'Continue in the companion web app', 'queue'),
    (3, 'app-review.png', 'Review your notes in the companion web app', 'review'),
]:
    canvas = Image.new('RGB', (1280, 800), PAPER)
    screenshot = Image.open(args.screenshots_dir / source).convert('RGB')
    # Keep the actual UI pixels and crop only unused space at the bottom.
    canvas.paste(screenshot.crop((0, 0, 1280, 744)), (0, 56))
    ImageDraw.Draw(canvas).rectangle((0, 0, 1279, 55), fill=GREEN)
    text(canvas, (28, 14), title, 22, bold=True)
    canvas.save(assets / f'screenshot-{number}-{filename}-1280x800.png')

source_zip = ROOT / 'build/extension/ankidsa-extension.zip'
target_zip = release / 'ankidsa-chrome-store.zip'
with zipfile.ZipFile(source_zip) as source:
    manifest = json.loads(source.read('manifest.json'))
    assert manifest['host_permissions'] == [
        'https://leetcode.com/*', 'https://ankidsa-backend.onrender.com/*']
    assert 'optional_host_permissions' not in manifest
    assert manifest['permissions'] == ['storage', 'activeTab', 'alarms']
    # The Web Store assigns the published item's identity. Keep the existing
    # development key only in the separately distributed unpacked beta package.
    manifest.pop('key', None)
    manifest['homepage_url'] = 'https://ankidsa.netlify.app'
    with zipfile.ZipFile(target_zip, 'w', zipfile.ZIP_DEFLATED) as target:
        for name in source.namelist():
            if name == 'manifest.json':
                target.writestr(name, json.dumps(manifest, indent=2, ensure_ascii=False))
            elif name == 'icons/128.png':
                target.write(assets / 'icon-128.png', name)
            elif name == 'PRIVACY.md' and (ROOT / 'store/chrome/PRIVACY.md').is_file():
                target.write(ROOT / 'store/chrome/PRIVACY.md', name)
            else:
                target.writestr(name, source.read(name))

with zipfile.ZipFile(target_zip) as archive:
    assert archive.testzip() is None
    config = archive.read('config.js').decode()
    assert 'https://ankidsa-backend.onrender.com' in config
    assert 'https://ankidsa.netlify.app' in config
    assert 'localhost' not in config and '.invalid' not in config
    assert 'key' not in json.loads(archive.read('manifest.json'))

for path in (ROOT / 'store/chrome').rglob('*'):
    if path.is_file() and path.name != 'PRIVACY-DRAFT.md':
        destination = release / path.relative_to(ROOT / 'store/chrome')
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
(release / 'PRIVACY-DRAFT.md').unlink(missing_ok=True)

checks = {'uploadZip': target_zip.name, 'version': manifest['version'],
          'sha256': hashlib.sha256(target_zip.read_bytes()).hexdigest(),
          'storeItemId': None, 'submissionStatus': 'not submitted',
          'requiresBeforeSubmission': ['verify the hosted privacy page is live',
                                      'actual Store item ID added to backend CORS',
                                      'registered Google developer account and submission']}
(release / 'package-check.json').write_text(json.dumps(checks, indent=2) + '\n')
print('Prepared Chrome Web Store artwork and upload ZIP: ' + str(target_zip))
