# Firebase Setup Guide for DiscountBuddy

## ✅ What's Already Done

1. ✅ Firebase dependencies added to `pubspec.yaml`
2. ✅ Firebase initialized in `main.dart`
3. ✅ Firebase Messaging service created
4. ✅ Background message handler configured
5. ✅ Foreground message listener set up

## 🔥 Firebase Configuration Required

You need to configure Firebase for your Android and iOS apps. Follow these steps:

### Step 1: Create Firebase Project (If Not Already Done)

According to your documentation, you already have:
- **Project ID:** `discount-buddy-d51bf`
- **Package:** `com.discountbuddy.app`

### Step 2: Add Firebase Configuration Files

#### For Android:

1. **Download `google-services.json`** from Firebase Console
   - Go to Firebase Console → Project Settings → Your Apps
   - Select your Android app
   - Download `google-services.json`

2. **Place the file:**
   ```
   android/app/google-services.json
   ```

3. **Update `android/build.gradle`:**
   ```gradle
   buildscript {
       dependencies {
           // Add this line
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```

4. **Update `android/app/build.gradle`:**
   ```gradle
   // At the bottom of the file, add:
   apply plugin: 'com.google.gms.google-services'
   ```

#### For iOS:

1. **Download `GoogleService-Info.plist`** from Firebase Console
   - Go to Firebase Console → Project Settings → Your Apps
   - Select your iOS app
   - Download `GoogleService-Info.plist`

2. **Place the file:**
   ```
   ios/Runner/GoogleService-Info.plist
   ```

3. **Update `ios/Runner/Info.plist`:**
   ```xml
   <key>FirebaseAppDelegateProxyEnabled</key>
   <false/>
   ```

### Step 3: Run Flutter Pub Get

```bash
cd /Users/priyansuchavda/Documents/DiscountBuddy
flutter pub get
```

### Step 4: Update Android Manifest (For Notifications)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <application>
        <!-- Add these inside <application> tag -->
        
        <!-- Firebase Messaging Service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- Default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
            
        <!-- Notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
            
        <!-- Notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
    
    <!-- Add permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
</manifest>
```

### Step 5: iOS Capabilities (For Push Notifications)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your project → Runner → Signing & Capabilities
3. Click "+ Capability" and add:
   - **Push Notifications**
   - **Background Modes** (check "Remote notifications")

## 📱 How It Works Now

### On App Launch:
```dart
1. Firebase.initializeApp() - Initializes Firebase
2. _initializeFirebaseMessaging() - Requests permissions and gets FCM token
3. Token is printed to console (for testing)
```

### When User Logs In:
You need to call the Firebase service to register the token:

```dart
// In your login success handler
import 'package:discount_buddy/services/firebase_messaging_service.dart';

// After successful login
await FirebaseMessagingService().registerTokenAfterLogin();
```

### When User Logs Out:
```dart
// In your logout handler
await FirebaseMessagingService().deactivateTokenOnLogout(tokenId);
```

### Receiving Notifications:

#### Foreground (App is open):
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Received: ${message.notification?.title}');
  // Show in-app notification or update badge
});
```

#### Background (App is minimized):
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('Notification tapped: ${message.notification?.title}');
  // Navigate to specific screen
});
```

#### Terminated (App is closed):
Handled by `_firebaseMessagingBackgroundHandler` in main.dart

## 🧪 Testing

### 1. Check FCM Token
Run the app and check the console for:
```
📱 FCM Token: fGcM_dEvIcE_tOkEn_HeRe...
```

### 2. Test from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Select your app
5. Send test message

### 3. Test from Backend
Use your backend to send a test notification:
```python
from notifications.services import NotificationService

NotificationService.create_notification(
    user=user,
    title="Test Push Notification",
    message="This is a test",
    notification_type="SYSTEM",
    send_push=True  # This will trigger FCM
)
```

## 🔧 Integration with Auth Service

Update your `AuthService` to register FCM token after login:

```dart
// In lib/services/auth_service.dart

import 'firebase_messaging_service.dart';

class AuthService {
  final FirebaseMessagingService _fcmService = FirebaseMessagingService();
  
  Future<void> login(String email, String password) async {
    // ... existing login code ...
    
    // After successful login
    if (loginSuccess) {
      // Register FCM token with backend
      await _fcmService.registerTokenAfterLogin();
    }
  }
  
  Future<void> logout() async {
    // Get stored token ID before logout
    // final tokenId = await getStoredTokenId();
    
    // ... existing logout code ...
    
    // Deactivate FCM token
    // if (tokenId != null) {
    //   await _fcmService.deactivateTokenOnLogout(tokenId);
    // }
  }
}
```

## 📋 Checklist

- [ ] Add `google-services.json` to `android/app/`
- [ ] Add `GoogleService-Info.plist` to `ios/Runner/`
- [ ] Update `android/build.gradle` with Google Services plugin
- [ ] Update `android/app/build.gradle` with Google Services plugin
- [ ] Update `AndroidManifest.xml` with notification permissions
- [ ] Add Push Notifications capability in Xcode
- [ ] Run `flutter pub get`
- [ ] Test FCM token generation
- [ ] Integrate with AuthService
- [ ] Test push notifications from Firebase Console
- [ ] Test push notifications from backend

## 🎯 Next Steps

1. **Get Firebase config files** from Firebase Console
2. **Place them in correct locations** (see above)
3. **Run `flutter pub get`**
4. **Test the app** - check console for FCM token
5. **Send test notification** from Firebase Console
6. **Integrate with login/logout** in AuthService

## 📞 Troubleshooting

### Token not generated?
- Check if permissions are granted
- Check Firebase config files are in correct location
- Check console for errors

### Notifications not received?
- Check FCM token is registered with backend
- Check notification permissions are granted
- Check Firebase Console for delivery status

### Build errors?
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app

## 🔗 Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Your Backend Docs](./NOTIFICATION_API_REFERENCE.md)
