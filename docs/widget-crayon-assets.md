# Widget crayon artwork

Generated with the built-in ImageGen tool using the supplied koala design as a style reference. Transparent PNG assets are downsampled for WidgetKit memory usage.

- `GohobiStickersWidget/Artwork.xcassets/crayon_cheer.imageset/artwork.png`: Japanese celebration lettering (600 px wide).
- `GohobiStickersWidget/Artwork.xcassets/crayon_patch.imageset/artwork.png`: blank textured patch for live goal text (360 px wide).
- Dynamic numbers and labels use the rounded system font for readability. Only English celebration lettering uses [Yomogi](https://github.com/satsuyako/YomogiFont). Font and SIL OFL license are bundled in `GohobiStickersWidget/Fonts`. The font is registered through the widget's `UIAppFonts` setting. English celebration text stays live rather than displaying Japanese artwork.

## Lettering prompt

Generate a single production UI lettering asset with true transparent background. Reference image is STYLE ONLY: match the orange handwritten Japanese 'すごい！' at its top. Output ONLY the exact Japanese text 'すごい！' on one horizontal line in warm burnt orange wax crayon, irregular playful handwritten strokes, visible dry grain and speckled semi-transparent edges, gently uneven baseline, thin-to-medium loose strokes. Wide tight composition, minimal transparent padding, no koala, no numbers, no bubble, no stars, no outlines, no shadow, no white backing. This is a handwritten crayon lettering PNG for a children's reward widget. Do not typeset with a conventional font.

## Patch prompt

Create one isolated blank pale yellow-green wax-crayon scribble cloud patch, transparent background. Reference is style only: match the fluffy pale lemon yellow scribbled patch at top left of the koala drawing, but remove ALL text. An organic irregular softly scalloped blob, softly grainy dry pastel/crayon edges with tiny flecks, filled pale light yellow with visible crayon grain, flat 2D. Wide oval 3:2 aspect shape filling nearly the entire image with minimal transparent margins. No outline, no white border, no drop shadow, no speech tail, no koala, no numbers, absolutely no letters or text. Intended as a small UI background behind live readable text. Real alpha transparency outside the patch.

## Printed Medium trails (2026-10-09)

Only `medium_pink_hero` and `medium_penguin_pink` now use the user-supplied dotted-trail PNGs. Originals are 3308×1654 and 3350×1675; widget copies are 1100×550 to retain the 2:1 composition within the widget memory budget. Small and other Medium illustrations keep their existing layout.

`PrintedTrailMediumWidgetView` displays the last six stamps in chronological order using `WidgetArtwork.mediumStampCenters`. The background and overlays share one aspect-fill coordinate system. No extra trail or empty stamp rings are drawn. Pink hero travels from upper left around the right bend to lower left; penguin travels down the left trail then up the right trail.

Typography follows the supplied reference: compact reward caption, emphasized remaining number, warm gray ink, and a beige total badge. The user approved a temporary rounded substitute for 筑紫A丸ゴシック. The simulator uses `HiraMaruProN-W4`, with rounded system type as the final fallback. No proprietary font was downloaded or copied into the bundle. If a licensed Tsukushi font is supplied later, add it to the widget resources and `UIAppFonts`; the font resolver already recognizes its regular/bold PostScript names.

Official licensing reference: https://aws-prod-lets.fontworks.co.jp/services/apps-games/option

Native SwiftUI comparison captures and edge states are in `docs/widget-review`; the review is recorded in `design-qa.md`.
