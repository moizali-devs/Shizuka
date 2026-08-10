# Shizuka

**Shizuka** (静か — "quiet, calm, steady") is a cross-platform mobile app that turns solo studying into a shared, structured, and calm experience. Up to three friends join a real-time focus room, work through synchronized Pomodoro sessions together, and end with a private, AI-generated reflection.

Most productivity apps push urgency: aggressive notifications, leaderboards, countdown anxiety. Shizuka takes the opposite approach — presence without pressure. You can see what your friends are working on, everyone moves through the same timer in lockstep, and there's no competition or punishment mechanic anywhere in the flow.

## Features

- **Real-time focus rooms** — create a room, get a 6-character code, and up to three friends join and stay in sync via Firebase Realtime Database (all clients see the same timer state within ~200ms).
- **Structured session flow** — two 45-minute focus blocks, each followed by a short break, ending in a longer break: `focus → check-in → break → focus → check-in → long-break → reflection`.
- **Intention setting** — before each block, everyone states in one line what they're working on. It stays visible to the group for the whole block.
- **Breathing-animation timer** — the countdown is presented as a slow breathing circle rather than a raw digit clock, on purpose.
- **Post-block check-ins** — a short free-text reflection after each block, shared with the group at the following break.
- **Private AI reflection** — at session end, each member gets a personal, non-judgmental summary generated from their own intentions and check-ins (OpenAI), visible only to them and saved to their profile history.
- **Streaks** — a daily focus streak that decays gently (never punitive, never below zero) instead of resetting to zero on a missed day.
- **Connectivity resilience** — a banner surfaces when sync drops, and clients snap back to the live room state automatically on reconnect.

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter / Dart |
| State management | Riverpod (`flutter_riverpod`, code-gen via `riverpod_generator`) |
| Navigation | `go_router`, auth-aware redirects |
| Backend | Firebase (Auth, Firestore, Realtime Database) — no custom server |
| AI reflections | OpenAI Chat Completions API |
| Targets | Android, iOS, plus generated desktop/web scaffolding |

## Architecture

The app is organized around a small set of deep modules with narrow interfaces, wired together with Riverpod providers:

- **`TimerService`** — owns the Pomodoro state machine end-to-end. The host's client is the only writer to the Realtime Database timer node; every client subscribes and derives elapsed time from `startedAt`, so state stays correct even after backgrounding the app.
- **`StreakService`** — pure date-diff logic: decrements the streak by days missed, floors at zero, no side effects beyond a single Firestore write.
- **`ReflectionService`** — gathers a completed session's intentions/check-ins, prompts OpenAI, and stores the private result.
- **`RoomRepository`** — room lifecycle: code generation with collision checks, member join, character assignment, host-disconnect handling.
- **`AuthRepository`** — thin wrapper over Firebase Auth plus the user profile document.
- **`IntentionRepository` / `CheckInRepository` / `ProfileRepository`** — shallow, focused Firestore CRUD.

Full requirements and implementation decisions live in [`docs/PRD.md`](docs/PRD.md).

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.11.5`)
- A Firebase project with Auth, Firestore, and Realtime Database enabled
- An OpenAI API key (only needed for the end-of-session reflection feature)

### Setup

```bash
flutter pub get
```

Firebase config (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`) is already wired up for the project's own Firebase instance. If you're standing up your own backend instead, regenerate these with the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):

```bash
flutterfire configure
```

The OpenAI key is injected at build/run time, not hardcoded:

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-...
```

### Run

```bash
flutter run
```

### Test

```bash
flutter test
```

## Project status

This project was built as a university final-project/lab exercise (see [`docs/PRD.md`](docs/PRD.md) for the full spec). Out-of-scope items for this version include password reset, Google sign-in, offline mode, and push notifications — see the PRD's "Out of Scope" section for the complete list.
