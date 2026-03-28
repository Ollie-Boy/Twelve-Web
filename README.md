# Breezy Diary (iPhone Offline Journal App)

This repository now includes a complete Xcode project (`BreezyDiary.xcodeproj`) for an offline iPhone diary app.

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
- Windy animated background (floating clouds + breezy streaks)
- Adaptive layout for modern iPhone screens (including iPhone 17 class sizes)
- English-only in-app text
- Fully offline local persistence (`UserDefaults`)

---

## Project Structure

- `BreezyDiary.xcodeproj` - Ready-to-open Xcode project
- `BreezyDiary/` - App source
  - `App/` - App entry
  - `Views/` - Main screens and cards
  - `Models/` - Diary and weather models
  - `Services/` - Local storage and location manager
  - `UI/` - Theme, button styles, text animation, windy background
  - `Assets.xcassets/` - Accent color and app icon set template
  - `Info.plist` - Includes location usage description

---

## Run on iPhone 17 (Xcode)

1. Open `BreezyDiary.xcodeproj` in Xcode.
2. Select target **BreezyDiary**.
3. In **Signing & Capabilities**:
   - choose your Apple Team
   - set a unique Bundle Identifier (for example `com.yourname.BreezyDiary`)
4. Choose your **iPhone 17** device from the run destination list.
5. Build and Run (`Cmd + R`).

If prompted on first run, allow location permission to use current coordinates in entries.

---

## Notes

- Works fully offline.
- No backend and no internet requirement.
- You can keep using manual location input even if location permission is denied.
