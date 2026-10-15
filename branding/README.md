# AnkiDSA logo

A custom geometric A with a recall dot, designed to stay readable at favicon size.
The forest-green and paper palette follows the existing product identity.

- Primary icon: `ankidsa-icon.svg` and its 1024 px transparent PNG.
- Light icon for dark surfaces: `ankidsa-icon-inverse.svg` / PNG.
- Standalone mark: `ankidsa-mark.svg`, inverse and monochrome variants.
- Horizontal wordmark: `ankidsa-wordmark.svg` and inverse. Lettering is outlined,
  so exported SVGs do not require a font installation.
- Review sheet: `brand-preview.png`, including actual 16/32/48/128 px samples.

Colors: forest `#234F40`, paper `#F7F6F0`, recall mint `#B8DCBD`.
Keep clear space of at least the dot diameter around the standalone mark. Do not
stretch, add shadows, rotate, or recolor individual pieces. Use the inverse version
on a dark surface. Android adaptive artwork is inset for system masking.

Regenerate platform assets with `python scripts/generate-brand.py` from the repo
root (Pillow and fontTools required). Web, extension, Flutter, Android, and iOS
assets all come from the same geometry. Android includes an adaptive icon,
a themed monochrome icon, and a matching notification mark. A portable kit is
written to `build/branding/ankidsa-brand-kit.zip`. Wordmark lettering uses the project's licensed
[DM Sans font](../assets/fonts/DMSans-LICENSE.txt).
