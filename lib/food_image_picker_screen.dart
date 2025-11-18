import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'food_image_service.dart';
import 'calorie_tracker_provider.dart';

class FoodImagePickerScreen extends StatefulWidget {
  final String apiKey;

  const FoodImagePickerScreen({super.key, required this.apiKey});

  @override
  State<FoodImagePickerScreen> createState() => _FoodImagePickerScreenState();
}

class _FoodImagePickerScreenState extends State<FoodImagePickerScreen> {
  late FoodImageService _imageService;
  File? _selectedImage;
  FoodPrediction? _prediction;
  bool _isLoading = false;
  String? _error;

  // Quantity override
  final _quantityCtrl = TextEditingController(text: '1');
  
  @override
  void initState() {
    super.initState();
    _imageService = FoodImageService(apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _error = null);
      final image = await _imageService.pickImageFromGallery();
      if (image != null) {
        setState(() => _selectedImage = image);
        await _analyzeFoodImage(image);
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _captureImageFromCamera() async {
    try {
      setState(() => _error = null);
      final image = await _imageService.captureImageFromCamera();
      if (image != null) {
        setState(() => _selectedImage = image);
        await _analyzeFoodImage(image);
      }
    } catch (e) {
      setState(() => _error = 'Failed to capture image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _analyzeFoodImage(File image) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _prediction = null;
    });

    try {
      final prediction = await _imageService.predictFoodCalories(image);
      setState(() => _prediction = prediction);
    } catch (e) {
      setState(() => _error = 'Failed to analyze image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logFood() async {
    if (_prediction == null) return;

    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 1;
    final totalCalories = _prediction!.estimatedCalories * quantity;

    try {
      // Update app state via Provider
      context.read<CalorieTrackerProvider>().addMeal(
        calories: totalCalories,
        protein: (_prediction!.protein * quantity).toInt(),
        carbs: (_prediction!.carbs * quantity).toInt(),
        fats: (_prediction!.fats * quantity).toInt(),
      );

      // Optional: save to Firestore if signed-in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('meals')
            .add({
          'name': _prediction!.foodName,
          'quantity': quantity,
          'calories': totalCalories,
          'protein': _prediction!.protein * quantity,
          'carbs': _prediction!.carbs * quantity,
          'fats': _prediction!.fats * quantity,
          'servingSize': _prediction!.servingSize,
          'description': _prediction!.description,
          'confidence': _prediction!.confidence,
          'source': 'image_prediction',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged: ${_prediction!.foodName} × $quantity • $totalCalories kcal',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging food: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Food'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web not supported message
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Food image scanning is not supported on web. Please use mobile or desktop app.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Image selection section
            if (_selectedImage == null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.image_not_supported,
                        size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No image selected',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: kIsWeb ? null : _captureImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: kIsWeb ? null : _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            const SizedBox(height: 20),

            // Loading indicator
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Analyzing food...'),
                  ],
                ),
              ),

            // Prediction results
            if (_prediction != null && !_isLoading) ...[
              const Divider(height: 30),
              const Text(
                'Food Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPredictionCard(),
              const SizedBox(height: 20),

              // Quantity selector
              TextFormField(
                controller: _quantityCtrl,
                decoration: InputDecoration(
                  labelText: 'Quantity/Servings',
                  hintText: 'e.g., 2',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Log button
              FilledButton.icon(
                onPressed: _logFood,
                icon: const Icon(Icons.check),
                label: const Text('Log This Meal'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final p = _prediction!;
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 1;
    final totalCalories = p.estimatedCalories * quantity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.foodName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.servingSize,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(p.confidence),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.confidence.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (p.description.isNotEmpty)
            Text(
              p.description,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated per serving: ${p.estimatedCalories} kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (quantity > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Total ($quantity servings): $totalCalories kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nutrition (per serving):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientBadge('Protein', p.protein, 'g'),
              _buildNutrientBadge('Carbs', p.carbs, 'g'),
              _buildNutrientBadge('Fats', p.fats, 'g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBadge(String label, int value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$value$unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
