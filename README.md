# GohobiStickers

GohobiStickers is a SwiftUI app for collecting stamps on the way to personal rewards. Collected stamps and upcoming goals are presented on a winding, vertical path inspired by Duolingo's progression UI.

## Features

- Choose stamps from images bundled with the app
- Add an optional comment to each stamp
- Edit or delete stamps and comments
- View the total number of collected stamps
- Set a different interval and reward name for every goal
- Add, edit, delete, and reorder goals
- Store all data locally in a JSON file
- Japanese and English localization using a String Catalog

Each goal interval is counted from the previous goal. For example, intervals of `5, 3, 2` place goals at cumulative stamp counts of `5, 8, 10`.

## Requirements

- Xcode 26.5 or later
- iOS 26.5 or later

## Getting Started

1. Open `GohobiStickers.xcodeproj` in Xcode.
2. Select your development team under Signing & Capabilities.
3. Select a run destination and run the `GohobiStickers` scheme.

## Stamp Images

Add production images to the following Image Sets in `GohobiStickers/Assets.xcassets`:

- `stamp_sun`
- `stamp_flower`
- `stamp_crown`
- `stamp_heart`
- `stamp_sparkle`
- `stamp_rainbow`

Until images are added, the app displays SF Symbols as fallbacks. Preset metadata is defined in `StampPreset.all` in `GohobiStickers/Models.swift`.

## Localization

Standard interface text is managed in `GohobiStickers/Localizable.xcstrings`. Japanese and English are currently included. Additional languages can be added through Xcode's String Catalog editor.

User-entered comments and reward names are stored and displayed exactly as entered; they are not translated.

## Local Storage

Stamps, comments, and goals are stored in `GohobiStickers/stamp-book.json` under the app's Application Support directory. The app does not require an account or send data to an external server.

## Testing

Run tests using Xcode's Test action or the following command:

```sh
xcodebuild test \
  -project GohobiStickers.xcodeproj \
  -scheme GohobiStickers \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
