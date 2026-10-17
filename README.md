# Notepad: Notes, To-Do & Memo

A fast, private, cross-platform notes app built with Flutter.

**Bundle ID:** `com.rpchauhan.notepad` · **Website:** rpchauhan.com/notepad
**Platforms:** Android (built & verified) · iOS (project ready, build requires macOS)

## Features

- 📝 Create, edit, delete, and pin notes with autosave
- 🗑️ Trash — deleted notes recoverable for 30 days, then auto-purged
- 🔍 Instant search across titles, body, and tags
- 📋 List or grid layout toggle (remembered between sessions)
- 🏷️ Colored tags/categories with one-tap filtering
- 🌗 Light / dark / system theme + 8 accent colors
- 🔤 Adjustable editor text size (12–24)
- 🔒 Privacy lock: 4-digit PIN + fingerprint/Face ID (locks when app is backgrounded)
- 📤 Export any note as **.txt**, **.pdf**, **.doc** (Word), or **.md** (Markdown)
- 📥 Import `.txt` / `.md` files as notes
- 📊 Word count, character count & reading time in the editor
- 💾 Full backup / restore as a JSON file, with a "device-only isn't a backup" reminder
- ☁️ Firebase cloud sync hook — ready to activate (see below)

## Project layout

```
notepad/
  lib/
    main.dart               # entry point + providers
    app.dart                # MaterialApp, lock gate, lifecycle
    models/note.dart        # Note model (map/JSON serialization)
    providers/              # notes, settings, lock (Provider state)
    services/
      database_service.dart # SQLite (sqflite)
      export_service.dart   # txt / pdf / doc / backup export
    screens/                # lock, home, editor, settings
    widgets/                # note card, tag chip, export sheet
    theme/app_theme.dart    # Material 3 theming
  android/  ios/             # platform shells
  assets/icon/               # launcher icons + splash art
```

## Getting started

> ⚠️ **This machine:** paths with spaces (your Windows username `R P Chauhan`)
> break Dart/Gradle tooling. The project therefore lives at **`C:\dev\Notepad\notepad`**
> with a junction at `Documents\project\Notepad`. Always run Flutter commands from
> `C:\dev\Notepad\notepad`. Flutter SDK = `C:\flutter`, Pub cache = `C:\pub-cache`.

```powershell
cd C:\dev\Notepad\notepad
flutter pub get
flutter run            # run on a connected device/emulator
flutter analyze        # lints (currently 0 issues)
flutter test           # unit tests
```

### Build commands

```powershell
flutter build apk --debug        # installable debug APK
flutter build apk --release      # signed release APK  -> build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release # Play Store bundle  -> build/app/outputs/bundle/release/app-release.aab
```

## Release signing (already configured)

- Keystore: `C:\dev\Notepad\upload-keystore.jks` — **back this up somewhere safe**
- Credentials: `notepad/android/key.properties` (git-ignored)
- Gradle reads `key.properties` automatically (see `android/app/build.gradle.kts`)

🔑 **Never lose the keystore + password.** Google Play requires every update to be
signed with the same key. Store copies of the `.jks` file and the password in a
password manager.

---

# Publishing checklist

## A. Google Play Store (Android) — do this from this PC

1. **Account**: Create a Google Account, then join [Play Console]
   (https://play.google.com/console) and pay the **$25 one-time** registration fee.
2. **Create app**: Play Console → *Create app* → name `Notepad: Notes, To-Do & Memo`,
   type *App*, free.
3. **Complete these Play Console sections** (left sidebar):
   - **Set up → App access**: declare no login required (or the PIN lock is local-only).
   - **Set up → Ads**: declare "Contains ads = No".
   - **Set up → Content rating**: questionnaire → *Tools* / *Productivity*, safe content.
   - **Set up → Target audience**: 18+ (safest for a generic utility) or as appropriate.
   - **Set up → Data safety**: required — declare: notes stored locally only; no data
     collected/shared (until Firebase sync is enabled).
   - **Set up → Privacy policy**: required. Host a simple policy page on
     rpchauhan.com/notepad/privacy and paste the URL.
   - **Set up → Store listing**:
     - Short description (80 chars max): `Notes, to-do lists & memos — fast, private, offline.`
     - Full description (4000 chars): features list from this README.
     - App icon: 512×512 PNG → `assets/icon/app_icon.png`
     - Feature graphic: 1024×500 PNG (create in Canva).
     - Screenshots: phone screenshots required (min 2, recommended 4–8). Run the app
       on your phone/emulator (light + dark), capture: home, editor, tags, lock, export.
4. **Upload**: *Production → Create new release → Upload* `app-release.aab`.
5. **Review**: new developer accounts usually pass manual review in **up to 7 days**
   (sometimes longer). Test with an internal testing track first if you prefer:
   *Testing → Internal testing →* upload same AAB, invite yourself as tester.
6. **Release**: after approval, roll out to Production.

## B. Apple App Store (iOS) — needs a Mac (or cloud CI)

⚠️ iOS builds require **macOS + Xcode**; this Windows PC cannot produce an IPA.
Two options:

**Option 1 — Codemagic (cloud, no Mac needed)**
1. Push this project to a GitHub repository.
2. Create a free account at codemagic.io, *Add app* → select the repo.
3. In App Store Connect (below), create the app record, then in Codemagic add
   *App Store Connect* integration to sign & upload automatically.
4. Free tier covers community builds; paid plan needed for more minutes.

**Option 2 — Buy/borrow a Mac**
1. Install Xcode from the Mac App Store, accept its license.
2. On this PC: `flutter build ipa` won't run — instead clone the repo on the Mac,
   run `flutter pub get`, then `flutter build ipa`.
3. Distribute via Xcode Organizer or `xcrun altool`/`notarytool`.

**Either way, Apple setup:**
1. **Account**: Join the Apple Developer Program — **$99/year**.
2. **App Store Connect** (appstoreconnect.apple.com) → *My Apps → +* → New App:
   iOS, name `Notepad: Notes, To-Do & Memo`, Bundle ID `com.rpchauhan.notepad`
   (register the identifier at developer.apple.com → Identifiers first).
3. **Metadata**: same description/screenshots as Play Store; iPhone screenshots
   required (6.7" and 6.5" sizes recommended), iPad optional.
4. **App Privacy**: declare data not collected (matches Data safety form).
5. **Review notes**: mention the PIN lock is optional and local-only.
6. Common rejection reasons to avoid: login required without demo access (N/A here),
   broken links, placeholder text. Expect first review ~24–48h.

## C. Optional: enable Firebase cloud sync

Sync needs your own (free) Firebase project — I can't create it for you:

1. Create a project at https://console.firebase.google.com (free Spark plan).
2. Add an Android app with package name `com.rpchauhan.notepad` → download
   `google-services.json` → place in `notepad/android/app/`.
3. Install FlutterFire CLI:
   ```powershell
   npm i -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Add dependencies: `flutter pub add firebase_core cloud_firestore firebase_auth`
5. Enable *Authentication → Email/Password* and *Firestore* in the Firebase console.
6. The Settings screen already shows a "Cloud sync" tile waiting for this setup.

Without it, users still have full **Backup / Restore** (Settings → Data).

## Versioning

- Version lives in `pubspec.yaml`: `version: 1.0.0+1` (name+build number).
- Play Store requires the build number to increase on every upload: `1.0.0+2`, …
  ```powershell
  flutter build appbundle --release --build-number=2
  ```

## Useful paths

| Item | Path |
|---|---|
| Release AAB (Play) | `build\app\outputs\bundle\release\app-release.aab` |
| Release APK (sideload) | `build\app\outputs\flutter-apk\app-release.apk` |
| Debug APK | `build\app\outputs\flutter-apk\app-debug.apk` |
| Keystore | `C:\dev\Notepad\upload-keystore.jks` |
| Signing credentials | `notepad\android\key.properties` (git-ignored) |
| App icon source | `assets\icon\app_icon.png` (1024×1024) |

Regenerate icons/splash after changing art:

```powershell
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
