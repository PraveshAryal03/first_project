import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import only when not on web
import 'package:image_picker/image_picker.dart';

class FoodImageService {
  final String apiKey;
  late final GenerativeModel _model;

  FoodImageService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      if (kIsWeb) {
        print('Web platform: Image picker not supported');
        return null;
      }
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  /// Capture an image from camera
  Future<File?> captureImageFromCamera() async {
    try {
      if (kIsWeb) {
        print('Web platform: Camera capture not supported');
        return null;
      }
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      rethrow;
    }
  }

  /// Predict food calories using Gemini Vision API
  Future<FoodPrediction> predictFoodCalories(File imageFile) async {
    try {
      // Read image as bytes
      final imageBytes = await imageFile.readAsBytes();

      // Prepare the prompt
      const prompt = '''Analyze this food image and provide calorie estimation.

Please respond in this exact JSON format (no additional text):
{
  "foodName": "name of the food",
  "estimatedCalories": number (approximate calories per serving),
  "confidence": "high/medium/low",
  "servingSize": "description of serving size",
  "description": "brief description of what you see",
  "nutritionEstimate": {
    "protein": number (grams),
    "carbs": number (grams),
    "fats": number (grams)
  }
}

Be conservative with calorie estimates and assume average portion size if not clear.''';

      // Send request to Gemini with image
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      // Parse the response
      final responseText = response.text ?? '';
      final prediction = _parsePredictionResponse(responseText);

      return prediction;
    } catch (e) {
      print('Error predicting food calories: $e');
      rethrow;
    }
  }

  /// Parse the JSON response from Gemini
  FoodPrediction _parsePredictionResponse(String responseText) {
    try {
      // Extract JSON from response (in case there's extra text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final Map<String, dynamic> json = _parseJsonManually(jsonStr);

      return FoodPrediction(
        foodName: json['foodName'] as String? ?? 'Unknown Food',
        estimatedCalories: _toInt(json['estimatedCalories']) ?? 0,
        confidence: json['confidence'] as String? ?? 'medium',
        servingSize: json['servingSize'] as String? ?? 'Unknown',
        description: json['description'] as String? ?? '',
        protein: _toInt(json['nutritionEstimate']?['protein']) ?? 0,
        carbs: _toInt(json['nutritionEstimate']?['carbs']) ?? 0,
        fats: _toInt(json['nutritionEstimate']?['fats']) ?? 0,
      );
    } catch (e) {
      print('Error parsing prediction response: $e, Raw response: $responseText');
      // Return a default prediction if parsing fails
      return FoodPrediction(
        foodName: 'Food Item',
        estimatedCalories: 300,
        confidence: 'low',
        servingSize: 'Unknown',
        description: 'Unable to analyze image',
        protein: 0,
        carbs: 0,
        fats: 0,
      );
    }
  }

  /// Simple JSON parser
  Map<String, dynamic> _parseJsonManually(String jsonStr) {
    final result = <String, dynamic>{};
    
    // Simple extraction for this specific JSON structure
    final foodNameMatch = RegExp(r'"foodName"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    if (foodNameMatch != null) {
      result['foodName'] = foodNameMatch.group(1)!;
    }

    final caloriesMatch = RegExp(r'"estimatedCalories"\s*:\s*(\d+)').firstMatch(jsonStr);
    if (caloriesMatch != null) {
      result['estimatedCalories'] = int.tryParse(caloriesMatch.group(1)!);
    }

    final confidenceMatch = RegExp(r'"confidence"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    if (confidenceMatch != null) {
      result['confidence'] = confidenceMatch.group(1)!;
    }

    final servingSizeMatch = RegExp(r'"servingSize"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    if (servingSizeMatch != null) {
      result['servingSize'] = servingSizeMatch.group(1)!;
    }

    final descriptionMatch = RegExp(r'"description"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
    if (descriptionMatch != null) {
      result['description'] = descriptionMatch.group(1)!;
    }

    // Nutrition estimates
    final nutrition = <String, dynamic>{};
    final proteinMatch = RegExp(r'"protein"\s*:\s*(\d+)').firstMatch(jsonStr);
    if (proteinMatch != null) {
      nutrition['protein'] = int.tryParse(proteinMatch.group(1)!);
    }

    final carbsMatch = RegExp(r'"carbs"\s*:\s*(\d+)').firstMatch(jsonStr);
    if (carbsMatch != null) {
      nutrition['carbs'] = int.tryParse(carbsMatch.group(1)!);
    }

    final fatsMatch = RegExp(r'"fats"\s*:\s*(\d+)').firstMatch(jsonStr);
    if (fatsMatch != null) {
      nutrition['fats'] = int.tryParse(fatsMatch.group(1)!);
    }

    if (nutrition.isNotEmpty) {
      result['nutritionEstimate'] = nutrition;
    }

    return result;
  }

  /// Helper to convert to int safely
  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
}

/// Model class for food prediction
class FoodPrediction {
  final String foodName;
  final int estimatedCalories;
  final String confidence; // high, medium, low
  final String servingSize;
  final String description;
  final int protein;
  final int carbs;
  final int fats;

  FoodPrediction({
    required this.foodName,
    required this.estimatedCalories,
    required this.confidence,
    required this.servingSize,
    required this.description,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}
