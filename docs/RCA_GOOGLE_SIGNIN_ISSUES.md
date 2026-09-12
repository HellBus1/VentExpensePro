# Root Cause Analysis (RCA): Google Sign-In & Drive Sync

**Date:** September 13, 2026  
**Component:** Authentication & Cloud Backup (`google_sign_in`, `googleapis`, `GoogleDriveService`)  
**Target Environment:** Android Emulator (API 37) / Flutter Mobile  

---

## 1. Executive Summary

During the initial integration and testing of the Google Drive backup feature on Android, two key blockers occurred:
1. **Runtime Exception:** `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: null null, null)`.
2. **Authorization Interstitial:** Google displayed the warning screen `"Google hasn't verified this app"`.

Both behaviors were investigated using device logs (`adb logcat`), system dump utilities (`dumpsys account`), and Gradle signing diagnostics (`signingReport`). This document analyzes the root causes and records the exact remediation steps.

---

## 2. Issue 1: `com.google.android.gms.common.api.ApiException: null null`

### 2.1 Symptoms
When tapping **"Sign In with Google"** or the sync chip in the app:
- The UI showed a generic error: `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: null null, null)`.
- The Google Sign-In account picker opened for a fraction of a second and immediately dismissed.

### 2.2 Forensic Log Analysis
Inspecting Android system logs via `adb logcat` revealed:
```text
09-13 00:05:45.840   WindowManager: setClientSurface Surface(name=VRI-.../SignInHubActivity)
09-13 00:05:46.740   GoogleApiManager: ConnectionResult{statusCode=API_UNAVAILABLE, resolution=null, message=null}
09-13 00:05:46.803   WindowManager: CLOSE f=FILLS_TASK leash=.../MinuteMaidActivity
09-13 00:05:47.919   Finsky: Module info request for [...] modules from package com.google.android.gms hasAccount:false authEnabled:false
```

Querying the device account manager (`adb shell dumpsys account`):
```text
User UserInfo{0:Owner}:
  Accounts: 0
  Active Sessions: 0
```

### 2.3 Root Cause Analysis

1. **Zero Device Accounts (`hasAccount: false`):**
   The Android emulator had no Google account logged in at the operating system level (`Accounts: 0`). When `google_sign_in` requested interactive sign-in with Drive scopes, Google Play Services' `SignInHubActivity` attempted to delegate to `MinuteMaidActivity` (the account registration flow). Because no account was authenticated with Google Play, Google Play Services aborted with `API_UNAVAILABLE`.
2. **Debug Keystore SHA-1 Fingerprint Matching:**
   Google Play Services on Android validates the caller's package name and SHA-1 certificate against the OAuth 2.0 client IDs configured in Google Cloud Console. If the SHA-1 of the local `debug.keystore` does not match the registered client ID, Play Services returns `CommonStatusCodes.DEVELOPER_ERROR` (code 10), which surfaces in Flutter as `ApiException`.

### 2.4 Resolution
1. **Added Google Account to Device:**
   Navigated to **Settings → Passwords & accounts → Add account → Google** in the emulator and logged in with the developer Google account.
2. **Confirmed Keystore Signature:**
   Ran `./gradlew signingReport` with JDK 17 to obtain the exact debug SHA-1:
   ```text
   Package: com.digiventure.ventexpensepro
   SHA-1:   31:26:42:32:43:C1:3D:F6:A9:F7:DA:2D:D5:62:7C:10:EC:D7:79:86
   ```
   Registered this fingerprint under the Android OAuth Client in the Google Cloud Console project.

---

## 3. Issue 2: "Google hasn't verified this app" Warning Screen

### 3.1 Symptoms
After resolving the account issue and retrying sign-in, Google opened a full-screen warning:
> **Google hasn't verified this app**  
> *The app is requesting access to sensitive info in your Google Account.*

### 3.2 Root Cause Analysis
- **Sensitive Scope Classification:**  
  VentExpensePro requests `https://www.googleapis.com/auth/drive.appdata`. Google Cloud classifies all Drive API scopes as **Sensitive** or **Restricted**.
- **OAuth Publishing Status:**  
  When an OAuth consent screen is created, its default publishing status is **Testing**. For testing apps requesting sensitive scopes, Google requires user acknowledgment before granting an OAuth grant token.
- **Whitelist Enforcement:**  
  If an account is NOT listed in the **Test users** section of the Google Cloud Console, Google displays an unbypassable error: *"Access blocked: This app has not completed the Google verification process"*.  
  When the account IS in the **Test users** list, Google allows the user to bypass the warning via the **Advanced** link.

### 3.3 Resolution
1. **For Development / Testing:**
   - On the warning screen, tap **"Advanced"** (below the *"Back to safety"* button).
   - Tap **"Go to VentExpensePro (unsafe)"**.
   - Check the permission checkbox and tap **Continue**.
   - Google grants the refresh token, and the prompt will not appear again for that user.
2. **For Production Releases:**
   - In Google Cloud Console → **OAuth consent screen**, submit the app for verification with a valid privacy policy URL, application homepage, and YouTube demonstration video.

---

## 4. Preventive Measures & Debugging Checklist

When setting up a new developer machine or testing environment:

| Step | Check | Verification Command |
|---|---|---|
| 1 | Emulator has an active Google account | `adb shell dumpsys account \| grep "Accounts:"` |
| 2 | Debug keystore matches Google Cloud | `cd android && ./gradlew signingReport` |
| 3 | Package name matches exactly | `com.digiventure.ventexpensepro` |
| 4 | Google Drive API is enabled | Check [Google Cloud Console API Library](https://console.cloud.google.com/apis/library/drive.googleapis.com) |
| 5 | Tester email is in Test Users list | Check [OAuth Consent Screen Test Users](https://console.cloud.google.com/apis/credentials/consent) |
| 6 | Detailed runtime error logging | Run `flutter run -v` to capture complete Play Services stack traces |
