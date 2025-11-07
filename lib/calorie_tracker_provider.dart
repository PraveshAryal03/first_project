import 'package:flutter/foundation.dart';

class CalorieTrackerProvider extends ChangeNotifier {
  int _calories = 0;
  int get calories => _calories;

  /// Nutrients map kept in your original structure:
  /// { "Protein": {"value": 0, "max": 100}, ... }
  final Map<String, Map<String, int>> _nutrients = {
    'Protein': {'value': 0, 'max': 120}, // tweak defaults if you want
    'Carbs':   {'value': 0, 'max': 250},
    'Fats':    {'value': 0, 'max': 70},
  };

  Map<String, Map<String, int>> get nutrients => _nutrients;

  // --- Calories ---

  void addCalories(int amount) {
    _calories += amount;
    notifyListeners();
  }

  void setCalories(int newCalories) {
    _calories = newCalories;
    notifyListeners();
  }

  // --- Nutrients (macros) ---

  /// Set an absolute value (your original method).
  void updateNutrient(String name, int value) {
    if (_nutrients.containsKey(name)) {
      _nutrients[name]!['value'] = value.clamp(0, 1000000);
      notifyListeners();
    }
  }

  /// Increment macros by amounts (in grams). Values are rounded to int to match your map.
  void addMacros({double protein = 0, double carbs = 0, double fats = 0}) {
    _inc('Protein', protein);
    _inc('Carbs',   carbs);
    _inc('Fats',    fats);
    notifyListeners();
  }

  /// Convenience: log one meal (per-unit * quantity).
  void addMeal({
    required int caloriesPerUnit,
    required int quantity,
    double proteinPerUnit = 0,
    double carbsPerUnit = 0,
    double fatsPerUnit = 0,
  }) {
    final totalCals = caloriesPerUnit * quantity;
    final totalP = proteinPerUnit * quantity;
    final totalC = carbsPerUnit   * quantity;
    final totalF = fatsPerUnit    * quantity;

    _calories += totalCals;
    _inc('Protein', totalP);
    _inc('Carbs',   totalC);
    _inc('Fats',    totalF);
    notifyListeners();
  }

  /// Set daily goals (max) for bars.
  void setGoals({int? protein, int? carbs, int? fats}) {
    if (protein != null && _nutrients.containsKey('Protein')) {
      _nutrients['Protein']!['max'] = protein;
    }
    if (carbs != null && _nutrients.containsKey('Carbs')) {
      _nutrients['Carbs']!['max'] = carbs;
    }
    if (fats != null && _nutrients.containsKey('Fats')) {
      _nutrients['Fats']!['max'] = fats;
    }
    notifyListeners();
  }

  /// Reset all daily totals.
  void resetToday() {
    _calories = 0;
    for (final e in _nutrients.values) {
      e['value'] = 0;
    }
    notifyListeners();
  }

  // --- helpers ---

  void _inc(String key, double by) {
    if (!_nutrients.containsKey(key)) return;
    final current = _nutrients[key]!['value'] ?? 0;
    _nutrients[key]!['value'] = (current + by.round()).clamp(0, 1000000);
  }
}
