# VentExpensePro 📈

**The Analog Digital Ledger** — A lightweight, privacy-first personal finance application built with Flutter.

VentExpensePro combines the simplicity of a paper ledger with the power of modern digital tools. It is designed for users who want total control over their financial data without compromising on aesthetics or ease of use.

---

## ✨ Features

### 📒 Smart Ledger
*   **Effortless Logging**: Add transactions in seconds with a streamlined interface.
*   **Categorization**: Organize expenses and income with customizable categories.
*   **Rich Details**: Track dates, notes, and payment methods for every entry.

### 🏦 Account Management
*   **Multi-Account Support**: Manage Bank accounts, Cash, Credit Cards, and Wallets in one place.
*   **Net Position**: Instantly view your total financial standing across all accounts.
*   **Credit Settlement**: Specialized workflow for settling credit card bills.

### 📊 Reports & Insights
*   **Visual Analytics**: Understand your spending patterns with dynamic charts (fl_chart).
*   **PDF Export**: Generate professional expense reports for sharing or archival.
*   **Data Filtering**: Drill down into your data by date range or account.

### ☁️ Privacy-First Sync
*   **Google Drive Sync**: Securely backup and sync your data using your own Google Drive.
*   **App Data Scope**: Uses the `drive.appdata` hidden folder scope, ensuring your data is only accessible by the app.
*   **Offline First**: Full functionality without an internet connection.

### 🎨 Premium Design
*   **Flat Aesthetic**: A clean, modern "Flat Design" look that prioritizes readability.
*   **Custom Typography**: Features *Lora* for elegance and *JetBrains Mono* for data precision.
*   **Micro-Animations**: Smooth transitions and interactive elements for a premium feel.

---

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/) (3.11+)
*   **State Management**: [Provider](https://pub.dev/packages/provider)
*   **Local Database**: [Sqflite](https://pub.dev/packages/sqflite) (SQLite)
*   **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it)
*   **APIs & Infrastructure**:
    *   Google Drive API (Backup/Sync)
    *   Firebase Crashlytics (Crash Reporting)
*   **Analytics & Reporting**:
    *   [fl_chart](https://pub.dev/packages/fl_chart)
    *   [pdf](https://pub.dev/packages/pdf)

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (^3.11.0)
*   Android Studio / VS Code with Flutter Extension
*   (Optional) Firebase account for Crashlytics

### Setup
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/HellBus1/VentExpensePro.git
    cd VentExpensePro
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the application**:
    ```bash
    flutter run
    ```

### Production Build (Android)
The project is configured with ProGuard obfuscation and resource shrinking for optimized release builds.

```bash
flutter build apk --release
```

*Note: For Crashlytics functionality, ensure `google-services.json` is placed in `android/app/`.*

---

## 🏗️ Architecture

The project follows a **Clean Architecture** pattern to ensure maintainability and testability:

- **`lib/domain`**: Core business logic, entities, and repository interfaces (Pure Dart).
- **`lib/data`**: Implementation of repositories, SQLite data sources, and external service integrations.
- **`lib/presentation`**: UI layer consisting of Screens, Widgets (Clean Flat Design), and Providers (State Management).
- **`lib/core`**: Application-wide configurations like Themes, DI setup, and Constants.

---

## 🔒 Privacy & Security

*   **No Central Server**: Your financial data is never stored on our servers.
*   **Encrypted Sync**: Cloud sync happens directly between your device and your private Google Drive space.
*   **Obfuscation**: Production builds are obfuscated using R8/ProGuard to protect the application logic.

---

## 📄 License
This project is for personal use and portfolio demonstration. See `LICENSE` for details.
