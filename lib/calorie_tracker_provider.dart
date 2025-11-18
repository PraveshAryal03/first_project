import 'package:flutter/material.dart';

class CalorieTrackerProvider extends ChangeNotifier {
  int _calories = 0;
  int _targetCalories = 0;

  // nutrients: value = current intake, max = daily target
  final Map<String, Map<String, int>> _nutrients = {
    'Protein': {'value': 0, 'max': 120},
    'Carbs': {'value': 0, 'max': 250},
    'Fats': {'value': 0, 'max': 70},
  };

  int get calories => _calories;
  int get targetCalories => _targetCalories;
  Map<String, Map<String, int>> get nutrients => _nutrients;

  /// Supports both:
  /// - addMeal(calories: 500, protein: 30, carbs: 40, fats: 10)
  /// - addMeal(caloriesPerUnit: 100, quantity: 2, proteinPerUnit: 5, ...)
  void addMeal({
    // direct totals
    int? calories,
    int protein = 0,
    int carbs = 0,
    int fats = 0,

    // per-unit style
    int? caloriesPerUnit,
    int quantity = 1,
    int proteinPerUnit = 0,
    int carbsPerUnit = 0,
    int fatsPerUnit = 0,
  }) {
    final qty = quantity;

    // If direct calories are not provided, compute from per-unit
    final totalCalories = calories ?? ((caloriesPerUnit ?? 0) * qty);

    // For macros: if direct total is non-zero, use it;
    // otherwise compute from per-unit * quantity.
    final totalProtein = protein != 0 ? protein : proteinPerUnit * qty;
    final totalCarbs = carbs != 0 ? carbs : carbsPerUnit * qty;
    final totalFats = fats != 0 ? fats : fatsPerUnit * qty;

    _calories += totalCalories;

    // ✅ Safely read existing values with ?? 0 to avoid nullable errors
    final currentProtein = _nutrients['Protein']?['value'] ?? 0;
    final currentCarbs = _nutrients['Carbs']?['value'] ?? 0;
    final currentFats = _nutrients['Fats']?['value'] ?? 0;

    _nutrients['Protein']!['value'] = currentProtein + totalProtein;
    _nutrients['Carbs']!['value'] = currentCarbs + totalCarbs;
    _nutrients['Fats']!['value'] = currentFats + totalFats;

    notifyListeners();
  }

  /// For old code that used `addCalories(...)`
  void addCalories(int calories) {
    addMeal(calories: calories);
  }

  /// Update daily targets from ProfileInfoPage
  void updateTargets(int calories, int protein, int carbs, int fats) {
    _targetCalories = calories;
    _nutrients['Protein']!['max'] = protein;
    _nutrients['Carbs']!['max'] = carbs;
    _nutrients['Fats']!['max'] = fats;
    notifyListeners();
  }

  /// Optional: reset daily intake
  void resetDay() {
    _calories = 0;
    _nutrients['Protein']!['value'] = 0;
    _nutrients['Carbs']!['value'] = 0;
    _nutrients['Fats']!['value'] = 0;
    notifyListeners();
  }
}
