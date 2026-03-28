# Hugo Breeze Manager (native Xcode + SwiftUI)

This repository is now a **native iOS app** that you can edit directly in **Xcode**.

Main features:

- GitHub account linking via **OAuth Device Flow**
- Connect to your Hugo blog repository (GitHub Pages)
- List markdown posts from `content/posts` (or custom path)
- Create new posts
- Edit existing posts
- Delete posts
- White/light-blue playful theme with gentle bubble + button animations

## Open and run in Xcode

1. Open `HugoBreezeManager.xcodeproj` in Xcode.
2. Select the `HugoBreezeManager` scheme.
3. Set your Signing Team and Bundle Identifier in target settings.
4. Choose your iPhone device.
5. Run.

## GitHub OAuth setup (required once)

1. GitHub -> Settings -> Developer settings -> OAuth Apps.
2. Create a new OAuth App and copy the **Client ID**.
3. In the app, paste Client ID and tap **Link GitHub**.
4. Finish device authorization in browser.

No client secret is stored in the app.

## Configure blog repository in the app

After login, set:

- Owner (username/org)
- Repository name
- Branch (usually `main`)
- Hugo content path (default `content/posts`)

Then save settings and manage posts.
