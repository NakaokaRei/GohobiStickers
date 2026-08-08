# GohobiStickers

[![iOS CI](https://github.com/NakaokaRei/GohobiStickers/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/NakaokaRei/GohobiStickers/actions/workflows/ios-ci.yml)

GohobiStickers is a SwiftUI app for collecting stamps on the way to personal rewards. Collected stamps and upcoming goals are presented on a winding, vertical path inspired by Duolingo's progression UI.

## Features

- Add a stamp by tapping the next available node on the route
- Choose stamps from images bundled with the app
- Add an optional comment to each stamp
- Attach one optional photo from the photo library to each stamp
- View attached photos in the stamp editor and long-press preview
- Edit or delete stamps and comments
- View the total number of collected stamps
- Add Small and Medium Home Screen widgets showing the latest stamp and progress to the next goal
- Open the new-stamp screen directly by tapping a widget
- Set a different interval and reward name for every goal
- Add, edit, delete, and reorder goals
- Undo a recent goal deletion
- Celebrate completed goals with animation and haptic feedback
- Choose System, Dark, or Light appearance inside the app
- Sync stamps, attached photos, comments, goals, and settings through the user's private iCloud database
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
4. Register the App Group `group.com.nakaokarei.GohobiStickers.7ZJJ7KR6WA` in Apple Developer, and enable it for both the app and widget App IDs.
5. Refresh the provisioning profiles for `com.nakaokarei.GohobiStickers.7ZJJ7KR6WA` and `com.nakaokarei.GohobiStickers.7ZJJ7KR6WA.widget`.
6. Select a run destination and run the `GohobiStickers` scheme once before adding the widget.

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
- `GohobiShared`: App Group snapshot and deep-link types shared by the app and widget
- `GohobiStickersWidget`: Small and Medium WidgetKit views and timeline provider
- `Stores`: application state, persistence, and sync coordination
- `DesignSystem`: shared colors and stamp artwork components
- `Views`: feature-based SwiftUI screens and their components
- `Support`: localization helpers

## Localization

Standard interface text is managed in `GohobiStickers/Localizable.xcstrings`. Japanese and English are currently included. Additional languages can be added through Xcode's String Catalog editor.

User-entered comments and reward names are stored and displayed exactly as entered; they are not translated.

## Storage and iCloud Sync

Stamps, comments, goals, and appearance settings are stored in `GohobiStickers/stamp-book.json` under the app's Application Support directory. Attached photos are normalized to JPEG (maximum 1,600 pixels on the longest edge) and stored separately in `GohobiStickers/StampImages`, so they remain available offline. The book JSON and photos are synchronized through the user's private CloudKit database. Cloud sync uses the iCloud account configured on the device, so the app does not require a separate sign-in flow or backend server.

Photo selection uses the system Photos picker and does not request broad photo-library access. Attached photos remain private to the user's iCloud account and are intentionally excluded from widgets and generated goal-sharing images.

CloudKit requires an Apple Developer Program team, an iCloud-enabled provisioning profile, and a device signed in to iCloud. Before releasing the app, deploy the CloudKit development schema to production in CloudKit Console.

To inspect `StampBook` records in CloudKit Console, add a `QUERYABLE` index for the `recordName` system field under Schema > Indexes.

The photo feature adds a private `StampImage` record type with an `asset` Asset field and a `revision` String field. Before releasing a build with photo attachments, exercise an upload in the development environment, confirm these fields in CloudKit Console, and deploy the updated development schema to production.

The widget does not read the main JSON file or CloudKit directly. The app publishes a compact snapshot to the shared App Group whenever stamps, goals, or downloaded CloudKit data change, then asks WidgetKit to refresh the timeline.

## Testing

Run tests using Xcode's Test action or the following command:

```sh
xcodebuild test \
  -project GohobiStickers.xcodeproj \
  -scheme GohobiStickers \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

GitHub Actions runs the unit and UI test suites as separate jobs for every pull request and every push to `main`. Each job uploads its `.xcresult` bundle for debugging failures.
