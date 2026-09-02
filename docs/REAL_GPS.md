# Bhoomi Farmer App — Real Device Geolocation (P1 Hardening)

## 1. Executive Summary

This document details the production-grade geolocation architecture implemented for the **Bhoomi Farmer App** in `app/`. The mock location implementation (which returned static Nashik coordinates `19.9975, 73.7898`) has been completely removed from production code and replaced with a resilient, testable, real-device GPS service powered by `geolocator` and native platform channels.

---

## 2. Architecture & Abstraction Layer

To ensure zero production-test coupling and prevent native platform channel hangs or missing-plugin crashes during widget/unit tests, an injectable platform wrapper pattern is used.

```
┌─────────────────────────────────────────────────────────────┐
│                    FarmSetupScreen (UI)                     │
│  - Displays acquired coordinates                            │
│  - Handles retry, disabled GPS, permanently denied flows    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  LocationService (Core Utility)             │
│  - Manages permission state machine & timeouts              │
│  - Returns structured LocationResult                        │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                GeolocatorWrapper (Interface)                │
│  - isLocationServiceEnabled()                               │
│  - checkPermission() / requestPermission()                  │
│  - getCurrentPosition(desiredAccuracy, timeLimit)           │
│  - openAppSettings() / openLocationSettings()               │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
┌──────────────────────────────┐ ┌─────────────────────────────┐
│   DefaultGeolocatorWrapper   │ │    MockGeolocatorWrapper    │
│  - Production (Geolocator)   │ │  - Fast, headless test      │
│  - Timeout & channel guards  │ │    assertions with fakes    │
└──────────────────────────────┘ └─────────────────────────────┘
```

---

## 3. Native Platform Declarations

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-feature android:name="android.hardware.location.gps" android:required="false" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Bhoomi requires your farm's GPS location to provide accurate local pest advisories, weather forecasts, and route queries to your nearest Krishi Vigyan Kendra (KVK).</string>
```

---

## 4. Permission & Service Lifecycle State Machine

The `LocationService.getCurrentLocation()` method evaluates a robust state machine:

| Step | Check / Action | Possible Result | Handled State |
| :--- | :--- | :--- | :--- |
| **1** | `isLocationServiceEnabled()` | `false` | `LocationServiceStatus.disabled` |
| **2** | `checkPermission()` | `denied` | Trigger `requestPermission()` |
| **3** | Post-Request Status | `denied` | `LocationServiceStatus.denied` |
| **4** | Post-Request Status | `deniedForever` | `LocationServiceStatus.deniedForever` |
| **5** | Post-Request Status | `whileInUse` / `always` | Call `getCurrentPosition()` |
| **6** | Sensor Acquisition | Satellites acquired | `LocationServiceStatus.acquired` (`GeoPoint(lat, lng)`) |
| **7** | Timeout Guard | > 10 seconds | `LocationServiceStatus.timeout` |
| **8** | Hardware Error | Sensor fault / Channel error | `LocationServiceStatus.error` |

---

## 5. Farmer-Centric UX & Settings Recovery

In `FarmSetupScreen`, location state is visually presented to the farmer in their chosen language (Marathi, Hindi, or English):

1. **Detecting State**: Displays an animated progress indicator with localized message (`GPS स्थान शोधत आहे...`).
2. **Success State**: Displays a green checkmark with 4-decimal-place precision GPS coordinates (`स्थान निश्चित केले: Lat 19.8765, Lng 73.1234`) and enables the farm profile submission button.
3. **Denied State**: Displays a calm turmeric warning explaining why GPS is needed for crop alerts and provides a **Retry Location** button.
4. **Permanently Denied State**: Informs the farmer that permissions were permanently declined and surfaces an **Open Settings** button directly routing to App Settings via `openAppSettings()`.
5. **Disabled Location State**: Informs the farmer that device GPS is turned off and provides an **Open Settings** button directly opening the system Location Settings page via `openLocationSettings()`.
6. **Timeout State**: Advises the farmer that GPS satellite fix timed out in field conditions and provides a one-tap retry button.

---

## 6. Error Normalization

Location exceptions are cleanly encapsulated within `LocationResult` and integrated into the global `AppException` hierarchy via `LocationException`:
- Raw plugin exceptions (`PlatformException`, `MissingPluginException`) are intercepted and converted into user-friendly localized messages.
- Silent fallback to hardcoded coordinates is **strictly prohibited**.

---

## 7. Automated Test Suite & Coverage

The test suite covers every permutation of GPS acquisition:

* **`Real Device GPS LocationService Unit Tests`**:
  * ✅ Acquires real device coordinates when GPS and permissions are enabled.
  * ✅ Returns disabled status when device location services (GPS) are off.
  * ✅ Requests permission when initially denied and returns coordinates if granted.
  * ✅ Returns denied status when user rejects location permission.
  * ✅ Returns deniedForever status when location permission is permanently denied.
  * ✅ Handles timeout when GPS satellite acquisition exceeds duration limit.
  * ✅ Handles unexpected platform exceptions and maps to error status.
  * ✅ Delegates `openAppSettings` and `openLocationSettings` to platform wrapper.
* **`FarmSetupScreen GPS UI Integration Tests`**:
  * ✅ Acquires real device coordinates and displays them in `FarmSetupScreen`.
  * ✅ Handles denied location permission and provides retry option.
  * ✅ Handles permanently denied permission and shows settings recovery button.
  * ✅ Handles disabled location services and shows enable settings button.
* **Global Regression Verification**:
  * ✅ `flutter analyze`: **0 issues**
  * ✅ `flutter test`: **154 / 154 passed** across all 38 test suites
