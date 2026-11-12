# Budget Tracker

A private, offline-first Flutter app for tracking income, expenses, monthly
budgets, recurring entries, and spending statistics. Data is stored locally in
SQLite through Drift.

## Features

- Add, edit, delete, and undo income and expense transactions.
- Track a derived wallet balance and get warnings when it becomes negative.
- Manage typed categories; archived categories remain attached to history.
- Set monthly spending limits with carry-forward and 80%/100% status levels.
- Review monthly totals, category breakdowns, and daily or Saturday-start weekly
  spending charts.
- Schedule monthly recurring entries with backfill, month-end clamping, and
  duplicate protection.

## Development

Requires Flutter and Dart compatible with the SDK constraint in `pubspec.yaml`.

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Regenerate launcher icons after changing `assets/app_icon.png`:

```powershell
dart run flutter_launcher_icons
```

Run static analysis and the full test suite with:

```powershell
flutter analyze
flutter test
```

## Release preparation

Set a unique Android application ID and configure production signing before
publishing. The current Android release configuration uses the debug signing
key for local release builds. Transaction export is not included yet.
