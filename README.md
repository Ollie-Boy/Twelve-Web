# Twelve (iPhone Offline Journal App)

This repository includes an Xcode project (`Twelve.xcodeproj`) for an offline iPhone diary app.

## Implemented Features

- Cartoon card-style UI
- Light blue + white base palette with soft yellow accents
- Automatic current date/time + manual date/time editing
- Offline weather picker
- Location options:
  - Current coordinates (CoreLocation, no network required)
  - Manual location text
- Playful typing animation (wiggle + bounce)
- Entry management:
  - Create
  - Edit
  - Delete (with confirmation)
- Windy animated background (floating clouds + wind streaks)
- Adaptive layout for modern iPhone screens
- English-only in-app text
- Fully offline local persistence (`UserDefaults`)

---

## Project Structure

- `Twelve.xcodeproj` - Ready-to-open Xcode project
- `Twelve/` - App source
  - `App/` - App entry
  - `Views/` - Main screens and cards
  - `Models/` - Diary and weather models
  - `Services/` - Local storage and location manager
  - `UI/` - Theme, button styles, text animation, windy background
  - `Assets.xcassets/` - Accent color and app icon set template
  - `Info.plist` - Includes location usage description

---

## Run in Xcode

1. Open `Twelve.xcodeproj` in Xcode.
2. Select target **Twelve**.
3. In **Signing & Capabilities**:
   - choose your Apple Team
   - set a unique Bundle Identifier (for example `com.yourname.Twelve`)
4. Choose your device from the run destination list.
5. Build and Run (`Cmd + R`).

If prompted on first run, allow location permission to use current coordinates in entries.

---

## Notes

- Works fully offline.
- No backend and no internet requirement.
- You can keep using manual location input even if location permission is denied.
