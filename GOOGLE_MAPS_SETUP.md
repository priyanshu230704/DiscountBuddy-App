# Google Maps API Key Setup

## To fix the map view error:

1. **Get a Google Maps API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable "Maps SDK for Android"
   - Create credentials (API Key)
   - Restrict the key to "Maps SDK for Android" for security

2. **Add the API Key to AndroidManifest.xml:**
   - Open: `android/app/src/main/AndroidManifest.xml`
   - Find the line: `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY_HERE" />`
   - Replace `YOUR_API_KEY_HERE` with your actual API key

3. **For iOS (if needed):**
   - Open: `ios/Runner/AppDelegate.swift`
   - Add: `GMSServices.provideAPIKey("YOUR_API_KEY_HERE")`

## Note:
- The app will work fine in **List View** mode without the API key
- Only the **Map View** requires the API key
- You can use the app normally and add the API key later when ready

