# Badge Boss

**Professional Event Check-in & Badging Solution**

A mobile-first, offline-capable Flutter application for event management, attendee check-in, and badge printing. Built with Flutter and Firebase.

## 🚀 Features

### ✅ Core Functionality
- **QR Code Scanning** - Real camera integration with mobile_scanner
- **Offline-First Architecture** - Hive local storage with auto-sync
- **Duplicate Detection** - Prevents pass-backs with timestamp warnings
- **Visual Verification** - Display attendee photo for identity confirmation

### ✅ Attendee Management
- **CSV/Excel Import** - Auto-detect column mapping
- **Search & Filter** - By name, email, company, or category
- **Walk-in Registration** - Add attendees on-device
- **Custom Fields** - Support for event-specific data

### ✅ Badge Printing
- **Visual Designer** - Drag-and-drop badge canvas
- **ZPL Generation** - Optimized for Zebra thermal printers
- **Printer Discovery** - Bluetooth and WiFi support
- **Print Queue** - Retry logic for connection issues

### ✅ Analytics Dashboard
- **Real-time Stats** - Registered vs checked-in
- **Category Breakdown** - Pie chart visualization
- **Velocity Graph** - Check-ins per hour
- **Export Reports** - Download attendance data

### ✅ Firebase Backend
- **Cloud Firestore** - Real-time data sync
- **Firebase Auth** - Email and Google SSO
- **Cloud Storage** - Attendee photos and logos
- **Security Rules** - Multi-tenant data isolation

## 📁 Project Structure

```
badge_boss/
├── lib/
│   ├── main.dart                 # App entry with Firebase init
│   ├── app.dart                  # Theme and routing
│   ├── firebase_options.dart     # Firebase configuration
│   ├── models/                   # Data models
│   │   ├── attendee.dart
│   │   ├── event.dart
│   │   ├── organization.dart
│   │   ├── badge_template.dart
│   │   └── checkin_log.dart
│   ├── services/                 # Business logic
│   │   ├── firebase_service.dart     # Real Firestore
│   │   ├── firestore_service.dart    # Mock for dev
│   │   ├── offline_sync_service.dart # Hive caching
│   │   ├── qr_scanner_service.dart   # Camera scanning
│   │   ├── import_service.dart       # CSV/Excel
│   │   └── printer_service.dart      # Zebra/Brother
│   ├── providers/                # State management
│   │   ├── auth_provider.dart
│   │   ├── event_provider.dart
│   │   ├── attendee_provider.dart
│   │   ├── checkin_provider.dart
│   │   └── sync_provider.dart
│   ├── screens/                  # UI screens
│   │   ├── auth/login_screen.dart
│   │   ├── dashboard/main_dashboard.dart
│   │   ├── checkin/checkin_screen.dart
│   │   ├── attendees/attendees_screen.dart
│   │   ├── attendees/import_screen.dart
│   │   ├── analytics/analytics_screen.dart
│   │   ├── badges/badge_designer_screen.dart
│   │   └── events/printer_setup_screen.dart
│   └── widgets/                  # Reusable components
└── pubspec.yaml
```

## 🛠 Getting Started

### Prerequisites
- Flutter SDK >= 3.2.0
- Dart >= 3.2.0
- Firebase project (optional for demo mode)

### Installation

```bash
# Clone and enter directory
cd badge_boss

# Get dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build

# Run the app
flutter run
```

### Firebase Setup (Optional)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure

# This will update firebase_options.dart with your project
```

## 🎯 Demo Mode

The app includes mock data for development:
- **Organization**: Demo Organization (3/100 events)
- **Event**: Tech Conference 2024 (150 attendees)
- **Check-ins**: 45 pre-checked attendees

## 📱 Supported Printers

| Brand | Models | Connection |
|-------|--------|------------|
| Zebra | ZD420, ZD621 | Bluetooth, WiFi |
| Brother | QL-820, QL-1110 | WiFi |

## 📄 License

MIT License

---

Built with ❤️ using Flutter
