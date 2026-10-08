# Branding assets

Picklog uses the Pickforge product mark family. The mark is a 128×128 frame
(radius 24) on `#0A0A0B` with three off-white L brackets. The top-right corner
is replaced by one ember dot. Faint dashed connectors join the brackets. A
small log glyph (two entry lines and a check) sits in the centre.

The SVG files are the source of truth. The PNGs are rasterized from them.
The in-app mark (`lib/core/widgets/brand_mark.dart`) draws the same geometry,
so update both together.

## Files

| File | Used for |
|------|----------|
| `picklog-mark.svg` | Canonical dark mark |
| `picklog-mark-light.svg` | Mark on cream (light mode, print) |
| `picklog-mark-mono.svg` | Single colour contexts |
| `picklog-app-icon.svg` | Source of `icon.png` (full-bleed square; iOS and Android apply their own corner mask) |
| `picklog-icon-foreground.svg` | Source of `icon_foreground.png` (Android adaptive foreground, glyph inside the 66dp safe circle) |
| `picklog-splash.svg` | Source of `splash_logo.png` (dark native splash) |
| `picklog-splash-light.svg` | Source of `splash_logo_light.png` (cream native splash) |
| `google_g.svg` | Google sign-in button logo |

All PNGs are 1024×1024.

## Regenerate

1. Rasterize the sources:

   ```bash
   cd assets/branding
   rsvg-convert -w 1024 -h 1024 picklog-app-icon.svg -o icon.png
   rsvg-convert -w 1024 -h 1024 picklog-icon-foreground.svg -o icon_foreground.png
   rsvg-convert -w 1024 -h 1024 picklog-splash.svg -o splash_logo.png
   rsvg-convert -w 1024 -h 1024 picklog-splash-light.svg -o splash_logo_light.png
   ```

2. Regenerate the platform assets:

   ```bash
   fvm dart run flutter_launcher_icons
   fvm dart run flutter_native_splash:create
   ```

3. `flutter_launcher_icons` 0.14 rewrites
   `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` in
   `ios/Runner.xcodeproj/project.pbxproj`. Revert that line before you commit.
4. Commit the regenerated files under `android/`, `ios/` and `web/`.

Config for both tools lives in `pubspec.yaml`. The launcher and dark splash
background is `#0A0A0B`; the light splash is cream `#FAFAF7`. The web loading
screen in `web/index.html` uses the same colours and follows the system theme.
Colour tokens live in `lib/core/theme/picklog_colors.dart`.

## Rules

Keep the brackets off-white (`#F2F2F3`), never pure white. The ember is a solid
`#FF7A1A` dot (`#E5610A` on cream) with no gradient. Do not rotate, outline or
decorate the mark.
