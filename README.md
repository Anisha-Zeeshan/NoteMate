# NoteMate

A Flutter note-taking app with Firebase Auth, Firestore, camera/OCR capture, and offline AI.

## Project structure

```
frontend/    Flutter app (Dart)
functions/   Firebase Cloud Functions (Node.js)
```

## Setup — Frontend (Flutter)

1. Install [Flutter](https://docs.flutter.dev/get-started/install)
2. Clone this repo and open the `frontend/` folder in Android Studio or VS Code
3. Run:
   ```
   flutter pub get
   ```
4. Make sure `frontend/android/app/google-services.json` exists — if it's missing, ask a teammate with Firebase access to send it to you
5. **Download the offline AI model file** (see below — required before the app will build)
6. Run the app:
   ```
   flutter run
   ```

### Offline AI model file (required, not in this repo)

This app uses `qwen2.5-0.5b-instruct-q4_k_m.gguf` for offline AI features. It's a large binary file (300MB+), so it's excluded from Git via `.gitignore` — downloading it separately keeps the repo small and clones fast for everyone.

1. Place it at exactly: `frontend/assets/models/qwen2.5-0.5b-instruct-q4_k_m.gguf`
2. Confirm the filename matches exactly what's listed under `assets:` in `pubspec.yaml` — a mismatched name will cause a build error

Without this file in place, the app will fail to build (missing asset error), even though everything else works.

### Google Sign-In on a new machine

Google Sign-In will fail with `ApiException: 10` on any laptop whose SHA-1 fingerprint hasn't been registered in Firebase yet. If this happens to you:

1. In Android Studio: **Gradle panel → app → Tasks → android → signingReport**, copy the `SHA1` value
2. Send it to whoever has Firebase Console access
3. They add it under **Project Settings → Your apps → Add fingerprint**
4. They re-download `google-services.json` and send it to the whole team
5. Everyone replaces their local copy and does a full rebuild (not hot reload)

## Setup — Backend (Cloud Functions)

1. Install [Node.js](https://nodejs.org) and the Firebase CLI:
   ```
   npm install -g firebase-tools
   ```
2. From the `functions/` folder:
   ```
   npm install
   ```
3. Log in and deploy:
   ```
   firebase login
   firebase deploy --only functions
   ```

