# AI Agent — Project Context & Master Guide

**Project:** السراج في بيان غريب القرآن — an **offline-first, 100% no-internet** Flutter app (Arabic, RTL, Amiri font) that shows the book's scanned pages as images, with live text search, a glossary-verification screen (image + word list side by side), and a quiz mode.

Read this file end-to-end before touching the code. It covers architecture, automation scripts, versioning rules, signing/security, environment quirks, and the git workflow. This repo has many customizations — do not assume standard Flutter conventions apply.

> **MAINTENANCE CONTRACT (mandatory):** This file is the project's living context. Every time the project changes — code, scripts, commands, versioning, signing, assets, structure, tooling, workflows, or any quirk/decision — update this file in the same pass (add, modify, or delete sections to match reality). Never let it go stale. **Never delete this file.**

---

## 1. LIVE SNAPSHOT (always re-verify — it drifts)

Run these first; they override anything below:

```powershell
cd C:\Users\devtips\Documents\pdf-to-images\quran-app
git status --short                  # pending changes
Select-String pubspec.yaml -Pattern '^version:'   # current version (source of truth)
C:/flutter/bin/flutter --version
```

Snapshot at time of writing:
- App version: **`1.1.0+3`** (`pubspec.yaml:19`)
- Flutter: **3.47.5 stable**, installed at `C:/flutter` (NOT on PATH — always call `C:/flutter/bin/flutter(.bat)`)
- Latest commits (newest first): `f2c8780` (developer console menu), `7603bdd` (control center + bump to 1.1.0), `8ff2bf7` (dropped home-header stats, deleted stray `log.json`)

---

## 2. REPOSITORY & HOSTING

- App folder: `C:\Users\devtips\Documents\pdf-to-images\quran-app\`
- **Git repo root is the PARENT**: `C:\Users\devtips\Documents\pdf-to-images\`. Git commands run inside `quran-app` print paths prefixed `quran-app/...`. A sibling `pages/` folder (repo root) is the raw data for assets.
- Remote: **https://github.com/AnassAzeroual/Gharib_Qoran_App.git**
- **The repo is PUBLIC.** Never commit or print: signing keys, `key.properties`, keystore passwords, any secret.
- History was once rewritten (`filter-branch`) to purge a leaked keystore. Never restore old blobs/branches that contained `upload-keystore.jks` or `key.properties`.

---

## 3. ENVIRONMENT (Windows 11, PowerShell 5.1)

| Tool | Path | Notes |
|---|---|---|
| Flutter | `C:/flutter/bin/flutter.bat` | 3.47.x stable; not on PATH |
| Dart | `C:/flutter/bin/dart.bat` | |
| Inno Setup | `$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe` | compiles `installer/AlSiraj.iss` |
| adb | `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe` | |
| apksigner | `$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat` | |
| keytool | `C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot\bin\keytool.exe` | |
| Python | `python` on PATH | used by `sync_resources.py` |
| Android SDK | `C:\Users\devtips\AppData\Local\Android\Sdk` | `ANDROID_HOME` may be unset; scripts fall back to `%LOCALAPPDATA%\Android\Sdk` |
| Phone | serial example `R5CY42DCQAX` | check `adb devices`; not always plugged in |

USB flow: developer options on the phone; `adb devices` must show state `device`. Samsung install "success" can silently fail when signatures differ — the scripts force the real error.

---

## 4. VERSIONING SYSTEM — read first, get this RIGHT

**Exactly one source of truth:** `pubspec.yaml` → `version: X.Y.Z+N`
- `X.Y.Z` = semantic version, shown in the app header
- `+N` = Android `versionCode` AND the Windows exe build number

Three files must always agree (never drift):

| File | Pattern |
|---|---|
| `pubspec.yaml` | `version: 1.1.0+3` |
| `lib/version.dart` | `const String kAppVersion = '1.1.0';` |
| `installer/AlSiraj.iss` | `#define MyAppVersion "1.1.0"` |

Rules:
- **Bump, THEN build, THEN install.** The version is frozen into the binary at build time. Bumping sources does not change an installed app until `build_install.ps1` runs.
- Android `versionName` = `X.Y.Z`; `versionCode` = `N`. `+N` MUST increase for every Google Play upload.
- Windows exe file-version derives from pubspec automatically (`FLUTTER_VERSION` injected by CMake into `windows/runner/CMakeLists.txt`). Do NOT hand-edit `Runner.rc` fallback values.
- **Never edit the three version files by hand — use `bump_version.ps1`.**
- The header version label (`appVersionLabel()` in `lib/version.dart`) is intentionally always Western digits (`1.0.2`), even when the app numeral toggle is Arabic-Indic.

---

## 5. AUTOMATION SCRIPTS (all in `quran-app/`)

### 5.1 `alsiraj.ps1` — the control center (interactive menu)
Right-click → **Run with PowerShell**. Shows current version and a FLAT 11-option menu:

```
 1 Bump version                      6 Run Windows (dev, flutter run)
 2 Build Windows release + install   7 Run Chrome (dev)
 3 Build Android release + USB       8 Flutter DevTools
 4 Build Android debug + USB         9 Google Play Console (browser)
 5 Build Android AAB (Play)         10 Project PowerShell prompt
                                    11 VS Code in project
 Q Quit
```

- Every job opens in its **own console window** (`Start-Process powershell -NoExit -WorkingDirectory $ProjectRoot`), so the menu stays responsive.
- Option 8 (DevTools): the standalone `devtools` pub package is RETIRED (dead since 2022, can't resolve on Dart 3). DevTools is built into `flutter run` — menu launches the app (W=Windows / C=Chrome) and tells the user to press `d`.

### 5.2 `build_install.ps1` — one-command build/install
```
.\build_install.ps1                          # default: Windows AND Android release
.\build_install.ps1 -Windows                 # Windows only
.\build_install.ps1 -AndroidRelease          # signed release APK + USB install
.\build_install.ps1 -AndroidDebug            # debug APK + USB install
.\build_install.ps1 -Aab                     # release AAB for Play (no install)
.\build_install.ps1 -NoLaunch                # install without launching
.\build_install.ps1 -SkipAndroid             # (legacy) same as -Windows
```
Flow (logged to `installer\build_install.log`):
1. Stop a running AlSiraj process (if it is a Windows job).
2. **Sync resources**: runs `python sync_resources.py` when python exists (skips gracefully otherwise).
3. Windows: `flutter build windows --release` → `ISCC` compile → silent uninstall old (`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`) → install → verify exe exists → launch (unless `-NoLaunch`).
4. Android: builds `app-release.apk` (arm64+arm, slim ~64MB) or `app-debug.apk`; if a device is connected (`adb devices` state `device`), `adb install -r`. **On signature-mismatch install failure, it automatically uninstalls the app and retries** (needed after the 2025 key rotation).
5. AAB: builds `app-release.aab` only.
- **UAC self-elevation** happens ONLY for Windows installs; Android-only jobs run without admin. Flags are forwarded through the elevated relaunch.

### 5.3 `bump_version.ps1` — the only sanctioned version editor
```
.\bump_version.ps1 -Patch [-Build]        # 1.0.1 -> 1.0.2 (+N ticks with -Build)
.\bump_version.ps1 -Minor  [-Build]       # 1.0.2 -> 1.1.0
.\bump_version.ps1 -Major  [-Build]       # 1.1.0 -> 2.0.0
.\bump_version.ps1                        # interactive prompts (right-click friendly)
```
Behavior:
- Reads `pubspec.yaml`, **verifies** `version.dart` and `AlSiraj.iss` match first (throws on drift).
- Only ONE of `-Patch/-Minor/-Major` allowed. `-Build` ticks `+N` (required for Play uploads; without it `+N` stays).
- No flags = interactive mode (asks patch/minor/major + build-tick, pauses at end) so right-click works.
- Writes files with exact `.Replace()` on full lines — never hand-edit siblings.

---

## 6. DATA & ASSET PIPELINE

Raw book data lives in the repo-root sibling folder:
`C:\Users\devtips\Documents\pdf-to-images\pages\` — per-page PNG + JSON, and `menu.json` (canonical surah order/names/classification/word counts).

`quran-app\sync_resources.py`:
- Copies `pages/*.png` → `assets/images/`, page JSONs → `assets/json/` (337 pages), regenerates `assets/surah_index.json` (114 surahs), `assets/thumun-menu.json`, `assets/search_index.json`.
- Source fallback: local absolute path first, else `../pages` (works on other machines/CI).
- "0 copied" is normal when sources already match assets.

Generated asset files are **gitignored**; to snapshot them into git (not normally needed) use `git add -f`. Only declare real assets in `pubspec.yaml` (`assets/images/`, `assets/json/`, `assets/sounds/`, plus the three index files) — `log.json` at `quran-app\` is stray junk (deleted).

---

## 7. CODEBASE MAP

```
lib/
├── main.dart                          entry point; RTL + Amiri font setup
├── theme.dart                         light/dark mode; menuModeNotifier (surah/hizb)
├── version.dart                        kAppVersion + appVersionLabel()
├── data/                               static lists (kQuranSurahs, etc.)
├── models/                             page_data.dart, hizb_menu.dart, quiz_word.dart
├── screens/                            home, page_viewer, verification, quiz*, search_*, hizb_*
├── services/                           data_service, search, arabic_normalizer, quiz_service, sound_service, ayah_highlighter
├── utils/                              arabic_digits.dart (displayNumber), etc.
└── widgets/                            search_result_card, numeral_toggle_button, ...
```

Key conventions:
- Identifiers/comments in English; **all UI strings Arabic** (RTL).
- `displayNumber()` (`utils/arabic_digits.dart`) converts digits per the app-wide numeral toggle — EXCEPT the version label, which must stay Western.
- Search matches `*_normalized` JSON fields with a normalizer that strips diacritics and unifies alef.
- Fonts: Amiri (bundled `assets/fonts/`). Theme colors: teal gradient header `0xFF0F766E → 0xFF134E4A`, accent gold `0xFFFCD34D`, dark background `0xFF16191F`.
- App/package id: **`com.siraj.alsiraj`** (Android). Windows binary: `AlSiraj.exe`.

Verification (`test/widget_test.dart`) has a KNOWN pre-existing failure (`pumpAndSettle` timeout) — do not chase it; it fails before your changes too.

---

## 8. SIGNING & SECURITY (public repo — critical)

| Item | Value |
|---|---|
| Keystore | `android/app/upload-keystore.jks` (CN=Siraj App, OU=Mobile, O=Siraj, C=MA, 10000 days, 2048-bit RSA) |
| Alias | `upload` |
| Config | `android/key.properties` (storeFile, storePassword, keyAlias, keyPassword) |
| Cert SHA-256 | `ca438e3d826a9bc31cfcf0424f39f138a5dfbc3f51bb02b12880bfb7cc1d71c6` |

- **Both files are gitignored** (`.gitignore`: `android/key.properties`, `android/app/*.jks`, `android/app/*.keystore`; repo-root `.gitignore` also has `alsiraj-signing-backup/`).
- `android/app/build.gradle.kts` reads signing from `android/key.properties` automatically; `storeFile` resolves relative to `android/app/`.
- If `key.properties` is missing, release builds silently downgrade to debug signing — Play rejects those. Check files exist before building.
- Backup strategy: `alsiraj-signing-backup/` at repo root + **MEGA** (E2E-encrypted, 2FA + recovery key). Losing these keys = unable to update the app ever.
- New-machine restore: copy the two files from backup into place, then `git status` must show neither file.
- NEVER put the password in README, code, or chat logs (it is only inside `key.properties`).

---

## 9. INSTALLER (Inno Setup / Windows)

- `installer/AlSiraj.iss` is tracked source (keep it). It is 64-bit aware (`ArchitecturesAllowed=x64compatible`, `ArchitecturesInstallIn64BitMode=x64compatible`) → installs to `C:\Program Files\AlSiraj\AlSiraj.exe`.
- Generated: `installer/AlSiraj-Setup.exe` and `installer/build_install.log` are **gitignored** and untracked (the `AlSiraj-Setup.exe` was removed from git — do not re-add).
- If `flutter build windows` behaves oddly after a rename, `flutter clean` or delete `build/windows` (CMake caches old names).

---

## 10. BUILD OUTPUTS

| Platform | File |
|---|---|
| Android APK | `build/app/outputs/flutter-apk/app-release.apk` (~64MB with `--target-platform android-arm64,android-arm`) |
| Android debug | `build/app/outputs/flutter-apk/app-debug.apk` |
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` |
| Windows | `build/windows/x64/runner/Release/AlSiraj.exe` |
| Web | `build/web/index.html` |

Verify signing: `apksigner verify --print-certs "…\app-release.apk"` (expect CN=Siraj App). Verify exe version: `(Get-Item 'C:\Program Files\AlSiraj\AlSiraj.exe').VersionInfo.FileVersion` (expect `X.Y.Z+N` matching pubspec).

---

## 11. GIT WORKFLOW

- Commit paths under the repo root get the `quran-app/` prefix in messages/status.
- Commit ONLY when the user asks. Inspect `git status`, `git diff`, `git log --oneline -10` first.
- Never amend/hook-skip/force-push unless told; history was force-rewritten once — avoid adding noise.
- Generated binaries (`build/`, `*.apk`, `*.aab`, `AlSiraj-Setup.exe`, `build_install.log`) are ignored; do not commit them.

---

## 12. POWERSHELL 5.1 GOTCHAS (Windows)

- PS 5.1 reads `.ps1` files without a BOM as ANSI → mojibake. **Keep scripts UTF-8 WITH BOM.** After editing a `.ps1`, re-add the BOM (shown below) and parse-check.
- Avoid non-ASCII (e.g. em-dash — ) inside `.ps1` bodies; it can decode into a stray quote byte.
- Do not name script variables the same as `param()` switches (case-insensitive collision), e.g. `$major` vs `-Major`.
- Regex `$1$2` style replacements corrupt text — use full `.Replace(old, new)` on exact strings.
- Parse-check a script without running it:
```powershell
$e = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path .\script.ps1), [ref]$null, [ref]$e) | Out-Null
"parse errors: $($e.Count)"
```
- Re-add BOM:
```powershell
$c = [System.IO.File]::ReadAllText('script.ps1', [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText('script.ps1', $c, (New-Object System.Text.UTF8Encoding($true)))
```

---

## 13. KNOWN QUIRKS & DECISIONS (do not "fix" these casually)

- `devtools` standalone pub package is dead → use `d` inside `flutter run`.
- Transitive deps `cli_util`, `material_color_utilities`, `test_api` are Flutter-SDK-pinned ("newer versions incompatible"); `pub upgrade` can't move them. Only a Flutter SDK upgrade does.
- MSIX packaging was tried then REVERTED (user disliked it) — stay on the Inno Setup installer path.
- Anatomy of confusion: a user right-clicking a script expects it to act; scripts must be interactive-safe when run flag-less.
- The Android APK on phones signed with the OLD (purged) key cannot be upgraded in place — first install after rotation requires uninstall. `build_install.ps1` auto-handles this.

---

## 14. GOOGLE PLAY STATUS & CHECKLIST (publishing not finished)

- Play Console account: **not yet fully set up**; publishing requires `app-release.aab` (built via `build_install.ps1 -Aab` or menu option 5).
- New individual accounts must pass a **closed-testing track: 12+ testers for 14 days** before production access.
- One-time $25 developer registration; signup at https://play.google.com/console/signup.
- Still needed before release: store listing assets (screenshots, feature graphic, icon), a **privacy policy URL** (the app is fully offline; host a simple page), content rating questionnaire.
- `+N` (versionCode) must be bumped for EVERY upload — `bump_version.ps1 -Build` or the `-Build`/interactive prompt.
- The app is offline-only, so there is no backend; the AAB must bundle everything (assets are included).

---

## 15. QUICK COMMAND CHEAT SHEET

```powershell
cd C:\Users\devtips\Documents\pdf-to-images\quran-app

# Control center (interactive): right-click alsiraj.ps1 -> Run with PowerShell

python sync_resources.py                       # refresh images/JSON/indexes from pages/
.\bump_version.ps1 -Minor -Build               # bump + tick Android build number
.\bump_version.ps1                             # interactive bump
.\build_install.ps1                            # Windows + Android release + install
.\build_install.ps1 -Aab                       # Play bundle only

C:/flutter/bin/flutter analyze                 # lint / type check (must pass)
C:/flutter/bin/flutter test                    # note: widget_test has a pre-existing failure
C:/flutter/bin/flutter run -d windows          # dev run (press d -> DevTools)
```

---

## 16. FIRST THINGS TO CHECK ON A NEW SESSION

1. `git status --short` and `git log --oneline -5` — see pending/pushed work.
2. `Select-String pubspec.yaml -Pattern '^version:'` + the other two version files agree.
3. Whether the phone is plugged in (`adb devices`).
4. Whether `installer\build_install.log` shows a recent run and its outcome.
5. Reread the drift-prone rules: bump→build→install, never edit version files manually, never commit secrets.