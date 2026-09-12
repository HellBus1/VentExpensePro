# Google Cloud OAuth 2.0 Setup Guide

This guide describes how to configure Google Cloud credentials for **VentExpensePro** on Android and iOS.

---

## 1. Google Cloud Console Project

1. Log in to [Google Cloud Console](https://console.cloud.google.com/).
2. Click the project dropdown in the top bar and select **New Project**.
3. Name the project `VentExpensePro` and click **Create**.
4. Make sure your newly created project is selected in the top bar.

---

## 2. Enable Google Drive API

1. Navigate to **APIs & Services** → **Library**.
2. Search for **Google Drive API**.
3. Click on **Google Drive API** and click **Enable**.

---

## 3. Configure OAuth Consent Screen

1. Navigate to **APIs & Services** → **OAuth consent screen**.
2. Select **External** user type and click **Create**.
3. Fill in the required application information:
   - **App name**: `VentExpensePro`
   - **User support email**: Select your developer email.
   - **Developer contact information**: Enter your email address.
   - Click **Save and Continue**.
4. **Scopes configuration**:
   - Click **Add or Remove Scopes**.
   - Select or manually add:
     - `https://www.googleapis.com/auth/drive.appdata` (*Application Data folder access*)
     - `.../auth/userinfo.email`
     - `.../auth/userinfo.profile`
   - Click **Update** → **Save and Continue**.
5. **Test users configuration (CRITICAL)**:
   - Click **+ Add Users**.
   - Add every Google account email address that will be used to log into the app during development or internal testing.
   - Click **Save and Continue**.

---

## 4. Android Client Setup

### 4.1 Retrieve your Debug SHA-1
Run the following command from the project root:

```bash
cd android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew signingReport
```
*(Or with keytool:)*
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **`debug`** variant output:
```text
Variant: debug
Config: debug
Store: /Users/<user>/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: 31:26:42:32:43:C1:3D:F6:A9:F7:DA:2D:D5:62:7C:10:EC:D7:79:86
```

### 4.2 Register Android OAuth Client in Google Cloud
1. Go to **APIs & Services** → **Credentials**.
2. Click **+ Create Credentials** → **OAuth client ID**.
3. Set **Application type** to `Android`.
4. Enter:
   - **Name**: `VentExpensePro Android Debug`
   - **Package name**: `com.digiventure.ventexpensepro`
   - **SHA-1 certificate fingerprint**: Paste your debug SHA-1 (e.g., `31:26:42:32:43:C1:3D:F6:A9:F7:DA:2D:D5:62:7C:10:EC:D7:79:86`).
5. Click **Create**.

### 4.3 Production Release Keystore (When Releasing to Play Store)
When signing with a release keystore or Google Play App Signing:
1. Extract the SHA-1 of your release keystore (or copy the App Signing Certificate SHA-1 from Google Play Console).
2. Add a **second Android OAuth Client ID** in Google Cloud Console with the release SHA-1 and the same package name (`com.digiventure.ventexpensepro`).

---

## 5. iOS Client Setup

1. In Google Cloud Console → **Credentials**, click **+ Create Credentials** → **OAuth client ID**.
2. Set **Application type** to `iOS`.
3. Enter:
   - **Name**: `VentExpensePro iOS`
   - **Bundle ID**: `com.digiventure.ventexpensepro`
4. After creation, copy the **Reversed client ID** (e.g. `com.googleusercontent.apps.XXXXXXXXXXXX-XXXXXXXX`).
5. In `ios/Runner/Info.plist`, add the URL scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR-REVERSED-CLIENT-ID</string>
           </array>
       </dict>
   </array>
   ```

---

## 6. Public Repository Security Guidelines

When maintaining a public repository on GitHub:

1. **OAuth Client IDs are Public by Design:**  
   Google OAuth client IDs for Android/iOS apps are public identifiers. Security is enforced by the **SHA-1 fingerprint signature matching** (Android) and **Bundle ID matching** (iOS). An attacker who copies your client ID cannot authorize against it without possessing your private keystore file.
2. **Never Commit Signing Keystores or Secrets:**  
   The following files MUST stay in `.gitignore`:
   - `*.keystore`, `*.jks` (Private Android keystores)
   - `key.properties` (Keystore passwords & aliases)
   - `google-services.json` / `GoogleService-Info.plist` (Config files containing project-specific metadata)
   - `*.env` (Environment secrets)
   - Local database files (`*.sqlite`, `*.db`) containing personal transactions.
3. **App Data Privacy:**  
   VentExpensePro uses `driveAppdataScope`. Backups uploaded by users remain in their personal Google Drive storage. No centralized database or backend server ever sees their personal financial data.
