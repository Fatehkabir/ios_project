# EmergencyReady 🛡️

A personal emergency preparedness iOS app built with **SwiftUI** and **Firebase**.

## Features

| Tab | What it does |
|-----|-------------|
| 🏠 Home | Daily safety tip, emergency categories, one-tap search |
| 📖 Guides | 6 emergency categories → 14 step-by-step guides |
| 👥 Contacts | Add / edit / call personal emergency contacts (Firestore) |
| ✅ Checklist | Supplies checklist with progress bar (Firestore) |
| ❤️ Favorites | Saved guides (Firestore) |

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 15.4 or later |
| iOS Deployment Target | 16.0+ |
| Swift | 5.9+ |
| Firebase iOS SDK | 11.x (resolved automatically via SPM) |

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/EmergencyReady.git
cd EmergencyReady
```

### 2. Add `GoogleService-Info.plist`

1. Go to [Firebase Console](https://console.firebase.google.com) → your project → Project Settings → iOS apps.
2. Download the real `GoogleService-Info.plist`.
3. Replace `EmergencyReady/GoogleService-Info.plist` with your downloaded file.

> ⚠️ The committed file is a **stub** — the app will crash on launch until you replace it.

### 3. Firebase Console setup

| Step | What to do |
|------|-----------|
| Authentication | Enable **Email/Password** sign-in |
| Firestore | Create database → paste `Firebase/firestore.rules` → Publish |

### 4. Open in Xcode and run

```
open EmergencyReady.xcodeproj
```

- Xcode will automatically resolve the Firebase Swift Package dependencies.
- Select an iPhone simulator (iOS 16+) and press **⌘R**.

## Project Structure

```
EmergencyReady/
├── EmergencyReadyApp.swift      # @main entry point, Firebase configure()
├── Theme.swift                  # Colours, button/card styles
├── Info.plist
├── GoogleService-Info.plist     # ← replace with your real file
├── Assets.xcassets/
├── Models/                      # Plain Swift structs (Codable / Identifiable)
├── Services/                    # Firebase services + Validation helpers
├── Resources/
│   └── EmergencyData.json       # All categories, guides and tips
└── Views/
    ├── Authentication/          # Login, Register
    ├── Checklist/
    ├── Components/              # Reusable cards, badges, form fields
    ├── Contacts/
    ├── Emergency/               # Category → Guide list → Guide detail
    ├── Favorites/
    ├── Home/
    ├── Search/
    └── Tips/
```

## Codemagic CI/CD

The repo includes `codemagic.yaml` with two workflows:

| Workflow | Purpose |
|----------|---------|
| `manual-setup-session` | Keeps a Mac Mini M2 alive 30 min via VNC for one-time setup |
| `simulator-native-ios` | Builds the app for the iOS Simulator (no signing needed) |

### Using `simulator-native-ios` on Codemagic

1. Connect this GitHub repo to [codemagic.io](https://codemagic.io).
2. *(Optional)* Add `GOOGLE_SERVICE_INFO_PLIST` as a **base-64** encoded environment file variable in Codemagic → it will be injected automatically.
3. Start a new build and select the **EmergencyReady iOS Simulator Build** workflow.

## License

MIT
