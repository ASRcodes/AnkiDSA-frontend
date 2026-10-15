"""Render public privacy/support pages after the owner confirms their contact."""
import argparse
from html import escape
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--publisher', required=True)
parser.add_argument('--email', required=True)
args = parser.parse_args()
if not args.publisher.strip() or not re.fullmatch(r'[^\s<>@]+@[^\s<>@]+\.[^\s<>@]+', args.email):
    parser.error('Provide the confirmed public publisher name and contact email.')

draft = (ROOT / 'store/chrome/PRIVACY-DRAFT.md').read_text(encoding='utf-8')
policy = '# AnkiDSA privacy policy\n\nEffective date:' + draft.split('Effective date:', 1)[1]
policy = re.sub(r'^Operator: .*$', 'Operator: ' + args.publisher, policy, flags=re.MULTILINE)
policy = policy.replace('[CONFIRMED PUBLIC SUPPORT EMAIL]', args.email)
assert '[CONFIRMED ' not in policy
(ROOT / 'store/chrome/PRIVACY.md').write_text(policy, encoding='utf-8')

def paragraphs(markdown):
    result = []
    for block in markdown.strip().split('\n\n'):
        if block.startswith('# '):
            continue
        if block.startswith('## '):
            result.append('<h2>' + escape(block[3:]) + '</h2>')
        else:
            text = escape(' '.join(block.splitlines()))
            text = text.replace(escape(args.email), f'<a href="mailto:{escape(args.email, quote=True)}">{escape(args.email)}</a>')
            result.append('<p>' + text + '</p>')
    return '\n'.join(result)

def page(title, subtitle, body):
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{escape(title)} · AnkiDSA</title><meta name="description" content="{escape(subtitle, quote=True)}">
<link rel="icon" href="/favicon.png"><style>
:root{{color-scheme:light}}*{{box-sizing:border-box}}body{{margin:0;background:#f7f6f0;color:#234f40;font:17px/1.75 system-ui,sans-serif}}
header,main,footer{{max-width:800px;margin:auto;padding:28px 24px}}header{{display:flex;align-items:center;gap:14px;border-bottom:1px solid #dce3d7}}
header img{{width:44px;height:44px}}header a{{font-size:22px;font-weight:650;text-decoration:none}}a{{color:inherit;text-underline-offset:4px}}
main{{padding-top:42px}}h1{{font:500 clamp(34px,7vw,48px)/1.2 Georgia,serif;margin:0 0 14px}}h2{{font-size:23px;line-height:1.35;margin:38px 0 12px}}
p{{margin:0 0 18px;overflow-wrap:anywhere}}.intro{{font-size:19px;color:#586e60;margin-bottom:36px}}footer{{font-size:14px;border-top:1px solid #dce3d7;display:flex;gap:24px;flex-wrap:wrap}}
</style></head><body><header><img src="/icons/Icon-192.png" alt=""><a href="/">AnkiDSA</a></header>
<main><h1>{escape(title)}</h1><p class="intro">{escape(subtitle)}</p>{body}</main>
<footer><a href="/">Open AnkiDSA</a><a href="/privacy/">Privacy policy</a><a href="/support/">Support</a></footer></body></html>
'''

pages = {
    'privacy': page('Privacy policy', 'How AnkiDSA uses and protects your study information.', paragraphs(policy)),
    'support': page('How can we help?', 'Support for AnkiDSA on the web, Chrome and Android.',
        f'<p>Contact {escape(args.publisher)} at <a href="mailto:{escape(args.email, quote=True)}">{escape(args.email)}</a>.</p>'
        '<h2>Report a problem</h2><p>Include your device and browser or Android version, the steps you took, '
        'what you expected, and what happened. A problem URL and the approximate time can help us investigate.</p>'
        '<p>Please do not send passwords, session tokens, hosting API keys, or payment details.</p>'
        '<h2>Account and privacy requests</h2><p>For account deletion, contact us from the email used for your '
        'AnkiDSA account. Deleting the browser extension does not delete your server account. You can delete '
        'individual problems and their notes through the app.</p>'
        '<h2>Current beta</h2><p>Problem capture, notes, synchronization and spaced reviews are available. '
        'Push reminders and password-reset email are not enabled yet.</p>'),
}
for name, html in pages.items():
    output = ROOT / 'web' / name / 'index.html'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(html, encoding='utf-8')
print('Rendered public privacy and support pages with the confirmed contact.')
