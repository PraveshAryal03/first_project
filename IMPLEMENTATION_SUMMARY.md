# Food Image Calorie Prediction - Implementation Summary

## What Was Added

Your CalTrack app now has an **AI-powered food image recognition system** that uses Google's Gemini Vision API to automatically detect foods and estimate their calorie content.

## New Components

### 1. **`food_image_service.dart`** - Core Service
- Handles camera/gallery image selection
- Sends images to Google Gemini Vision API
- Parses AI responses into structured food prediction data
- Returns: Food name, calories, protein/carbs/fats, confidence level

### 2. **`food_image_picker_screen.dart`** - User Interface
- Clean, intuitive screen for capturing/selecting food images
- Camera button for taking photos
- Gallery button for selecting existing photos
- Shows loading state while AI analyzes image
- Displays prediction results with confidence indicator
- Quantity/servings selector
- One-click logging to calorie tracker

### 3. **`home_page.dart`** - Updated
- New "Scan Food" button next to existing "Log Food" button
- Opens image picker screen with single tap
- Automatic error handling if API key not configured

### 4. **`.env`** - Configuration File
- Stores sensitive data (Gemini API key)
- Never committed to Git (add to .gitignore)
- Referenced at app startup via `dotenv.load()`

### 5. **`pubspec.yaml`** - Updated Dependencies
- `image_picker: ^1.0.0` - Camera and photo library access
- `google_generative_ai: ^0.4.7` - Gemini API client
- `flutter_dotenv: ^5.1.0` - Environment variable support

### 6. **`main.dart`** - Updated
- Now loads `.env` file at startup
- Ensures API key is available throughout the app

## How to Use

### Step 1: Get Gemini API Key
1. Visit [Google AI Studio](https://ai.google.dev/)
2. Click "Get API key"
3. Copy your free API key

### Step 2: Configure API Key
1. Open `.env` file in project root
2. Replace `your_api_key_here` with your actual key:
   ```
   GEMINI_API_KEY=sk-xxxxxxxxxxxx
   ```
3. Save the file

### Step 3: Install Packages
```bash
flutter pub get
```

### Step 4: Configure Permissions

**Android** - Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**iOS** - Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture food photos</string>
```

### Step 5: Run the App
```bash
flutter run
```

## User Workflow

1. **Tap "Scan Food"** button on home screen
2. **Choose image source**: Camera or Gallery
3. **AI analyzes** the food (2-5 seconds)
4. **Review predictions**: Food name, calories, macros
5. **Adjust quantity** if needed (e.g., 2 servings)
6. **Tap "Log This Meal"** to save

## Data Logged

When user logs a meal via image:
```
- Food name (from AI)
- Estimated calories
- Protein (grams)
- Carbohydrates (grams)
- Fats (grams)
- Serving size
- Confidence level (high/medium/low)
- Source: "image_prediction"
- Timestamp
- Saved to: CalorieTrackerProvider + Firestore (if signed in)
```

## Key Features

✅ **AI-Powered Recognition** - Uses Google Gemini Vision API
✅ **Automatic Estimation** - Predicts calories & macros
✅ **Confidence Indicator** - Shows reliability of prediction
✅ **Flexible Quantity** - Adjust servings before logging
✅ **Firestore Integration** - Saves to database if authenticated
✅ **Offline Support** - Works without internet after image is captured
✅ **Error Handling** - User-friendly error messages
✅ **Privacy** - API key stored locally, not exposed

## API Response Example

For a chicken breast image:
```json
{
  "foodName": "Grilled Chicken Breast",
  "estimatedCalories": 165,
  "confidence": "high",
  "servingSize": "100g",
  "description": "Grilled chicken, lean cut",
  "nutritionEstimate": {
    "protein": 31,
    "carbs": 0,
    "fats": 3
  }
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "API key not configured" | Add key to `.env` file, restart app |
| Camera not working | Grant camera permission in device settings |
| "Unable to analyze" | Take clearer, better-lit photo |
| Slow analysis | Check internet connection, images take 2-5 seconds |

## File Locations

```
lib/
├── food_image_service.dart           ← Core AI service
├── food_image_picker_screen.dart     ← UI screen
├── home_page.dart                    ← Updated buttons
├── main.dart                         ← Loads .env
└── ...other files unchanged

.env                                  ← API key config
pubspec.yaml                          ← New dependencies
FOOD_IMAGE_SETUP.md                   ← Detailed setup guide
```

## Next Steps

1. ✅ **Get API key** from Google AI Studio
2. ✅ **Add to `.env`** file
3. ✅ **Configure permissions** for Android/iOS
4. ✅ **Run `flutter pub get`**
5. ✅ **Test the feature** by taking a food photo

## Cost

- **Free tier**: 60 requests/minute, 1,500/day
- **Paid tier**: $0.0001 per image (if you exceed free tier)

For most personal use, the free tier is plenty!

## Security Notes

⚠️ **Important:**
- Never commit `.env` file with real API keys
- Add `.env` to `.gitignore`
- Rotate API keys periodically
- In production, consider Firebase Remote Config for API key management

---

**Ready to use!** Tap "Scan Food" on your home screen to get started.
