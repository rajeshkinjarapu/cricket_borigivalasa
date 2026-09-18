# Cricket Scoring App

Flutter cricket scoring app with role-based access (Admin + Member).

## Features
- Ball-by-ball live scoring
- Tournaments, teams, players
- Match scheduling & toss
- Points table with NRR
- Manhattan / Run-rate / Worm charts
- Player career stats

## Setup
1. `flutter pub get`
2. `flutterfire configure`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter run`

## First admin
Sign up in app, then in Firestore change `users/{uid}.role` to `admin`.
