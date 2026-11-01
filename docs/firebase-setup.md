# Firebase setup (accounts and cloud backup)

The app runs without Firebase. Do these steps to switch on sign-in and backup.

1. **Create a project** at https://console.firebase.google.com and add an iOS app
   (bundle id `com.foodmonitor.aiCalorieTracker`) and an Android app
   (package name from `android/app/build.gradle`, `applicationId`).
2. **Generate config files** from the project root:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This writes `android/app/google-services.json` and
   `ios/Runner/GoogleService-Info.plist`. Keep them out of public repos if the
   project is shared widely.
3. **Turn on sign-in:** Authentication > Sign-in method > Email/Password > Enable.
4. **Create the database:** Firestore Database > Create database (production mode).
5. **Publish the rules** in `firestore.rules`:
   ```bash
   npm i -g firebase-tools
   firebase login
   firebase init firestore   # choose the existing firestore.rules, keep defaults
   firebase deploy --only firestore:rules
   ```
   Or paste the file into Firestore > Rules and press Publish.
6. **Test:** run the app, open More > Account and backup, create an account,
   tap Back up now, then restore on a second device or after erasing data.

## What the rules do
- Backups live at `users/{uid}/backup/latest`.
- Only the signed-in owner can read or write them; the write is capped under 900 KB
  (Firestore's hard limit is 1 MB).
- All other paths are denied.

## Notes
- Crashlytics and Analytics are off in debug builds.
- To delete a user's data, remove their `users/{uid}` document and their
  Authentication account in the console.
