# Budget Tracker 💰

A modern, private, and offline-first personal finance application built with **Flutter**, **Drift (SQLite)**, and **Material 3**. Designed to give you complete ownership and clarity over your finances without third-party cloud accounts, tracking, or subscription paywalls.

---

## ✨ Features

### 💵 Core Accounting & Wallets
- **Multi-Wallet Architecture**: Manage separate accounts (e.g., Cash, Bank, Savings) with dedicated balances, custom icons, and inter-wallet transfers.
- **Transaction Management**: Add, edit, delete, and undo income and expense records.
- **Negative Balance Warnings**: Real-time visual alerts and overdrawn badges when account balances fall below zero.
- **Income & Expense Categories**: Categorize spending with customized icons and colors. Archived categories safely retain historical transaction links.

### 📊 Monthly Budgets & Analytics
- **Spending Limits & Utilization**: Configure monthly budget caps with dynamic progress indicators and visual alert thresholds (80% warning and 100% exceeded).
- **Interactive Visual Statistics**: Monthly totals, donut chart spending distribution, category utilization bars, and Saturday-first weekly spending trends.

### 🔁 Automation & Recurring Rules
- **Monthly Recurring Entries**: Automate recurring bills, salaries, and subscriptions.
- **Smart Generation**: Handles month-end clamping (e.g., 31st on shorter months), duplicate prevention, and historical backfilling on app launch.

### 📱 Android Home Screen Widget
- **Glanceable Live Balance**: Real-time home screen widget powered by `home_widget`.
- **Quick Action**: "+ Expense" button on your home screen opens directly to the entry sheet.
- **Privacy Support**: Option to hide the balance on the widget directly from settings.

### 🛡️ Privacy & Security
- **Biometric App Lock**: Fingerprint, Face ID, or system PIN authentication powered by `local_auth`.
- **Configurable Auto-Lock**: Choose when the app locks upon leaving the foreground (*Immediately*, *1 min*, *5 min*, *15 min*).
- **Incognito Privacy Mode**: One-tap toggle to mask financial amounts (`••••••`) across the entire app for privacy in public spaces.

### 💾 Data Portability & Safety
- **Full Database Backups (`.budgetbackup` / JSON)**: Export and restore complete snapshots of wallets, categories, transactions, recurring rules, and budgets.
- **AES-256 Encryption**: Optional password protection for backups using PBKDF2 key derivation and AES-256 encryption.
- **Safe Restore Verification**: Inspects backup contents and item counts with confirmation before atomic restoration.
- **Export Reports**: Generate clean RFC 4180 **CSV spreadsheets** and styled **PDF monthly statements** ready to print or share.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.9.2`)
- **Design System**: Material 3 with full Light and Dark theme support (custom Emerald identity)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (BLoC & Cubit)
- **Local Database**: [Drift](https://drift.simonbinder.eu/) (Type-safe SQLite persistence with DAOs)
- **Dependency Injection**: [get_it](https://pub.dev/packages/get_it) & [injectable](https://pub.dev/packages/injectable)
- **Routing**: [go_router](https://pub.dev/packages/go_router) with stateful bottom navigation
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Native Extensions**: [home_widget](https://pub.dev/packages/home_widget) & [local_auth](https://pub.dev/packages/local_auth)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.35.x or later)
- Android Studio / Android SDK (configured for compileSdk 34+)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Code
Run `build_runner` to generate Drift database code and Injectable dependency registrations:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run the App
```bash
flutter run
```

---

## 🧪 Testing & Code Quality

Run static analysis:
```bash
dart analyze
```

Run test suite:
```bash
flutter test
```

Update launcher icons:
```bash
dart run flutter_launcher_icons
```

---

## 🔒 Privacy Notice

Budget Tracker is **100% offline-first**. None of your financial records, balances, notes, or receipts are sent to any remote server or third-party analytics provider. All data stays strictly on your local device.
