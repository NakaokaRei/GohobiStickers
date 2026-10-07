# Widget crayon artwork

Generated with the built-in ImageGen tool using the supplied koala design as a style reference. Transparent PNG assets are downsampled for WidgetKit memory usage.

- `GohobiStickersWidget/Artwork.xcassets/crayon_cheer.imageset/artwork.png`: Japanese celebration lettering (600 px wide).
- `GohobiStickersWidget/Artwork.xcassets/crayon_patch.imageset/artwork.png`: blank textured patch for live goal text (360 px wide).
- Dynamic numbers and labels use the rounded system font for readability. Only English celebration lettering uses [Yomogi](https://github.com/satsuyako/YomogiFont). Font and SIL OFL license are bundled in `GohobiStickersWidget/Fonts`. The font is registered through the widget's `UIAppFonts` setting. English celebration text stays live rather than displaying Japanese artwork.

## Lettering prompt

Generate a single production UI lettering asset with true transparent background. Reference image is STYLE ONLY: match the orange handwritten Japanese 'すごい！' at its top. Output ONLY the exact Japanese text 'すごい！' on one horizontal line in warm burnt orange wax crayon, irregular playful handwritten strokes, visible dry grain and speckled semi-transparent edges, gently uneven baseline, thin-to-medium loose strokes. Wide tight composition, minimal transparent padding, no koala, no numbers, no bubble, no stars, no outlines, no shadow, no white backing. This is a handwritten crayon lettering PNG for a children's reward widget. Do not typeset with a conventional font.

## Patch prompt

Create one isolated blank pale yellow-green wax-crayon scribble cloud patch, transparent background. Reference is style only: match the fluffy pale lemon yellow scribbled patch at top left of the koala drawing, but remove ALL text. An organic irregular softly scalloped blob, softly grainy dry pastel/crayon edges with tiny flecks, filled pale light yellow with visible crayon grain, flat 2D. Wide oval 3:2 aspect shape filling nearly the entire image with minimal transparent margins. No outline, no white border, no drop shadow, no speech tail, no koala, no numbers, absolutely no letters or text. Intended as a small UI background behind live readable text. Real alpha transparency outside the patch.
