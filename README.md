# Breezy Diary (iPhone Offline Journal App)

This repository contains a ready-to-use SwiftUI source implementation for an offline iPhone diary app with:

- Card-style cartoon UI
- Main color tone: light blue + white, with soft yellow accents
- Automatic current date/time recognition
- Editable date/time
- Weather selection (offline)
- Location option:
  - Use current coordinates (CoreLocation, no network required)
  - Manual location input
- Typing animation (wiggle + bounce) for playful, windy/kids feeling
- English-only in-app text

---

## Project Structure

All app source files are under:

`BreezyDiary/`

- `App/` - App entry
- `Views/` - Main screens and cards
- `Models/` - Diary and weather models
- `Services/` - Local storage and location manager
- `UI/` - Theme, button styles, text animation

---

## Run on iPhone (Xcode)

Because this repo stores source files only, create a SwiftUI iOS app shell in Xcode and drop in these files:

1. Open Xcode -> **File > New > Project...**
2. Choose **iOS > App**
3. Product Name: `BreezyDiary` (or any name)
4. Interface: **SwiftUI**, Language: **Swift**
5. Create project, then drag all files from `BreezyDiary/` into the Xcode project navigator.
6. Ensure target membership is checked for all added files.
7. In target **Info** (or `Info.plist`), add:
   - `Privacy - Location When In Use Usage Description`
   - Example value: `Used to attach current coordinates to your diary entry.`
8. Select your iPhone device/simulator and run.

---

## Notes

- Works fully offline.
- Diary entries are saved locally via `UserDefaults`.
- No backend and no internet requirement.
- Location feature uses system GPS permission only.
