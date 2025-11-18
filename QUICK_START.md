# Quick Start Guide - Food Image Calorie Prediction

## 🚀 Get Started in 5 Minutes

### 1️⃣ Get Your API Key (1 minute)
- Go to: https://ai.google.dev/
- Click "Get API key"
- Copy your free API key

### 2️⃣ Add to .env File (1 minute)
1. Open `.env` in your project
2. Replace `your_api_key_here` with your actual key:
   ```
   GEMINI_API_KEY=your_actual_key_here
   ```

### 3️⃣ Install Packages (1 minute)
```bash
flutter pub get
```

### 4️⃣ Configure Permissions (2 minutes)

**Android:**
- Open `android/app/src/main/AndroidManifest.xml`
- Add (before `<application>`):
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  ```

**iOS:**
- Open `ios/Runner/Info.plist`
- Add these keys:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>We need camera access to capture food photos</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>We need access to your photo library</string>
  ```

### 5️⃣ Run the App
```bash
flutter run
```

---

## ✨ How to Use

1. **Tap "Scan Food"** button on home screen
2. **Choose**: Camera (take photo) or Gallery (select photo)
3. **Wait**: AI analyzes food (2-5 seconds)
4. **Review**: Food name, calories, protein/carbs/fats
5. **Adjust**: Change quantity if needed
6. **Log**: Tap "Log This Meal"

Done! Your food is now logged with automatic calorie prediction.

---

## 📋 What You Get

✅ **Food Recognition** - AI identifies what's in the photo
✅ **Calorie Estimation** - Predicts total calories
✅ **Macros** - Protein, carbs, fats breakdown
✅ **Confidence Score** - Shows how sure the AI is
✅ **Serving Size** - Estimates portion size
✅ **Firestore Sync** - Saves to database if signed in

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| App crashes on startup | Make sure `.env` file exists and `flutter pub get` was run |
| "API key not configured" error | Check `.env` file has correct key |
| Camera permission denied | Grant camera permission in device settings |
| Image won't analyze | Take a clearer, better-lit photo |

---

## 📚 Full Documentation

- **Detailed Setup**: See `FOOD_IMAGE_SETUP.md`
- **Permissions Help**: See `PERMISSIONS_SETUP.md`
- **Implementation Details**: See `IMPLEMENTATION_SUMMARY.md`

---

## 💡 Tips

- 📷 **Good lighting** = Better AI accuracy
- 🍽️ **Single meal** = Take one photo per meal
- ⏱️ **Be patient** = AI takes 2-5 seconds to analyze
- ✔️ **Verify results** = Always check if prediction seems reasonable
- 🔢 **Adjust servings** = Change quantity before logging

---

## 🎯 What's New

Your app now has 2 ways to log food:

1. **Log Food** - Manual entry (name, calories, quantity)
2. **Scan Food** ← **NEW!** - AI-powered image recognition

Pick whichever works best for you!

---

## 📞 Need Help?

- Check `.env` file exists with valid API key
- Verify permissions in AndroidManifest.xml (Android) or Info.plist (iOS)
- Make sure you ran `flutter pub get`
- Check internet connection (needed for AI analysis)
- Try taking a clearer photo with better lighting

---

**Ready? Tap "Scan Food" and start!** 🎉
