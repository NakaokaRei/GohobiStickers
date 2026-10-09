# Medium widget design QA — 2026-10-09

final result: passed

Scope: only the pink hero and pink penguin Medium designs. The user explicitly accepted a temporary rounded font instead of unlicensed Tsukushi A Round Gothic.

## Visual targets and rendered evidence

- Pink hero source: `/Users/nakaokarei/Downloads/pinkheroフチ濃いめ_widget_その2_破線.png` (3308×1654).
- Pink hero composition reference: `/Users/nakaokarei/Downloads/pinkheroフチ濃いめ_widget_その2_破線 の案.png` (3308×1654).
- Penguin source: `/Users/nakaokarei/Downloads/ペンギンえへpink1_widget_その2_破線.png` (3350×1675). No text-layout mock was supplied for this character; its open top center is used for the reward text, with the total on the lower belly.
- Production source: `GohobiStickersWidget/PrintedTrailMediumWidgetView.swift` and `WidgetArtwork.swift`.
- Rendering: the actual production SwiftUI component, compiled into an isolated simulator review host; `ImageRenderer` at 3× density. The rendering harness is preserved at `docs/widget-review/ReviewHarness.swift` (not part of app targets).
- Reference-state viewport: 364×182 pt → 1092×546 px, matching the supplied 2:1 canvas. Input art is normalized to 1092×546 in comparison boards. Native points, not CSS pixels.
- Widget-shaped viewport: 364×170 pt → 1092×510 px; smaller viewport: 320×148 pt → 960×444 px. Aspect-fill crops the image and overlays together.
- Main state: total 39, remaining 36, six chronological stamps. The no-history reference capture intentionally hides history to compare the supplied text-only mock at the same count/state.
- Full-view evidence: `docs/widget-review/comparison-final.png`, `penguin-comparison.png`.
- Focused typography evidence: `docs/widget-review/typography-comparison.png` (source above implementation, identical normalized region). Shows the approved font substitution explicitly.
- Native simulator screenshot: `docs/widget-review/native-preview.png`; cropped presentation: `preview.png`. This is a SwiftUI review host with widget-size rounded clips, not a SpringBoard WidgetKit capture.
- Edge states: `edge-states.png`, `edge-states-final.png`, individual `*-empty.png`, `*-no-goal.png`, `*-large-count.png`.
- English verification: `docs/widget-review/en/pink_hero-history.png`, `en/penguin_pink-large-count.png`.

## Findings and iteration history

1. **[P2, fixed] Typography too large and surrounding words too low.**
   `comparison-v1.png` showed a wider caption and taller number than the reference; “あと” and “こ” sat on the number's bottom baseline. Reduced caption/number/total sizes, adjusted tracking and raised the small words. `comparison-v2.png` and the final focused comparison confirm the intended hierarchy and placement.
2. **[P2, fixed] Grouped numbers lost emphasis.**
   `edge-states.png` showed 12,345 entirely at caption size because plain `String(count)` did not match the localized number in the sentence. The numeric substring now uses the same localized integer formatting. `edge-states-final.png` confirms the number remains emphasized and fits at 320×148 pt. The English total uses a compact localized label to avoid compressing a long sentence into the small badge.
3. **Approved deviation: font family.**
   No Tsukushi font is installed in the simulator. `fonts.txt` verifies `HiraMaruProN-W4`. Its strokes and numeral shapes are thinner/more regular than the reference. This is the user's approved temporary substitution, not an exact font match. A licensed Tsukushi file can later be bundled/registered without changing layout code.
4. **[P3] Badge outline.**
   The total badge uses a smooth capsule; the reference has a subtly irregular outline. Color, location and dimensions match closely. Minor shape polish remains optional.

## Required fidelity checks

- **Typography:** checked full-view and close-up. Warm gray, caption/number hierarchy, raised small words, one-line fitting and localized grouping verified. Approved font difference documented above.
- **Layout rhythm:** reference placement reproduced in normalized artwork coordinates; one aspect-fill transform keeps stamps on the printed paths. Six existing stamps only; no empty rings or extra dashed roads. No character-face or text collisions in both viewport sizes.
- **Colors:** supplied image backgrounds preserved. Text uses warm gray (0.46, 0.41, 0.41); total badge muted beige (0.80, 0.76, 0.66). No unrelated contrast panels added.
- **Image quality:** both actual user PNGs used at 1100×550. Character crop and printed trails preserved, no regenerated illustrations. Existing circular stamp art retains complete figures.
- **Copy/content:** Japanese caption, remaining count, total, empty history and no-goal prompt checked; English short labels fit. Real snapshot counts and chronological history drive the production view. Reference counts exist only in the review harness.

## Validation and limits

- Xcode 26.5 (the repository CI version), iOS 26.5 simulator: **30 unit tests passed**. Includes widget snapshot/history and bundled stamp-asset tests. Result: `/tmp/gohobi-widget-build-265/Logs/Test/Test-GohobiStickers-2026.10.09_20-21-20-+1300.xcresult`.
- App + widget compile successfully. `git diff --check` passes.
- Initial Xcode 27.2 beta test build failed on existing `FakeCloudSyncService`/`CloudSyncing` actor conformance. Using the repository's Xcode 26.5 resolved that compiler difference. A signing-disabled test launch also lacked required CloudKit entitlements; normal simulator signing resolved it. No unrelated concurrency or CloudKit source changes were made.
- Visual review covers the production view in a native review host. Home Screen tint modes and live timeline refresh were not exercised; those paths were unchanged.
- Existing unrelated app/UI-test edits in the working tree were retained.

## Implementation checklist

- [x] Replace only two Medium image assets.
- [x] Remove generated road/empty rings for these printed-trail designs.
- [x] Place actual history stamps on the artwork's paths.
- [x] Match reference caption, large number, warm palette and total placement.
- [x] Verify Japanese/English, no history, no goal and five-digit counts.
- [x] Recapture and compare after visual fixes.
- [x] Build and run the repository's unit tests.

## Follow-up: restore stamp borders

The user clarified that the placed stamps must keep their circular borders. Restored the original Medium widget's outer 1.3 pt border, subtle inner 0.7 pt ring, translucent backing and inset artwork on both printed-trail variants. Only the road itself is supplied by the background; no empty stamp rings are added. `docs/widget-review/borders-restored.png` shows both production components re-rendered with six stamps and reviewed for clipping/alignment. `native-preview.png` and `preview.png` now show this corrected version; earlier comparison boards record the prior iterations. Xcode 26.5 app/widget build and `git diff --check` passed after this visual-only correction.
