# Shizuka — Product Requirements Document

**Version:** 1.0
**Status:** needs-triage
**Platform:** iOS & Android (Flutter / Dart)
**Prepared by:** Moiz Ali
**Date:** 2026-05-05

---

## Problem Statement

University students frequently struggle to study consistently, especially when working alone. Isolation leads to distraction, and most productivity tools respond to this with aggressive notifications, competitive leaderboards, or anxiety-inducing countdown timers. These mechanics punish failure rather than encourage presence.

Students who study with friends — even remotely — are more consistent. But there is no tool built specifically for this: one that supports a shared, structured study session without adding noise, competition, or social pressure. The gap is a calm, multiplayer Pomodoro experience where friends can be present together without being in the same room.

---

## Solution

Shizuka is a cross-platform mobile application that transforms solo study into a shared, calm, and structured experience. It combines the Pomodoro technique with real-time multiplayer focus rooms, allowing up to three friends to study together remotely.

Each session consists of two 45-minute focus blocks, each followed by a short break, ending with a longer break and a private AI-generated reflection. Users are held accountable through visibility — every member can see what others are working on — without any competitive or punitive mechanics.

The name Shizuka means quiet, calm, and steady. The product is built around presence, not pressure.

---

## User Stories

### Authentication

1. As a new user, I want to register with my email address and a password, so that I can create a personal account tied to my identity.
2. As a returning user, I want to sign in with my email and password, so that I can access my rooms, streak, and session history.
3. As a user, I want to see a clear error message when I enter incorrect credentials, so that I know what went wrong and can try again.
4. As a user, I want to remain signed in between app sessions, so that I do not have to log in every time I open the app.
5. As a user, I want to sign out of my account, so that I can log out on a shared device.

### Home & Profile

6. As a user, I want to see my current focus streak on the home screen, so that I have a daily motivation to keep studying.
7. As a user, I want to see a list of my past sessions on the home screen, so that I can reflect on my study history.
8. As a user, I want my streak to decrease by one for every day I miss, so that missing one day does not feel catastrophic.
9. As a user, I want my streak to never drop below zero, so that I am never punished past a neutral starting point.
10. As a user, I want to see my streak update automatically after completing a session, so that progress feels immediate.

### Room Creation

11. As a host, I want to create a focus room with a single tap, so that starting a session is frictionless.
12. As a host, I want to receive a unique 6-character alphanumeric room code when I create a room, so that I can share it with friends.
13. As a host, I want to see which friends have joined my room in real time, so that I know when everyone is ready.
14. As a host, I want each joining member to be automatically assigned a unique character, so that everyone has a distinct visual identity in the room without any setup.
15. As a host, I want the session to end for all members if I leave the room, so that the session state remains consistent.

### Room Joining

16. As a guest, I want to enter a 6-character room code to join a session, so that I can join a room my friend is hosting.
17. As a guest, I want to see an error if the code I entered does not match any active room, so that I know to double-check the code.
18. As a guest, I want to be automatically assigned a character when I join, so that my presence in the room is immediately visible.
19. As a guest, I want to see all other members who are already in the lobby, so that I know who I am studying with.

### Lobby & Intention Setting

20. As a user, I want to see all room members and their assigned characters in the lobby, so that the group feels present before the session starts.
21. As a user, I want to type a one-line intention describing what I will work on before each focus block, so that I am accountable to a stated goal.
22. As a user, I want my intention to be visible to all other room members throughout the session, so that everyone knows what each person is working on.
23. As a host, I want to be unable to start the timer until I have submitted my own intention, so that the host is held to the same standard as guests.
24. As a guest, I want a 60-second window after the timer starts to submit my intention, so that a brief delay does not block the whole group.
25. As a user, I want to see which members have submitted their intentions in the lobby, so that I can see when the group is ready.

### Focus Session & Timer

26. As a user, I want the focus timer to appear as a slow breathing animation rather than a raw countdown, so that the experience feels calm rather than pressured.
27. As a user, I want to see a subtle time-remaining indicator below the breathing animation, so that I can check how much time is left without the clock dominating the UI.
28. As a user, I want all members of my room to share the exact same timer state in real time, so that we are all in the same phase simultaneously.
29. As a host, I want to be the only person who can start, pause, or skip the timer, so that there are no conflicting control inputs.
30. As a guest, I want to see the timer state controlled by the host, so that I stay in sync without needing to manage anything.
31. As a user, I want to see all members' stated intentions displayed on the session screen during a focus block, so that I am reminded of what everyone is working on.
32. As a user, I want the session to consist of two 45-minute focus blocks, each followed by a 10-minute break, ending with a 15-minute long break, so that the structure follows the established Pomodoro rhythm agreed upon for this app.
33. As a user, I want a banner to appear when I lose internet connectivity during a session, so that I know the sync has been interrupted.
34. As a user, I want the app to automatically reconnect and snap back to the current room state when my connection is restored, so that I rejoin the session without manual intervention.

### Post-Block Check-In

35. As a user, I want to be prompted to submit a brief check-in after each 45-minute focus block, so that I can reflect on what I accomplished.
36. As a user, I want the check-in to be a single free-text field asking what I got done, so that reflection is low-friction and open-ended.
37. As a user, I want to see all other members' check-in responses after everyone has submitted, so that the group can see each other's progress.
38. As a user, I want check-in responses to be stored so they can be used in the AI reflection at the end of the session.

### Break Screen

39. As a user, I want to see a simple break countdown between focus blocks, so that I know how long the break lasts.
40. As a user, I want to see all members' check-in responses on the break screen, so that the break is a moment of shared reflection.
41. As a host, I want the timer to automatically transition from break back to the next focus block, so that the session flows without manual restarts.

### AI End-of-Session Reflection

42. As a user, I want to receive a privately generated reflection at the end of the session, so that I get a personalised insight into my study session.
43. As a user, I want the reflection to be generated based on my stated intention and my check-in responses, so that it is relevant to what I actually did.
44. As a user, I want the reflection to be calm and non-judgmental in tone, so that it encourages rather than criticises.
45. As a user, I want my reflection to be visible only to me, so that honest check-ins are not discouraged by the fear of being judged.
46. As a user, I want my reflection to be stored in my profile history, so that I can revisit it after the session ends.
47. As a user, I want the session summary — total time, blocks completed, members present — to be displayed alongside my reflection, so that I have a full picture of the session.

### Navigation & Screens

48. As a user, I want a splash screen that auto-navigates based on my auth state, so that I am taken directly to the right screen on launch.
49. As a user, I want clear navigation between all 11 screens — Splash, Login, Home, Create Room, Join Room, Lobby, Session, Check-In, Break, Reflection, Profile — so that the app flow is never confusing.
50. As a user, I want the back button to behave predictably throughout the session flow, so that I do not accidentally exit a live session.

---

## Implementation Decisions

### Module Architecture

The application is structured around five deep modules and three shallow repositories, all wired together via Riverpod providers. No custom backend server is used — the Flutter client communicates directly with Firebase services and the OpenAI API.

**Deep Modules (complex logic, simple interface):**

- **TimerService** — Owns the complete Pomodoro state machine: `idle → focus → check-in → short-break → focus → check-in → long-break → reflection`. Writes timer state to Firebase Realtime Database (host only). All clients subscribe to the Realtime DB node and receive updates in under 200ms. Exposes a single stream of `TimerState` and action methods guarded by host identity. This is the most complex module in the app.

- **StreakService** — Owns streak read and update logic. Computes the number of days missed between `lastActiveDate` and today, decrements streak by that amount, and floors at zero. Exposes `getStreak` and `updateStreak`. Pure logic with no side effects beyond a single Firestore write.

- **ReflectionService** — Fetches the user's intentions and check-ins for the completed session, constructs a prompt, calls the OpenAI chat completions endpoint, and writes the result to the user's Firestore reflection history. Exposes a single `generateReflection(userId, sessionId)` method. The API key is held client-side (acceptable for a lab project).

- **RoomRepository** — Manages the full room lifecycle: generates a 6-character alphanumeric room code, writes the room document to Firestore, handles member join via code lookup, assigns characters, and updates room status. On host disconnect, sets room status to `ended` so all clients navigate away.

- **AuthRepository** — Wraps Firebase Auth `createUserWithEmailAndPassword` and `signInWithEmailAndPassword`. On successful registration, writes the user profile document to Firestore `/users/{uid}`. Exposes an `authStateChanges` stream consumed by the app router to drive navigation.

**Shallow Repositories (simple CRUD, thin interface):**

- **IntentionRepository** — Writes and streams intentions for a given room and block from Firestore `/rooms/{roomId}/intentions/{uid}`.

- **CheckInRepository** — Writes and streams check-ins from Firestore `/rooms/{roomId}/checkins/{uid}/{block}`.

- **ProfileRepository** — Reads user profile and session history from Firestore `/users/{uid}`.

### State Management

Riverpod is used throughout. Each deep module is exposed as a `Provider` or `AsyncNotifierProvider`. Firebase streams are consumed via `StreamProvider`. Screens read providers via `ConsumerWidget` or `ConsumerStatefulWidget`. No `setState` is used beyond animation controllers.

### Firebase Data Structure

**Firestore:**
- `/users/{uid}` — `{name, email, streak, lastActiveDate, createdAt}`
- `/rooms/{roomId}` — `{code, host, members[], status, characters{uid: charId}, createdAt}`
- `/rooms/{roomId}/intentions/{uid}` — `{text, block, submittedAt}`
- `/rooms/{roomId}/checkins/{uid}/{block}` — `{text, submittedAt}`
- `/users/{uid}/reflections/{sessionId}` — `{text, generatedAt, intention, checkins[], sessionId}`

**Realtime Database:**
- `/rooms/{roomId}/timer` — `{state, phase, blockNumber, startedAt, pausedAt}`

### Timer State Machine

Valid states and transitions:
- `idle` → `focus` (host starts)
- `focus` → `paused` (host pauses)
- `paused` → `focus` (host resumes)
- `focus` → `check-in` (45 min elapsed or host skips)
- `check-in` → `short-break` (all check-ins submitted or timeout)
- `short-break` → `focus` (10 min elapsed, if block 1 complete)
- `short-break` → `long-break` (10 min elapsed, if block 2 complete)
- `long-break` → `reflection` (15 min elapsed)

### Room Code Generation

Room codes are 6-character strings drawn from the set `[A-Z0-9]`. Generated client-side by the host at room creation time. Collision checked against Firestore before writing — regenerate on collision.

### Connectivity

Firebase SDK handles reconnection automatically. A `connectionStateProvider` monitors `FirebaseDatabase.instance.ref('.info/connected')` and surfaces a banner when the value is `false`. On reconnect, Riverpod providers invalidate and re-fetch current room state.

### Navigation

11 screens managed via `go_router`. The app router listens to `authStateChanges` and redirects unauthenticated users to Login. Session screens (Lobby → Session → Check-In → Break → Reflection) form a guarded sub-route that requires an active room.

### OpenAI Integration

A single POST to `/v1/chat/completions` is made per user at session end. The prompt includes the user's intention for each block and their check-in response for each block. The system prompt instructs the model to respond in one short paragraph, calmly, without judgment. The response is displayed privately and stored in Firestore.

---

## Testing Decisions

### What makes a good test

A good test verifies observable external behaviour — what a module returns or what state it produces — not how it achieves it internally. Tests should not assert on private methods, internal data structures, or implementation-specific sequences of calls. A test should remain valid after a refactor that does not change external behaviour.

### Modules to test

**TimerService — high priority**
The state machine transitions are pure logic that can be tested independently of Firebase. Tests should verify that: valid transitions produce the correct next state, invalid transitions are rejected, phase progression (block 1 → check-in → break → block 2 → long break → reflection) is correct, and the block number increments correctly. These tests should use a fake/stub Realtime Database writer so no network calls are made.

**StreakService — high priority**
The streak decrement logic is a pure function of two dates and a current streak value. Tests should verify: same-day session does not change streak, one missed day decrements by one, multiple missed days decrement by the number of days missed, streak never goes below zero, and streak increments by one after a completed session when no days were missed.

**RoomRepository (code generation) — medium priority**
The 6-character code generator should be tested to verify it only produces characters from the valid set and always produces exactly 6 characters.

### Modules not tested in v1

IntentionRepository, CheckInRepository, ProfileRepository, and ReflectionService all depend heavily on network calls or external APIs and are deferred to integration testing after the app is functional.

---

## Out of Scope

The following are explicitly excluded from this version:

- **Forgot password / password reset** — not included in v1 auth flow
- **Google sign-in** — email/password only in v1
- **Hard room member limit enforcement** — the 3-member design is soft; no Firebase rule blocks a 4th member
- **Host transfer** — if the host leaves, the session ends; host role does not migrate
- **Offline mode** — the app requires connectivity; no action queuing or offline state reconciliation
- **Music queue** — lo-fi playback is a future feature
- **Analytics dashboard** — session pattern visualisations are a future feature
- **Public rooms** — all rooms are invite-only via code in v1
- **Character customisation** — characters are auto-assigned from a fixed set; no unlocking or skins
- **Wearable support** — Apple Watch and Wear OS are future features
- **Web landing page** — the public download page is out of scope for the Flutter build
- **Email verification** — not enforced in v1
- **Push notifications** — no remote notifications in v1

---

## Further Notes

- The breathing animation for the timer is the centrepiece UI element. It should be implemented as a looping scale animation on a circle, with speed and opacity modulated by the current timer phase. The actual elapsed time is derived from `startedAt` in the Realtime DB, not from a local ticker, so all clients stay in sync even after backgrounding the app.
- The word "Shizuka" means quiet and calm in Japanese. Every design and interaction decision should reinforce this feeling. When in doubt, do less, not more.
- Firebase must be set up from scratch — no project has been created yet. Firebase setup (project creation, Android/iOS app registration, `google-services.json` / `GoogleService-Info.plist` download, and Firestore/Realtime DB rule configuration) is a prerequisite before any code that touches Firebase can run.
- The OpenAI API key is stored client-side. This is acceptable for a university lab project but would need to be moved to a backend proxy before any public release.
- LinkedIn posts will be written at the end of each development phase in a personal, storytelling tone under Moiz Ali's name.
- Microsoft Planner board structure will be defined and populated separately.
