# CampusMate

A mobile app that helps college students connect, form study groups, and communicate — all in one place.

Built with Flutter and Firebase as a class project (CSC322), then extended with additional features including real-time messaging, file sharing, and a group calendar.

---

## Features

- **Authentication** — Email/password sign-up with email verification and a guided onboarding flow
- **Home Dashboard** — Daily motivational quotes (fetched from an external API), friend stats, and personalized peer recommendations
- **Friend System** — Search for other students, send/accept friend requests, view profiles
- **Direct Messaging** — Real-time 1-on-1 chat with image and file attachment support
- **Study Groups** — Create and join study groups tagged by major and personality traits; group chat included
- **Group Calendar** — Per-group calendar for scheduling study sessions and events
- **Search & Discovery** — Filter groups by name, major, and personality traits in real time
- **Profile & Settings** — Edit profile info, bio, major, and personality traits

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Backend / Database | Firebase Firestore |
| Authentication | Firebase Auth |
| File Storage | Firebase Storage |
| Navigation | go_router |
| External API | Motivational quotes REST API |

---

## Architecture

```
lib/
├── main.dart               # App entry point, router setup
├── models/                 # Data models (UserProfile, Groups, Chat, Message)
├── providers/              # Riverpod providers (auth, user profile, groups, chats)
├── screens/
│   ├── auth/               # Login, sign-up, email verification, onboarding
│   ├── general/            # Home, search, messages, groups, chat, calendar
│   └── settings/           # Profile edit, settings
├── db_helpers/             # Firestore abstraction layer (users, groups, chat)
├── services/               # Friend service logic
├── widgets/                # Reusable UI components
├── theme/                  # Light/dark theme definitions
└── util/                   # File utilities, snackbar helpers
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.9.2`
- A Firebase project with Firestore, Authentication, and Storage enabled

### Setup

1. Clone the repo
   ```bash
   git clone https://github.com/Kipung/campusmate.git
   cd campusmate
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Add your own `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase project — these are excluded from version control.

4. Run the app
   ```bash
   flutter run
   ```

---

## Notes

- Firebase config files are gitignored — you will need to connect your own Firebase project to run this locally.
- The app was originally scaffolded from a course template (CSC322) and then built out collaboratively.
