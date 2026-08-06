# Releasing Nyro

What has to be true before an upload, and the two steps only you can do.

Written 2026-08-06, the day the app was rebranded from `music_app` to **Nyro**
and pointed at production.

---

> **Also read `mvp_push.md`.** Background playback, the media notification and the
> lock-screen controls were added on 2026-08-06 and are **code complete but not yet
> device-tested**. That work touches the Android manifest, `MainActivity.kt` and
> `Info.plist`, so it changes what an upload contains. Do not ship before its device
> pass has been run and recorded.

## The two blockers

### 1. The keystore does not exist yet

`android/app/build.gradle` now reads its release signing from
`android/key.properties`, which is gitignored. Until that file and its keystore
exist, `flutter build apk --release` fails on purpose:

```
SigningConfig "release" is missing required property "storeFile".
```

That failure is the feature. The previous config signed release builds with the
**debug** key, which the Play Console rejects on upload — debug keys are public,
so an app signed with one is an app anyone can forge an update for. Failing
loudly beats discovering it at review.

Generate the key (from the `android/` directory):

```bash
keytool -genkey -v -keystore nyro-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias nyro
```

Then copy `android/key.properties.example` to `android/key.properties` and fill
in the four values.

> **Back the `.jks` up somewhere private and permanent.** This key is how Google
> identifies Nyro for the life of the app. Lose it and you cannot ship an update
> ever again, under any account — the only route is a new listing with a new
> id, starting from zero installs. Losing it is worse than losing the source.

Verify with `flutter build appbundle --release`. The Play Store wants the
`.aab`, not the `.apk`.

### 2. The favourites backend fix is still undeployed

`../music_apis/migration_user_fav_uuid.sql` plus 5 PHP files have been finished
and sitting undeployed since 2026-08-06. `user_fav.user_id` is `INT UNSIGNED`
while the app sends a uuid, so MySQL silently coerces every write into a
garbage bucket **while the API answers `success: true`**.

Ship the app without this and every user's favourites appear to save and then
come back empty, with nothing in the logs to explain it. See "Out-of-band
fixes" in `claude_code_prompt.md`.

---

## What the rebrand touched

`Nyro` is now the name everywhere a user can see one. The Dart package is still
`music_app` — it is the import prefix on every file in `lib/`, and renaming it
would touch every file to change nothing a user perceives.

| Surface | Value |
|---|---|
| Android launcher | `android:label="Nyro"` |
| iOS home screen | `CFBundleDisplayName` / `CFBundleName` |
| Android task switcher | `GetMaterialApp.title`, from `kAppName` |
| Settings → About, licences page | `kAppName` |
| Web tab, PWA install | `web/index.html`, `web/manifest.json` |
| Play Store id | `applicationId = "com.nyro.app"` — **permanent** |

`kAppName` and `kAppVersion` both live in
`lib/controller/settings_controller.dart`. **`kAppVersion` is hand-kept against
`pubspec.yaml`'s `version:` line and nothing checks the two agree** — bump both
together or About starts lying.

`namespace` in build.gradle stays `com.shubha.music`: it matches the Kotlin
source tree under `src/main/kotlin/com/shubha/music/`, and it is invisible to
users. Only `applicationId` is permanent and public, and that one is the
brand's.

### Icons

Generated from `ChatGPT Image Aug 4, 2026, 10_42_33 PM.png`, using **only the
N-note mark** — the wordmark and tagline are illegible at 48dp.

- Android legacy mipmaps, all five buckets
- Android **adaptive** icon (`mipmap-anydpi-v26/ic_launcher.xml`) with a
  transparent foreground over `@color/brand_black`. Without this, Android 8+
  launchers shrink the square icon inside a white backdrop
- iOS `AppIcon.appiconset`, opaque RGB — the App Store rejects icons with an
  alpha channel
- `android/play_store_icon_512.png` for the listing
- Web favicon and PWA icons, maskable pair with extra padding

The splash screen was also fixed: it was `@android:color/white` and
`?android:colorBackground` under a `Theme.Light` parent, so a **dark-only app
opened with a full white flash** on any light-mode phone. Both variants are
`@color/brand_black` now with the mark centred.

---

## New: the foreground-service declaration

`mvp_push.md` added four permissions to the manifest, and one of them needs paperwork:

**`FOREGROUND_SERVICE_MEDIA_PLAYBACK` requires a Foreground Service declaration in
the Play Console.** Since Android 14, Google Play asks every app declaring a
foreground service type to explain in the listing what it is for, and typically to
supply a short screen recording showing the feature. Nyro's answer is
straightforward — a music player continuing playback with the screen off is the
textbook `mediaPlayback` case — but the form is not optional, and an upload that
skips it is rejected.

The other three (`WAKE_LOCK`, `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`) are
routine and need no declaration.

Note this cuts against the section below, which removed permissions precisely to
avoid declaration forms. The trade is different here: those bought nothing, and this
one buys the app's single most important behaviour.

## Also changed for store review

Two permissions were removed from `AndroidManifest.xml` because nothing in
`lib/` used them:

- `READ_EXTERNAL_STORAGE`
- `READ_MEDIA_AUDIO`

Both are "sensitive" on the Play Console — they trigger a declaration form and
are a routine rejection cause. Every track is streamed from the API; nothing
opens a local file. If local playback is ever added, bring back
`READ_MEDIA_AUDIO` (API 33+) with `READ_EXTERNAL_STORAGE` capped at
`maxSdkVersion="32"`.

`android:usesCleartextTraffic="true"` was removed too. It permitted plain HTTP
app-wide and there is none: `apis/all_urls.dart` builds every URL from an https
host, and both the stream (`song_controller.dart`'s `setUrl`) and the cover art
are relative paths prefixed with it. **If playback or artwork ever breaks after
a server move, check this first** — pointing the app at an http host now
requires putting this back.

---

## Worth doing, not blocking

- **`minifyEnabled` is deliberately off.** Flutter already AOT-compiles and
  tree-shakes the Dart half; R8 would only shrink the thin plugin layer, and a
  missing keep-rule crashes release builds *only*. Not a switch to flip on
  upload day. Revisit with a `proguard-rules.pro` and a release build exercised
  on a device.
- **~560 KB of unused mock covers still ship** — `pubspec.yaml` globs all of
  `assets/`. See "Known weak points" in `progress.md`.
- ~~**No Dio timeouts.**~~ Done — see `mvp_push.md` Phase 3. One shared `Dio` in
  `apis/all_urls.dart` at 10s connect / 15s receive / 10s send.
- **`db_secret.php` is committed** in `../music_apis/`. Check what is in it
  before that repo goes anywhere public.
- **No crash reporting.** Once real users have it, a release-only crash is
  invisible without one.
