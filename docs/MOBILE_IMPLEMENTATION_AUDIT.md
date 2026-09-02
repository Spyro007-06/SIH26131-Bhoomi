# Bhoomi Farmer App — Mobile Implementation Audit

**Document Status:** Complete Implementation Audit  
**Target Module:** `app/` (Flutter Mobile Client)  
**Date of Audit:** September 2026  
**Auditor:** Senior Flutter Mobile Engineer  
**Reference Frozen Docs:** `docs/PRD.md`, `docs/DESIGN.md`, `docs/API_CONTRACT.md`, `CLAUDE.md`, `app/README.md`

---

## 1. Executive Summary

A comprehensive implementation audit was conducted across the entire Bhoomi Flutter codebase (`app/`). The Flutter application possesses a clean, modular architecture based on **Feature-Driven Development**, **Flutter Riverpod (2.5.1)** for state management, **Dio (5.4.3+1)** for HTTP networking with structured error handling, **Flutter Secure Storage (9.2.2)** for cryptographic credential persistence, and a custom design system adhering to the rural UI/UX specifications in `docs/PRD.md` and `docs/DESIGN.md`.

All **144 automated unit and widget tests pass cleanly**, and `flutter analyze` reports **0 lint or static analysis issues**.

However, several hardware-interacting capabilities (Camera capture, GPS geolocation, Microphone recording, and Audio playback) are currently **mocked or stubbed with synthetic fixtures** in the presentation and utility layers rather than binding to native device sensors and hardware APIs. Furthermore, native platform harnesses (`android/` and `ios/`) have not yet been generated.

---

## 2. Verification Suite Results

### 2.1 Static Analysis (`flutter analyze`)
```
Analyzing app...
No issues found! (ran in 1.6s)
```
- **Exit Code:** `0`
- **Lint Rules:** Strict conformance to `package:flutter_lints/flutter.yaml`.

### 2.2 Test Suite Execution (`flutter test`)
```
00:08 +144: All tests passed!
```
- **Exit Code:** `0`
- **Total Test Files:** 38 test suites in `app/test/`
- **Total Tests:** 144 unit, widget, and integration tests passed across all core modules, repositories, gate deciders, and UI workflows.

---

## 3. Detailed Audit Matrix (13 Core Dimensions)

### 3.1 Flutter Project Structure
* **Architecture Pattern:** Feature-driven modular layered architecture (Presentation, Domain/Models, Data/Repositories, Providers, Core Infrastructure).
* **Source Tree (`app/lib/`):**
  * `lib/core/`
    * `config/` (`demo_config.dart`): Static configuration for SIH demo presentations.
    * `constants/` (`api_endpoints.dart`, `app_constants.dart`, `demo_fixtures.dart`): Centralized endpoints and offline fallback fixtures.
    * `error/` (`app_exception.dart`, `error_handler.dart`): Typed domain exception hierarchy mapped to `docs/API_CONTRACT.md` §0 error codes (`BhoomiError`).
    * `localization/` (`app_strings.dart`, `locale_provider.dart`): Tri-lingual in-memory dictionary and Riverpod locale state notifier.
    * `network/` (`api_client.dart`, `api_config.dart`, `auth_interceptor.dart`): Dio HTTP client with JWT injection and separate unauthenticated binary upload client.
    * `storage/` (`secure_storage.dart`, `token_storage.dart`): Encrypted key-value storage layer.
    * `theme/` (`app_colors.dart`, `app_radius.dart`, `app_spacing.dart`, `app_theme.dart`, `app_typography.dart`): PRD-compliant design tokens (Soil Charcoal, Rice Paper, Forest Green, Turmeric, min 48px touch targets).
    * `utils/` (`connectivity_checker.dart`, `location_service.dart`, `media_upload_helper.dart`): Helper utilities.
  * `lib/features/`: 13 distinct feature packages (`advisory`, `alerts`, `diagnose`, `doubt_doctor`, `followup`, `home`, `label_check`, `landing`, `more`, `onboarding`, `referrals`, `shell`, `showcase`, `splash`, `timeline`).
  * `lib/models/`: 14 strongly typed Dart models mirroring wire shapes (C1, C2, C3).
  * `lib/providers/`: Riverpod `Provider`, `FutureProvider`, and `StateNotifierProvider` bindings.
  * `lib/repositories/`: 11 repository interfaces and implementations.
  * `lib/widgets/`: 18 tactile, accessible UI components.

---

### 3.2 Android / iOS Platform Targets
* **Current Status:** **MISSING PLATFORM HARNESSES**.
* **Confirmed Gaps:**
  * The `app/` directory does not contain `android/` or `ios/` platform directories.
  * Missing Android manifest (`AndroidManifest.xml`), Gradle configuration (`build.gradle`, `settings.gradle`, Gradle wrapper), and `MainActivity`.
  * Missing iOS configuration (`Info.plist`, `Podfile`, `Runner.xcworkspace`).
* **Platform-Specific Requirements:**
  * **Android:** Must configure `minSdkVersion 21+`, `targetSdkVersion 34`, AndroidX, and runtime permissions in `AndroidManifest.xml`.
  * **iOS:** Must configure camera (`NSCameraUsageDescription`), microphone (`NSMicrophoneUsageDescription`), and location (`NSLocationWhenInUseUsageDescription`) strings in `Info.plist`.

---

### 3.3 Dependencies Audit (`pubspec.yaml`)
* **Existing Dependencies:**
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    flutter_localizations:
      sdk: flutter
    intl: '>=0.19.0 <1.0.0'
    dio: ^5.4.3+1
    flutter_riverpod: ^2.5.1
    flutter_secure_storage: ^9.2.2

  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: ^3.0.0
  ```
* **Missing Native Hardware & Utility Dependencies:**
  1. `camera: ^0.11.0+` or `image_picker: ^1.1.2` (Device camera preview and photo capture)
  2. `flutter_image_compress: ^2.3.0` (Client-side image compression before presigned upload)
  3. `geolocator: ^12.0.0` or `location: ^7.0.0` (Native GPS coordinates acquisition and location services check)
  4. `record: ^5.1.2` or `speech_to_text: ^6.6.0` (Microphone audio recording for voice queries)
  5. `audioplayers: ^6.0.0` or `just_audio: ^0.9.38` or `flutter_tts: ^4.0.2` (Playback of synthesized voice audio and spoken summaries)
  6. `permission_handler: ^11.3.1` (OS runtime permission check/request flows)
  7. `connectivity_plus: ^6.0.3` (Live network status monitoring and offline stream)
  8. `path_provider: ^2.1.3` (Temporary file storage for audio recording bytes and compressed images)

---

### 3.4 Camera Implementation
* **Files:**
  * [camera_capture_screen.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/features/diagnose/presentation/camera_capture_screen.dart)
  * [image_preview_screen.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/features/diagnose/presentation/image_preview_screen.dart)
* **Confirmed Gaps & Stubs:**
  * **Synthetic JPEG Generator (Lines 30–37):**
    ```dart
    Uint8List _generateSampleLeafBytes() {
      return Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, ...
      ]);
    }
    ```
  * **Simulated Viewfinder (Lines 143–213):** The camera viewfinder renders a static green leaf icon `Icon(Icons.eco_rounded, ...)` with reticle borders rather than a live `CameraPreview` bound to a hardware `CameraController`.
  * **Mock Actions (Lines 39–71):** Both `_onCapturePressed()` and `_onGalleryPressed()` simply inject the 38-byte dummy sample into `diagnosisControllerProvider`.
  * **Flash Button (Line 289):** Shows a mock snackbar (`'Camera lighting optimized for field sunlight.'`) without triggering torch hardware.

---

### 3.5 GPS / Location Implementation
* **Files:**
  * [location_service.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/utils/location_service.dart#L30-L51)
  * [farm_setup_screen.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/features/onboarding/presentation/farm_setup_screen.dart#L54-L70)
* **Confirmed Gaps & Stubs:**
  * **Hardcoded Coordinates (Lines 39–42):**
    ```dart
    return const LocationResult(
      location: GeoPoint(lat: 19.9975, lng: 73.7898), // Fixed Nashik coordinates
      status: LocationServiceStatus.acquired,
    );
    ```
  * No integration with `geolocator` or platform location channels.
  * No GPS sensor availability verification, timeout handling, or location settings prompt.

---

### 3.6 Voice Implementation (F9 / Cross-screen)
* **Files:**
  * [voice_repository.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/repositories/voice_repository.dart)
  * [farmer_voice_assistant.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/farmer_voice_assistant.dart)
  * [spoken_summary_player.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/spoken_summary_player.dart)
* **Confirmed Gaps & Stubs:**
  * **API Contracts Present:** Repositories correctly define `POST /api/v1/voice/transcribe` and `POST /api/v1/voice/synthesize`.
  * **Mock Recording (`farmer_voice_assistant.dart` L128–132):**
    ```dart
    final result = await voiceRepo.transcribe(
      assetId: 'audio_mock_asset',
      lang: language.localeIdentifier,
      context: widget.initialContext ?? 'query',
    );
    ```
    No microphone audio recording package is present; calls pass a hardcoded mock asset ID.
  * **Mock Audio Playback (`spoken_summary_player.dart` L53–80):** UI triggers a simulated `_waveController` animation without piping synthesized audio bytes to a media player or TTS engine.

---

### 3.7 Runtime Permissions
* **Files:**
  * [farmer_voice_assistant.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/farmer_voice_assistant.dart#L871-L915)
  * [farm_setup_screen.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/features/onboarding/presentation/farm_setup_screen.dart#L79-L85)
* **Confirmed Gaps:**
  * Permission denial UI flows and dialog messages are fully designed and localized in `AppStrings`.
  * However, no native OS permission requests occur because `permission_handler` is not integrated.

---

### 3.8 Networking & Retry Behavior
* **Files:**
  * [api_client.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/network/api_client.dart)
  * [auth_interceptor.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/network/auth_interceptor.dart)
  * [error_handler.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/error/error_handler.dart)
  * [connectivity_checker.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/utils/connectivity_checker.dart)
* **Audit Findings:**
  * Configurable base URL via `--dart-define=BHOOMI_API_URL=...` or defaults (`http://10.0.2.2:8000/api/v1` for Android emulator, `http://localhost:8000/api/v1` for desktop/tests).
  * Timeouts configured: 15 seconds for API calls, 30–60 seconds for binary media uploads.
  * Conformance to `docs/API_CONTRACT.md` §0 error envelope parsing (`code`, `message`, `details`).
  * **Retry Gap:** Automated exponential backoff retry at the HTTP client level for idempotent network/503 errors is not present (manual retries are wired through UI `AppErrorState` and `ref.refresh`).

---

### 3.9 Authentication & Token Handling
* **Files:**
  * [token_storage.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/storage/token_storage.dart)
  * [secure_storage.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/storage/secure_storage.dart)
  * [auth_providers.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/providers/auth_providers.dart)
  * [auth_repository.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/repositories/auth_repository.dart)
* **Audit Findings:**
  * Tokens stored encrypted in Android Keystore / iOS Keychain (`bhoomi_access_token`, `bhoomi_refresh_token`, `bhoomi_user_data`, `bhoomi_active_farm_id`).
  * `AuthNotifier` exposes `checkAuthStatus()`, `requestOtp()`, `verifyOtp()`, `loginAsDemo()`, and `logout()`.
  * `logout()` cleanses all tokens and invalidates active farm providers.
  * **Gap:** Silent refresh loop is absent (API_CONTRACT §2 does not declare a token refresh endpoint, but on 401 the client triggers session expiry to redirect to login).

---

### 3.10 Image Upload Pipeline
* **Files:**
  * [asset_repository.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/repositories/asset_repository.dart#L21-L42)
  * [media_upload_helper.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/utils/media_upload_helper.dart)
  * [diagnosis_controller.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/features/diagnose/presentation/diagnosis_controller.dart#L90-L126)
* **Audit Findings:**
  * Strict adherence to `docs/API_CONTRACT.md` §3 invariant: **Presigned Object Storage Upload**.
    1. Step 1: `POST /api/v1/assets/presign` -> gets `upload_url`, `asset_id`.
    2. Step 2: Binary `PUT` raw image stream to MinIO/S3 via unauthenticated `_uploadDio`.
    3. Step 3: Passes `asset_id` to `POST /api/v1/farms/{id}/diagnose` or `POST /api/v1/problems/{id}/label-check`.
  * Safety cap validation: 10MB for images, 15MB for audio.
  * **Gap:** Missing client-side image downscaling/compression before sending to `uploadImage()`.

---

### 3.11 Localization (l10n)
* **Files:**
  * [app_strings.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/localization/app_strings.dart) (1,208 lines)
  * [locale_provider.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/localization/locale_provider.dart)
  * `app/lib/l10n/` (`app_en.arb`, `app_hi.arb`, `app_mr.arb`)
* **Audit Findings:**
  * Supported languages: **Marathi** (`mr-IN`, primary), **Hindi** (`hi-IN`), **Indian English** (`en-IN`).
  * `AppStrings` provides 1,208 lines of exhaustive, strongly-typed, tri-lingual string definitions used across all screens.
  * Selected locale is persisted in encrypted storage.
  * `app_en.arb` files in `lib/l10n/` are partial (~58 keys) and currently unused since UI exclusively consumes `AppStrings` through `stringsProvider`.

---

### 3.12 Accessibility (a11y)
* **Files:**
  * [app_colors.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/theme/app_colors.dart)
  * [app_typography.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/theme/app_typography.dart)
  * [app_button.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/app_button.dart)
* **Audit Findings:**
  * High-contrast outdoor color ratios (Rice Paper `#F7F5EE`, Warm Surface `#FFFDF8`, Soil Charcoal `#202A25`, Forest Green `#245C45`, Turmeric `#D69A2D`).
  * Minimum touch targets enforced (48px–56px for primary farmer buttons).
  * Explicit `Semantics` tags on icon buttons and voice toggles.
  * Validated for dynamic text scaling at 1.0x, 1.5x, and 2.0x without visual clipping or overflow errors in `accessibility_and_scaling_test.dart`.

---

### 3.13 Existing Tests Suite Summary
* **Test Directory:** `app/test/` (38 test files, 144 tests)
* **Key Test Coverage Areas:**
  * `api_contract_audit_test.dart`: Complete wire contract verification against `docs/API_CONTRACT.md`.
  * `auth_flow_test.dart` & `logout_flow_test.dart`: Phone auth, OTP verification, demo login, session cleanup.
  * `confidence_gate_routing_test.dart` & `diagnosis_polymorphism_test.dart`: C1/C3 gate verification (`advise`, `clarify`, `escalate`, `is_stub` banner).
  * `gps_location_service_test.dart`: Location model serialization and state handling.
  * `camera_preview_flow_test.dart`: Capture workflow and preview state machine.
  * `step8_production_integration_test.dart`: End-to-end multi-step farmer flow simulation.

---

## 4. Contract Safety Invariants Compliance

| Contract Invariant (`docs/API_CONTRACT.md` §17) | App Implementation Status | Line Reference |
|---|---|---|
| **Invariant 1: Presigned Media Upload** | **Compliant** | [asset_repository.dart:82-105](file:///d:/Project/SIH26131-Bhoomi/app/lib/repositories/asset_repository.dart#L82-L105) |
| **Invariant 2: Spoken Summary Local Playback** | **Compliant** (UI) | [spoken_summary_player.dart:10-40](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/spoken_summary_player.dart#L10-L40) |
| **Invariant 3: Verbatim Treatment / No Pesticide Composition** | **Compliant** | [advisory_ipm_card.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/advisory_ipm_card.dart) |
| **Invariant 11: Mandatory `is_stub: true` Banner** | **Compliant** | [stub_banner.dart:1-83](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/stub_banner.dart#L1-L83) |

---

## 5. Risk Assessment

1. **Hardware Integration Gap (Medium Risk):**
   * Running the app on a physical Android device currently produces synthetic JPEG bytes and hardcoded Nashik coordinates.
   * *Mitigation:* Integrate official `camera`, `geolocator`, and `record` packages behind the existing service abstractions.
2. **Missing Platform Scaffold (Medium Risk):**
   * Without `app/android/`, standard Gradle builds (`flutter build apk`) cannot be executed.
   * *Mitigation:* Execute `flutter create . --platforms=android,ios` to create native runners and add required permissions to `AndroidManifest.xml`.
3. **Large Image Uploads over 2G/3G Networks (Low-Medium Risk):**
   * Uncompressed multi-megabyte photos from modern smartphone sensors could fail on rural cellular uplinks.
   * *Mitigation:* Add client-side JPEG compression (`flutter_image_compress`) capping image dimensions to ~1600px width / ~80% quality prior to presigned upload.

---

## 6. Recommended Implementation Order

To transition from the current verified UI prototype/mock state to a field-ready production Android application, execute the following steps in sequence:

### Phase 1: Platform Scaffolding & Native Harness Setup
1. Run `flutter create . --project-name bhoomi --platforms=android,ios` in `app/`.
2. Configure Android `minSdkVersion 21`, `targetSdkVersion 34` in `app/android/app/build.gradle`.
3. Add hardware permissions to `app/android/app/src/main/AndroidManifest.xml`:
   * `android.permission.CAMERA`
   * `android.permission.RECORD_AUDIO`
   * `android.permission.ACCESS_FINE_LOCATION`
   * `android.permission.ACCESS_COARSE_LOCATION`
   * `android.permission.INTERNET`
4. Add iOS permission description strings to `app/ios/Runner/Info.plist`.

### Phase 2: Native Hardware & Sensor Integration
1. Add dependencies to `app/pubspec.yaml`:
   * `camera`, `geolocator`, `record`, `audioplayers` (or `flutter_tts`), `permission_handler`, `flutter_image_compress`, `connectivity_plus`, `path_provider`.
2. Implement real device GPS in [location_service.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/utils/location_service.dart) using `geolocator`.
3. Replace synthetic leaf bytes with real `CameraController` and `CameraPreview` in [camera_capture_screen.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/features/diagnose/presentation/camera_capture_screen.dart).
4. Implement audio capture in [farmer_voice_assistant.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/farmer_voice_assistant.dart) using `record` and pipe recorded bytes to `assetRepo.uploadAudio()`.
5. Implement audio playback in [spoken_summary_player.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/widgets/spoken_summary_player.dart) using `audioplayers` or `flutter_tts`.

### Phase 3: Image Optimization & Network Resilience
1. Integrate `flutter_image_compress` in [media_upload_helper.dart](file:///d:/Project/SIH26131-Bhoomi/app/lib/core/utils/media_upload_helper.dart) before triggering `uploadImage()`.
2. Add a Dio retry interceptor with exponential backoff for idempotent GET queries and transient timeouts.

---

## 7. Verification Commands

To verify the app at any stage:

```bash
# Navigate to Flutter app root
cd app

# 1. Static analysis and lint verification
flutter analyze

# 2. Run complete automated test suite
flutter test

# 3. Run individual critical test suites
flutter test test/step8_production_integration_test.dart
flutter test test/api_contract_audit_test.dart
flutter test test/confidence_gate_routing_test.dart
flutter test test/accessibility_and_scaling_test.dart

# 4. Generate Android APK (once Phase 1 scaffolding is run)
flutter build apk --debug
```
