import os
import json
from PIL import Image, ImageDraw

src_logo_path = r'C:\Users\DELL\.gemini\antigravity-ide\brain\2a3f6839-f901-406e-ba38-3ba30348ea08\.user_uploaded\media_1789501860499.png'
raw_logo = Image.open(src_logo_path).convert('RGBA')

bg_color = (20, 34, 21, 255)  # #142215 official dark green security theme

# Create Master 1024x1024 Square Icon
master_size = 1024
master_icon = Image.new('RGBA', (master_size, master_size), bg_color)
logo_target_w = 800
scale = logo_target_w / raw_logo.width
logo_target_h = int(raw_logo.height * scale)
logo_resized = raw_logo.resize((logo_target_w, logo_target_h), Image.Resampling.LANCZOS)
x_off = (master_size - logo_target_w) // 2
y_off = (master_size - logo_target_h) // 2
master_icon.paste(logo_resized, (x_off, y_off), logo_resized)

# Create Master 1024x1024 Round Icon
master_round = Image.new('RGBA', (master_size, master_size), (0, 0, 0, 0))
mask = Image.new('L', (master_size, master_size), 0)
draw = ImageDraw.Draw(mask)
draw.ellipse((0, 0, master_size - 1, master_size - 1), fill=255)
master_round.paste(master_icon, (0, 0), mask)

# Create Adaptive Foreground (Centered within safe 64% zone for Android masking)
fg_master = Image.new('RGBA', (master_size, master_size), (0, 0, 0, 0))
fg_target_w = 640
fg_scale = fg_target_w / raw_logo.width
fg_target_h = int(raw_logo.height * fg_scale)
fg_resized = raw_logo.resize((fg_target_w, fg_target_h), Image.Resampling.LANCZOS)
fg_x = (master_size - fg_target_w) // 2
fg_y = (master_size - fg_target_h) // 2
fg_master.paste(fg_resized, (fg_x, fg_y), fg_resized)

# Save Master Assets
os.makedirs('assets/icons', exist_ok=True)
master_icon.save('assets/icons/dociscan_icon.png', 'PNG')
master_round.save('assets/icons/dociscan_icon_round.png', 'PNG')
fg_master.save('assets/icons/dociscan_icon_foreground.png', 'PNG')
print('[OK] Master assets created in assets/icons/')

# 1. Android Icons
android_densities = {
    'mipmap-mdpi': {'legacy': 48, 'fg': 108},
    'mipmap-hdpi': {'legacy': 72, 'fg': 162},
    'mipmap-xhdpi': {'legacy': 96, 'fg': 216},
    'mipmap-xxhdpi': {'legacy': 144, 'fg': 324},
    'mipmap-xxxhdpi': {'legacy': 192, 'fg': 432},
}

for folder, sizes in android_densities.items():
    dir_path = os.path.join('android/app/src/main/res', folder)
    os.makedirs(dir_path, exist_ok=True)

    # Legacy Square Icon
    legacy_size = sizes['legacy']
    icon_resized = master_icon.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS)
    icon_resized.save(os.path.join(dir_path, 'ic_launcher.png'), 'PNG')

    # Legacy Round Icon
    round_resized = master_round.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS)
    round_resized.save(os.path.join(dir_path, 'ic_launcher_round.png'), 'PNG')

    # Adaptive Foreground
    fg_size = sizes['fg']
    fg_res = fg_master.resize((fg_size, fg_size), Image.Resampling.LANCZOS)
    fg_res.save(os.path.join(dir_path, 'ic_launcher_foreground.png'), 'PNG')

# Android mipmap-anydpi-v26 XMLs
anydpi_dir = 'android/app/src/main/res/mipmap-anydpi-v26'
os.makedirs(anydpi_dir, exist_ok=True)

xml_content = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""

with open(os.path.join(anydpi_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
    f.write(xml_content)

with open(os.path.join(anydpi_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
    f.write(xml_content)

# Android values/colors.xml
values_dir = 'android/app/src/main/res/values'
os.makedirs(values_dir, exist_ok=True)
with open(os.path.join(values_dir, 'colors.xml'), 'w', encoding='utf-8') as f:
    f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#142215</color>
</resources>
""")

print('[OK] Android launcher and adaptive icons generated.')

# 2. iOS AppIcon Catalog
ios_icons = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

ios_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
os.makedirs(ios_dir, exist_ok=True)
for filename, size in ios_icons.items():
    out_img = master_icon.resize((size, size), Image.Resampling.LANCZOS)
    out_img.save(os.path.join(ios_dir, filename), 'PNG')

print('[OK] iOS AppIcon assets generated.')

# 3. Web & PWA Icons
web_dir = 'web'
web_icons_dir = 'web/icons'
os.makedirs(web_icons_dir, exist_ok=True)

# Favicon 64x64
favicon = master_icon.resize((64, 64), Image.Resampling.LANCZOS)
favicon.save(os.path.join(web_dir, 'favicon.png'), 'PNG')

# PWA icons
master_icon.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-192.png'), 'PNG')
master_icon.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-512.png'), 'PNG')
master_round.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-maskable-192.png'), 'PNG')
master_round.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-maskable-512.png'), 'PNG')

print('[OK] Web and PWA icons generated successfully.')
