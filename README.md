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
5. Run the app:
   ```
   flutter run
   ```

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

## Team

| Name | Role |
|------|------|
| _(you)_ | Frontend |
| _(teammate)_ | Frontend |
| _(teammate)_ | Backend |

See `CONTRIBUTING.md` for branch naming and how we work together.