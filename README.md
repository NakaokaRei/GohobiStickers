# GohobiStickers

GohobiStickers is a SwiftUI app for collecting stamps on the way to personal rewards. Collected stamps and upcoming goals are presented on a winding, vertical path inspired by Duolingo's progression UI.

## Features

- Add a stamp by tapping the next available node on the route
- Choose stamps from images bundled with the app
- Add an optional comment to each stamp
- Edit or delete stamps and comments
- View the total number of collected stamps
- Set a different interval and reward name for every goal
- Add, edit, delete, and reorder goals
- Undo a recent goal deletion
- Celebrate completed goals with animation and haptic feedback
- Choose System, Dark, or Light appearance inside the app
- Sync stamps, comments, goals, and settings through the user's private iCloud database
- Keep a local JSON copy so the app remains usable offline
- Japanese and English localization using a String Catalog

Each goal interval is counted from the previous goal. For example, intervals of `5, 3, 2` place goals at cumulative stamp counts of `5, 8, 10`.

## Requirements

- Xcode 26.5 or later
- iOS 26.5 or later

## Getting Started

1. Open `GohobiStickers.xcodeproj` in Xcode.
2. Select your development team under Signing & Capabilities.
3. Confirm that the iCloud capability uses the `iCloud.com.nakaokarei.GohobiStickers.7ZJJ7KR6WA` CloudKit container.
4. Select a run destination and run the `GohobiStickers` scheme.

## Stamp Images

Bundled artwork is stored in the following Image Sets in `GohobiStickers/Assets.xcassets/Stamps`:

- `stamp_blue_hero`
- `stamp_pink_hero`
- `stamp_frog_pink`
- `stamp_frog_blue`
- `stamp_frog_green`
- `stamp_sea_lion`
- `stamp_shell`

Presets without bundled artwork display SF Symbols as fallbacks. Preset metadata is defined in `StampPreset.all` in `GohobiStickers/Models/Models.swift`.

## Project Structure

- `App`: app entry point and root configuration
- `Models`: Codable data models and stamp preset definitions
- `Services`: CloudKit integration
- `Stores`: application state, persistence, and sync coordination
- `DesignSystem`: shared colors and stamp artwork components
- `Views`: feature-based SwiftUI screens and their components
- `Support`: localization helpers

## Localization

Standard interface text is managed in `GohobiStickers/Localizable.xcstrings`. Japanese and English are currently included. Additional languages can be added through Xcode's String Catalog editor.

User-entered comments and reward names are stored and displayed exactly as entered; they are not translated.

## Storage and iCloud Sync

Stamps, comments, goals, and appearance settings are stored in `GohobiStickers/stamp-book.json` under the app's Application Support directory and synchronized as a private CloudKit record. The local copy remains available offline. Cloud sync uses the iCloud account configured on the device, so the app does not require a separate sign-in flow or backend server.

CloudKit requires an Apple Developer Program team, an iCloud-enabled provisioning profile, and a device signed in to iCloud. Before releasing the app, deploy the CloudKit development schema to production in CloudKit Console.

To inspect `StampBook` records in CloudKit Console, add a `QUERYABLE` index for the `recordName` system field under Schema > Indexes.

## Testing

Run tests using Xcode's Test action or the following command:

```sh
xcodebuild test \
  -project GohobiStickers.xcodeproj \
  -scheme GohobiStickers \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
