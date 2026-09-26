# CrateTrack NG

A reusable plastic crate (RPC) rental ledger for produce transport. Tracks
each crate by QR code, records deposits and per-trip rental fees, logs
custody as crates move farm → truck → market, and handles damage claims.

## Features
- **QR code per crate** — generated on registration (`qr_flutter`) and
  scanned in the field (`mobile_scanner`) to pull up a crate's record.
- **Custody transfer log** — every hand-off records status, location,
  handler and timestamp; moving a crate into transit automatically books
  the rental fee for that trip.
- **Deposit & rental fee ledger** — per-crate ledger of deposits, rental
  fees, payments, refunds and damage penalties, with a running balance.
- **Damage claims** — file a claim with a description, estimated cost and
  optional photo; approving a claim deducts it from the deposit refund and
  posts a penalty to the ledger.
- **Crate inventory dashboard** — counts, revenue, and per-crate status at
  a glance.

## Setup
```bash
flutter pub get
flutter run
```

## Testing
```bash
flutter analyze
flutter test
```
`test/ledger_calculator_test.dart` covers the fee/balance/refund
calculations in `lib/core/services/ledger_calculator.dart`, kept free of
Flutter dependencies so it is fast and deterministic to test.

## Permissions
The app requests camera access (Android `CAMERA` permission,
iOS `NSCameraUsageDescription`) to scan crate QR codes and to attach photos
to damage claims.

## Architecture
BLoC state management (`CrateBloc`) over a Hive-backed repository
(`CrateRepository`), with plain-map (de)serialization — no code generation
required. Dark theme UI built with Material 3.

## App 10 of 11 — Abuja Infrastructure Series
