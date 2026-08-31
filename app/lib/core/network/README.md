# Bhoomi Farmer App — Networking & API Architecture

This directory defines the HTTP client foundation, authentication interceptors, and network configuration for the Bhoomi Farmer App, connecting to the Bhoomi v2 backend (`/api/v1`).

---

## 1. API Base URL Configuration (`api_config.dart`)

The backend URL is centrally configured in `ApiConfig`.

- **Default Android Emulator:** `http://10.0.2.2:8000/api/v1`
- **Default Desktop / Test:** `http://localhost:8000/api/v1`
- **Compile-Time Override:**
  ```bash
  flutter run --dart-define=BHOOMI_API_URL=https://api.bhoomi.gov.in/api/v1
  ```
- **Custom Client Factory:**
  ```dart
  final customConfig = ApiConfig.custom('https://demo.bhoomi.internal/api/v1');
  ```

No endpoint URLs or backend hosts are hardcoded inside UI widgets or feature screens.

---

## 2. Authentication & Token Lifecycle (`auth_interceptor.dart`, `token_storage.dart`)

1. **Storage:**
   - JWT `access_token` and `refresh_token` are stored securely using `FlutterSecureStorage` (encrypted Keystore on Android, Keychain on iOS).
   - Tokens are **never** stored in plain `SharedPreferences` and **never** printed in application logs.

2. **Interceptor:**
   - `AuthInterceptor` automatically attaches `Authorization: Bearer <access_token>` to all protected endpoints.
   - Public endpoints (such as `POST /auth/otp/request`, `POST /auth/otp/verify`, and `GET /health`) are skipped automatically.

3. **No Phantom Refresh Endpoints:**
   - As per `API_CONTRACT.md`, only documented auth endpoints are implemented.

---

## 3. Presigned Media Upload Workflow (`asset_repository.dart`)

To prevent multi-megabyte image and audio payloads from choking the API server, raw media bytes are **never** uploaded directly to API endpoints.

### Workflow:
1. **Presign Request:** The client calls `POST /assets/presign` with `{ "kind": "image", "content_type": "image/jpeg", "farm_id": "..." }`.
2. **Presigned URL Received:** The server returns `{ "asset_id": "a_9", "upload_url": "https://storage...", "method": "PUT" }`.
3. **Binary PUT:** `ApiClient.uploadBinary()` executes a direct binary `PUT` with the exact `Content-Type` header directly to `upload_url` without the API `Authorization` header.
4. **Downstream Reference:** The returned `asset_id` (e.g. `a_9`) is referenced in subsequent API calls (e.g. `POST /farms/{id}/diagnose`).

---

## 4. Repository Layer & UI Boundary

The application enforces a clean unidirectional dependency graph:

```
Screen (Widget)
      ↓
Riverpod Provider
      ↓
Repository (e.g. DiagnosisRepository)
      ↓
ApiClient (Dio + AuthInterceptor)
      ↓
Backend API (/api/v1)
```

- **Widgets never import Dio or make direct HTTP calls.**
- **Repositories return typed wire models (`models/`) rather than raw JSON maps.**
- **All errors are caught and converted into normalized `AppException` instances by `ErrorHandler`.**

---

## 5. Adding a New Endpoint

When an endpoint is added to the frozen `docs/API_CONTRACT.md`:

1. **Add the Path Constant:**
   Define the path in [`lib/core/constants/api_endpoints.dart`](file:///f:/SIH26131-Bhoomi/app/lib/core/constants/api_endpoints.dart).
2. **Create/Update Model:**
   Add typed request/response models with `.fromJson()` and `.toJson()` in [`lib/models/`](file:///f:/SIH26131-Bhoomi/app/lib/models/).
3. **Add Repository Method:**
   Declare the method in the corresponding repository interface and implement it using `_apiClient.get()`, `_apiClient.post()`, etc.
4. **Expose Riverpod Provider:**
   Expose or inject the repository via [`lib/providers/repository_providers.dart`](file:///f:/SIH26131-Bhoomi/app/lib/providers/repository_providers.dart).
5. **Add Unit Tests:**
   Add serialization and repository mock tests in `test/`.
