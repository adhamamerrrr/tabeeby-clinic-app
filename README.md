# Tabeeby - clinic appointment demo

A newly authored Flutter portfolio rebuild, added in October 2026. The previous repository contained only a README. This is an offline demonstration with fictional doctors and sample patient data, not recovered original application code.

## Run

Install a current stable Flutter SDK (Dart 3.10+), then:

```sh
flutter pub get
flutter run -d chrome
```

A web entry point is included. To generate standard native platform projects locally:

```sh
flutter create --platforms=android,ios --project-name tabeeby_clinic_app --org dev.adhamamer .
flutter run
```

Keep the included `lib/` implementation and `test/` files if a local generator offers to replace them. iOS builds require macOS and Xcode; Android requires its SDK.

## Working source

- Doctor directory with specialties and appointment fees.
- Future half-hour slots between 09:00 and 17:00 in the device's local timezone.
- Validated booking with doctor-slot and patient-time conflict prevention.
- Patient appointment list, cancellation confirmation and visit history.
- Doctor demonstration view, filtering and completion with optional notes.
- Local JSON persistence through SharedPreferences; failed writes preserve the previous in-memory state. Invalid stored data shows a retry screen without overwriting it.
- Responsive Material 3 layout and empty/loading/error states.

`lib/clinic.dart` contains framework-independent booking/state logic; `lib/main.dart` contains the UI and storage boundary. Tests cover booking conflicts, terminal state transitions, JSON persistence, invalid inputs and a widget booking/cancellation/restart flow. `tool/check_domain.dart` is a dependency-free Dart smoke runner.

## Checks and status

```sh
dart tool/check_domain.dart
flutter analyze
flutter test
flutter build web
```

The Dart domain smoke runner and `dart analyze lib/clinic.dart` passed during this update. Source files were formatted with Dart. **Flutter UI analysis, widget tests and platform builds were not executed successfully in the build environment.** The included GitHub Actions workflow is prepared but has not run. Run these checks locally before considering the app release-ready.

## Scope

The role selector is a workflow demonstration, not authentication. Firebase, cloud synchronization, doctor/patient authorization, payment, notifications, multi-device booking concurrency and real clinic schedules are unimplemented. All appointments are visible to anyone using this local demo. SharedPreferences is not encrypted clinical storage. Use fictional data only. Fees are sample values, not real clinic quotations.
