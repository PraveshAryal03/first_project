# Food Image Calorie Prediction Setup Guide

This guide explains how to set up and use the AI-powered food image calorie prediction feature in your CalTrack app.

## Overview

The app now includes a "Scan Food" feature that allows users to:
1. Capture a photo of their food using the camera or select from gallery
2. Use Google's Gemini Vision API to analyze the image
3. Get automatic calorie and nutrition predictions
4. Log the food with predicted values

## Prerequisites

### 1. Google Gemini API Key

You need a **free** Google Gemini API key to use this feature.

**Steps to get your API key:**

1. Go to [Google AI Studio](https://ai.google.dev/)
2. Click "Get API key" button
3. Select or create a Google Cloud project
4. Generate a new API key
5. Copy the API key

### 2. Add API Key to Your App

1. Open the `.env` file in your project root directory
2. Replace `your_api_key_here` with your actual Gemini API key:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```
3. Save the file

**Important:** Never commit your `.env` file to version control. Add it to `.gitignore`:
```
.env
```

## Installation

### 1. Update Pubspec Dependencies

Run the following command to install required packages:

```bash
flutter pub get
```

The following packages have been added to `pubspec.yaml`:
- `image_picker: ^1.0.0` - Camera and gallery access
- `google_generative_ai: ^0.4.7` - Gemini API integration
- `flutter_dotenv: ^5.1.0` - Environment variable management

### 2. Configure Camera & Gallery Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add these permissions:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`)

Add these keys:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture food photos for calorie analysis</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select food images for calorie analysis</string>
```

## Features Implemented

### 1. **FoodImageService** (`lib/food_image_service.dart`)

Main service class that handles:
- **Image capture** from camera and gallery
- **AI analysis** using Gemini Vision API
- **JSON parsing** of API responses
- **Food prediction** model with nutrition data

**Key Methods:**
```dart
// Pick image from gallery
Future<File?> pickImageFromGallery()

// Capture image from camera
Future<File?> captureImageFromCamera()

// Predict calories from image
Future<FoodPrediction> predictFoodCalories(File imageFile)
```

**Prediction Model:**
```dart
class FoodPrediction {
  final String foodName;           // e.g., "Grilled Chicken Breast"
  final int estimatedCalories;     // e.g., 165
  final String confidence;         // "high", "medium", "low"
  final String servingSize;        // e.g., "100g"
  final String description;        // Brief analysis
  final int protein;               // grams
  final int carbs;                 // grams
  final int fats;                  // grams
}
```

### 2. **FoodImagePickerScreen** (`lib/food_image_picker_screen.dart`)

UI screen for the image capture flow:
- Camera button to take a photo
- Gallery button to select existing photo
- Loading state while analyzing
- Results display with confidence indicator
- Quantity selector for multiple servings
- Log button to save to your calorie tracker

### 3. **HomePage Update** (`lib/home_page.dart`)

Added "Scan Food" button next to "Log Food" button:
- Users can quickly access image-based food logging
- Error handling if API key is not configured
- Seamless navigation to image picker screen

## How It Works

### User Flow:

1. **User taps "Scan Food" button** on home screen
2. **Select image source**: Camera or Gallery
3. **App analyzes image** using Gemini Vision API (takes 2-5 seconds)
4. **AI returns predictions**: Food name, calories, protein/carbs/fats, serving size
5. **User adjusts quantity** if needed (default: 1 serving)
6. **User taps "Log This Meal"** to save to their calorie tracker
7. **Data is saved** to both app state and Firestore (if signed in)

### AI Analysis Process:

The Gemini API is prompted to:
- Identify the food item visible in the image
- Estimate calories per typical serving
- Assess confidence level (high/medium/low)
- Estimate macronutrient breakdown (protein, carbs, fats)
- Provide confidence indicator and description

**Note:** Estimates are intentionally conservative to avoid overestimating calorie intake.

## Example Prediction Response

For an image of a grilled chicken breast:

```json
{
  "foodName": "Grilled Chicken Breast",
  "estimatedCalories": 165,
  "confidence": "high",
  "servingSize": "100g (3.5 oz)",
  "description": "Grilled chicken breast, appears to be lean cut with no visible skin",
  "nutritionEstimate": {
    "protein": 31,
    "carbs": 0,
    "fats": 3
  }
}
```

## Troubleshooting

### "Gemini API key not configured" Error

**Solution:** 
- Ensure `.env` file exists in project root
- Verify `GEMINI_API_KEY=your_key` is set correctly
- Restart the app after updating `.env`

### Camera permission denied

**Solution:**
- Grant camera permission when prompted
- Check app permissions in device settings
- For iOS, ensure Info.plist has camera usage description

### "Unable to analyze image" Error

**Solution:**
- Ensure clear, well-lit photo of food
- API may reject blurry or unclear images
- Try a different angle or lighting
- Check internet connection

### API Rate Limiting

**Note:** Free Gemini API has rate limits. If you see errors:
- Wait a few seconds before trying again
- Consider upgrading to a paid plan if heavy usage
- Implement retry logic in your app

## Cost Considerations

Google Gemini API:
- **Free tier:** 60 requests per minute, 1,500 requests per day
- **Paid tier:** Usage-based pricing (~$0.0001 per request for vision)

For most personal use, the free tier is sufficient.

## Best Practices

1. **Good Lighting:** Ensure food is well-lit for better AI analysis
2. **Clear View:** Show the food clearly without obstruction
3. **Reasonable Portions:** Take photos of single meals, not entire plates
4. **Verify Results:** Always verify predictions seem reasonable
5. **Adjust as Needed:** Modify quantities if actual portion differs

## File Structure

```
lib/
├── food_image_service.dart          # Core AI service
├── food_image_picker_screen.dart    # UI for image capture
├── home_page.dart                   # Updated with Scan Food button
└── main.dart                        # Updated to load .env file

.env                                 # Environment variables (Git-ignored)
pubspec.yaml                         # Updated dependencies
```

## Data Flow

```
User selects image
       ↓
Image sent to Gemini API
       ↓
API returns food analysis (JSON)
       ↓
FoodPrediction object created
       ↓
UI displays results
       ↓
User adjusts quantity if needed
       ↓
Data logged to CalorieTrackerProvider
       ↓
Optional: Save to Firestore
```

## Security Notes

- Never commit `.env` file with real API keys
- Use Firebase auth to ensure only authenticated users log meals
- API keys should be rotated periodically
- Consider using Firebase Remote Config for API key management in production

## Future Enhancements

Possible improvements:
- Batch processing for multiple food items in one image
- User feedback loop to improve predictions
- Saved meal templates for frequently logged foods
- Offline mode with cached food database
- Integration with food database APIs for more accurate data
- Barcode scanning for packaged foods
