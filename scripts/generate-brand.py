"""Generate the AnkiDSA vector logo and consistent platform icons.

Uses Pillow and fontTools. Fonts are the project's licensed DM Sans assets.
"""
from pathlib import Path
import json
import zipfile
from PIL import Image, ImageDraw, ImageFont
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / 'branding'
BRAND.mkdir(exist_ok=True)
GREEN, PAPER, MINT = '#234F40', '#F7F6F0', '#B8DCBD'
MARK = 'M133 364 L231 151 Q239 135 256 135 Q273 135 281 151 L379 364 H327 L302 305 H210 L185 364 Z M229 260 H283 L256 193 Z'

def svg(tile=True, inverse=False, mono=False):
    foreground = GREEN if inverse else PAPER
    background = PAPER if inverse else GREEN
    if not tile:
        foreground = PAPER if inverse else GREEN
    dot = foreground if mono else (GREEN if inverse else MINT)
    rect = f'<rect width="512" height="512" rx="112" fill="{background}"/>' if tile else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-label="AnkiDSA"><title>AnkiDSA</title>{rect}<path d="{MARK}" fill="{foreground}" fill-rule="evenodd"/><circle cx="357" cy="159" r="21" fill="{dot}"/></svg>\n'

def quadratic(start, control, end):
    return [((1-t)**2*start[0]+2*(1-t)*t*control[0]+t*t*end[0],
             (1-t)**2*start[1]+2*(1-t)*t*control[1]+t*t*end[1]) for t in [i/32 for i in range(1,33)]]

def icon(size, inverse=False, tile=True, mono=False):
    scale = max(4, 2048//size)
    canvas = size*scale
    factor = canvas/512
    image = Image.new('RGBA',(canvas,canvas),(0,0,0,0))
    draw = ImageDraw.Draw(image)
    foreground, background = (GREEN,PAPER) if inverse else (PAPER,GREEN)
    if tile:
        draw.rounded_rectangle((0,0,canvas-1,canvas-1),radius=112*factor,fill=background)
    else:
        foreground=PAPER if inverse else GREEN
    mask=Image.new('L',(canvas,canvas),0)
    md=ImageDraw.Draw(mask)
    points=[(133,364),(231,151)] + quadratic((231,151),(239,135),(256,135)) + quadratic((256,135),(273,135),(281,151)) + [(379,364),(327,364),(302,305),(210,305),(185,364)]
    md.polygon([(x*factor,y*factor) for x,y in points],fill=255)
    md.polygon([(229*factor,260*factor),(283*factor,260*factor),(256*factor,193*factor)],fill=0)
    layer=Image.new('RGBA',(canvas,canvas),foreground)
    image.alpha_composite(Image.composite(layer,Image.new('RGBA',(canvas,canvas)),mask))
    ImageDraw.Draw(image).ellipse((336*factor,138*factor,378*factor,180*factor),fill=foreground if mono else (GREEN if inverse else MINT))
    return image.resize((size,size),Image.Resampling.LANCZOS)

def save_icon(path, size, **kwargs):
    path=ROOT/path
    path.parent.mkdir(parents=True,exist_ok=True)
    icon(size,**kwargs).save(path)

for name,options in [('ankidsa-icon',{}),('ankidsa-icon-inverse',{'inverse':True}),
                     ('ankidsa-mark',{'tile':False}),('ankidsa-mark-inverse',{'tile':False,'inverse':True}),
                     ('ankidsa-mark-monochrome',{'tile':False,'mono':True})]:
    (BRAND/(name+'.svg')).write_text(svg(**options),encoding='utf-8')
    icon(1024,**options).save(BRAND/(name+'.png'))

save_icon(Path('assets/brand/ankidsa-icon.png'),256)
save_icon(Path('assets/brand/ankidsa-icon-inverse.png'),256,inverse=True)
save_icon(Path('web/favicon.png'),32)
for size in (192,512):
    save_icon(Path(f'web/icons/Icon-{size}.png'),size)
    # Maskable icons have a full-bleed background, with artwork inside the safe circle.
    mark=icon(size)
    full=Image.new('RGBA',(size,size),GREEN);full.alpha_composite(mark)
    full.convert('RGB').save(ROOT/f'web/icons/Icon-maskable-{size}.png')
for size in (16,32,48,128):
    save_icon(Path(f'extension/icons/{size}.png'),size)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    save_icon(Path(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'),size)

# iOS applies its own corner mask and requires opaque app artwork.
ios=ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((ios/'Contents.json').read_text())['images']:
    size=round(float(entry['size'].split('x')[0])*float(entry['scale'].rstrip('x')))
    full=Image.new('RGBA',(size,size),GREEN)
    full.alpha_composite(icon(size))
    full.convert('RGB').save(ios/entry['filename'])

font=TTFont(ROOT/'assets/fonts/DMSans.ttf')
if 'fvar' in font: font=instantiateVariableFont(font,{'wght':700},inplace=False)
glyphs=font.getGlyphSet();cmap=font.getBestCmap();units=font['head'].unitsPerEm
paths=[];advance=0;scale=112/units
for character in 'AnkiDSA':
    glyph=glyphs[cmap[ord(character)]];pen=SVGPathPen(glyphs);glyph.draw(pen)
    paths.append(f'<path d="{pen.getCommands()}" transform="translate({advance*scale:.3f} 0) scale({scale:.6f} {-scale:.6f})"/>')
    advance+=glyph.width-14
width=round(196+advance*scale+20)
for inverse in (False,True):
    foreground=PAPER if inverse else GREEN
    symbol=svg(tile=False,inverse=inverse).split('<title>AnkiDSA</title>',1)[1].split('</svg>',1)[0]
    wordmark=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} 180" role="img" aria-label="AnkiDSA"><title>AnkiDSA</title><g transform="translate(-26 -4) scale(.37)">{symbol}</g><g fill="{foreground}" transform="translate(168 128)">{"".join(paths)}</g></svg>\n'
    (BRAND/('ankidsa-wordmark-inverse.svg' if inverse else 'ankidsa-wordmark.svg')).write_text(wordmark,encoding='utf-8')

foreground=f'''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="512" android:viewportHeight="512">
  <group android:scaleX="0.85" android:scaleY="0.85" android:pivotX="256" android:pivotY="256">
    <path android:fillColor="{PAPER}" android:fillType="evenOdd" android:pathData="{MARK}"/>
    <path android:fillColor="{MINT}" android:pathData="M378,159 A21,21 0,1 1,336,159 A21,21 0,1 1,378,159"/>
  </group>
</vector>\n'''
(ROOT/'android/app/src/main/res/drawable/ic_launcher_foreground.xml').write_text(foreground,encoding='utf-8')
mono=f'''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="512" android:viewportHeight="512">
  <group android:scaleX="0.85" android:scaleY="0.85" android:pivotX="256" android:pivotY="256">
    <path android:fillColor="#FFFFFFFF" android:fillType="evenOdd" android:pathData="{MARK}"/>
    <path android:fillColor="#FFFFFFFF" android:pathData="M378,159 A21,21 0,1 1,336,159 A21,21 0,1 1,378,159"/>
  </group>
</vector>\n'''
(ROOT/'android/app/src/main/res/drawable/ic_launcher_monochrome.xml').write_text(mono,encoding='utf-8')
notification=f'''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="512" android:viewportHeight="512">
  <group android:scaleX="1.5" android:scaleY="1.5" android:pivotX="256" android:pivotY="256">
    <path android:fillColor="#FFFFFFFF" android:fillType="evenOdd" android:pathData="{MARK}"/>
    <path android:fillColor="#FFFFFFFF" android:pathData="M378,159 A21,21 0,1 1,336,159 A21,21 0,1 1,378,159"/>
  </group>
</vector>\n'''
(ROOT/'android/app/src/main/res/drawable/ic_notification.xml').write_text(notification,encoding='utf-8')
adaptive=ROOT/'android/app/src/main/res/mipmap-anydpi-v26';adaptive.mkdir(exist_ok=True)
(adaptive/'ic_launcher.xml').write_text('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/ic_launcher_background"/><foreground android:drawable="@drawable/ic_launcher_foreground"/></adaptive-icon>\n',encoding='utf-8')
themed=ROOT/'android/app/src/main/res/mipmap-anydpi-v33';themed.mkdir(exist_ok=True)
(themed/'ic_launcher.xml').write_text('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/ic_launcher_background"/><foreground android:drawable="@drawable/ic_launcher_foreground"/><monochrome android:drawable="@drawable/ic_launcher_monochrome"/></adaptive-icon>\n',encoding='utf-8')
(ROOT/'android/app/src/main/res/values/brand_colors.xml').write_text(f'<resources><color name="ic_launcher_background">{GREEN}</color></resources>\n',encoding='utf-8')

# A review sheet also checks the mark at real favicon/extension sizes.
sheet=Image.new('RGB',(1600,1000),PAPER);d=ImageDraw.Draw(sheet)
regular=ImageFont.truetype(str(ROOT/'assets/fonts/DMSans.ttf'),28)
large=ImageFont.truetype(str(ROOT/'assets/fonts/DMSans.ttf'),86)
d.text((80,60),'AnkiDSA',font=large,fill=GREEN)
d.text((84,170),'KEEP WHAT YOU LEARN',font=regular,fill='#6D786F')
sheet.paste(icon(400),(90,280),icon(400))
d.rounded_rectangle((570,280,1510,680),radius=40,fill=GREEN)
sheet.paste(icon(260,inverse=True),(620,350),icon(260,inverse=True))
d.text((930,420),'AnkiDSA',font=large,fill=PAPER)
d.text((930,530),'Learn. Recall. Repeat.',font=regular,fill=MINT)
d.text((90,755),'ONE MARK. EVERY SURFACE.',font=regular,fill=GREEN)
x=100
for size,label in [(16,'16'),(32,'32'),(48,'48'),(128,'128')]:
    sheet.paste(icon(size),(x,840+(128-size)//2),icon(size))
    d.text((x,970),label,font=ImageFont.truetype(str(ROOT/'assets/fonts/DMSans.ttf'),18),fill=GREEN)
    x+=size+100
sheet.save(BRAND/'brand-preview.png')
bundle=ROOT/'build/branding/ankidsa-brand-kit.zip'
bundle.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(bundle,'w',zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(BRAND.iterdir()):
        if file.suffix in ('.svg','.png','.md'):
            archive.write(file,file.name)
    archive.write(ROOT/'assets/fonts/DMSans-LICENSE.txt','DM-Sans-LICENSE.txt')
print('Generated vector masters, brand kit, Flutter, web, extension, Android, and iOS icons.')
