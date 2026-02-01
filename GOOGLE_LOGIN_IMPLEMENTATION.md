# Google Login Implementation Guide

## Overview
This document describes the Google Sign-In implementation for DiscountBuddy mobile app (Flutter).

## Implementation Summary

### 1. Get Google ID Token (Step 1)
**Location:** `lib/services/auth_service.dart` - `loginWithGoogle()` method

```dart
// Trigger Google Sign-In flow
final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

// Get authentication details including ID token
final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

// Extract the ID token (JWT)
String idToken = googleAuth.idToken;
```

### 2. Call Backend API (Step 2)
**Endpoint:** `POST /api/users/google`

**Request Body:**
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIs..."
}
```

**Implementation:**
```dart
final response = await _apiService.post(
  '/users/google',
  body: {
    'id_token': googleAuth.idToken,
  },
);
```

### 3. Handle API Response (Step 3)
**Expected Success Response (200):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "user123",
    ...
  },
  "username": "user123",
  "role": "customer",
  "is_merchant": false,
  "is_customer": true
}
```

**Token Storage:**
- Access token stored in: `FlutterSecureStorage` with key `access_token`
- Refresh token stored in: `FlutterSecureStorage` with key `refresh_token`
- User data stored in: `FlutterSecureStorage` with key `user_data`

**Error Responses:**
- `400` - Missing token: `{"detail": "id_token or credential is required."}`
- `401` - Invalid/expired Google token: `{"detail": "Invalid Google ID token: ..."}`
- `500` - Backend misconfiguration: `{"detail": "Google OAuth is not configured."}`

### 4. Use JWT for Authenticated Requests (Step 4)
**Implementation:** `lib/services/api_service.dart`

All authenticated API calls automatically include:
```
Authorization: Bearer <access_token>
```

**Token Refresh Flow:**
When access token expires (401 response), the app will:
1. Call `POST /api/users/token/refresh` with `{"refresh": "<refresh_token>"}`
2. Get new access token from response
3. Update stored access token
4. Retry the original request

**Implementation:** `lib/services/auth_service.dart` - `refreshAccessToken()` method

## File Structure

### Core Files Modified/Created:
1. **`lib/services/auth_service.dart`**
   - Added `GoogleSignIn` instance
   - Implemented `loginWithGoogle()` method
   - Updated `logout()` to sign out from Google

2. **`lib/providers/auth_provider.dart`**
   - Added `loginWithGoogle()` to manage state
   - Handles loading states and error messages

3. **`lib/pages/auth/login_page.dart`**
   - Added "Continue with Google" button
   - Implemented `_handleGoogleLogin()` method

4. **`lib/pages/auth/register_page.dart`**
   - Added "Continue with Google" button
   - Implemented `_handleGoogleLogin()` method

## Platform Configuration Required

### Android Setup:
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/` directory
3. Ensure `android/app/build.gradle` includes:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### iOS Setup:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/` directory
3. Add to Xcode project
4. Add URL scheme to `Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

## Backend API Endpoint

Your backend must implement:
```
POST /api/users/google
```

**Request:**
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIs..."
}
```

**Response:**
```json
{
  "access": "JWT_ACCESS_TOKEN",
  "refresh": "JWT_REFRESH_TOKEN",
  "user": { ... },
  "username": "...",
  "role": "customer|merchant",
  "is_merchant": false,
  "is_customer": true
}
```

## Testing

### Test Flow:
1. Run the app on a device/emulator
2. Navigate to Login or Register page
3. Tap "Continue with Google"
4. Select Google account
5. App should:
   - Get ID token from Google
   - Send to backend
   - Receive and store JWT tokens
   - Navigate to home screen

### Debug Logging:
Enable API logging in `lib/config/environment.dart`:
```dart
static const bool enableLogging = true;
```

This will log:
- API endpoints being called
- Request bodies
- Response status codes
- Response bodies

## Security Notes

1. **ID Token Validation:** Backend must validate the Google ID token signature and claims
2. **Secure Storage:** Tokens are stored using `FlutterSecureStorage` (encrypted on device)
3. **Token Expiry:** Access tokens expire; refresh token is used to get new access tokens
4. **HTTPS Only:** All API calls must use HTTPS in production

## Dependencies

```yaml
dependencies:
  google_sign_in: ^6.2.1
  flutter_secure_storage: ^9.0.0
  http: ^1.2.0
```

## Client ID Information

From your provided JSON:
- **Client ID:** `1019573233560-qdrakgr5gr19rej8ck4ekmtqe7ert74c.apps.googleusercontent.com`
- **Project ID:** `discountbuddy`

This client ID can be used for web applications. For mobile apps, you'll need platform-specific client IDs from Firebase Console.
