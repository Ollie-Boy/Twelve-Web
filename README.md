# Hugo Breeze Manager (iPhone app starter)

A fresh mobile app repository built with Expo + React Native + TypeScript.

This app is designed for iPhone use and lets you:

- Link your GitHub account (device login flow)
- Connect to a Hugo blog repository used for GitHub Pages
- List markdown posts from `content/posts` (or custom path)
- Create new posts
- Edit existing posts
- Delete posts

UI style: white + light-blue, playful/cute animations.

## Quick start

```bash
npm install
npm run start
```

Scan the QR code in Expo Go on your iPhone.

## GitHub setup (required once)

1. Go to GitHub Developer Settings -> OAuth Apps.
2. Create a new OAuth App.
3. Copy the **Client ID**.
4. In the app login screen, paste the Client ID and tap **Link GitHub**.
5. Complete device authorization in browser.

No client secret is stored in the mobile app.

## Repo settings in app

After login, configure:

- Owner (GitHub username or org)
- Repository name
- Branch (usually `main`)
- Hugo content path (default `content/posts`)

Then save settings and manage posts.

## Notes

- The app uses GitHub Contents API and commits directly to your repo.
- For private repos, make sure your OAuth token has repo access.
