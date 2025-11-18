import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:first_project/calorie_tracker_provider.dart';
import 'package:first_project/map_screen.dart';
import 'package:first_project/app_drawer.dart';
import 'package:first_project/add_food_screen.dart';
import 'package:first_project/log_food_page.dart';
import 'package:first_project/food_image_picker_screen.dart';
import 'profile_info_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // ignore: deprecated_member_use
                Colors.black.withOpacity(0.30),
                // ignore: deprecated_member_use
                Colors.black.withOpacity(0.70),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 30),
                  _buildAnimatedTitle(),
                  const SizedBox(height: 30),
                  _buildActionButtons(context),
                  const SizedBox(height: 30),
                  _buildTodaysIntake(context),
                  const SizedBox(height: 25),
                  _buildNutrientsSection(context),
                  const SizedBox(height: 25),
                  _buildRecommendedNearby(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------- UI helpers below ---------------------------- */

Widget _buildAppBar(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddFoodScreen()),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildAnimatedTitle() {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 800),
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: const Text(
            "Calories\nTracker",
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildActionButtons(BuildContext context) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  return Row(
    children: [
      _buildActionButton(context, Icons.restaurant_menu, "Log Food", () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LogFoodPage(
              onCaloriesLogged: (calories) {
                // Just log for debugging - addMeal() is already called in LogFoodPage
                //print('🏠 Callback received: $calories kcal logged');
              },
            ),
          ),
        );
      }),
      // Only show Scan Food on non-web platforms
      if (!kIsWeb) ...[
        const SizedBox(width: 12),
        _buildActionButton(context, Icons.photo_camera, "Scan Food", () {
          if (apiKey.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gemini API key not configured. Please set GEMINI_API_KEY in .env'),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodImagePickerScreen(apiKey: apiKey),
            ),
          );
        }),
      ],
    ],
  );
}

Widget _buildActionButton(
  BuildContext context,
  IconData icon,
  String label,
  VoidCallback onTap,
) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTodaysIntake(BuildContext context) {
  return Consumer<CalorieTrackerProvider>(
    builder: (context, provider, child) {
      final total = provider.calories;
      final target = provider.targetCalories;

      // Debug print to see when homepage rebuilds
      print('🏠 Homepage rebuilding - Calories: $total / Target: $target');

      return Container(
        padding: const EdgeInsets.all(25),
        decoration: _whiteCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Intake",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Show target if available
                if (target > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Goal: $target kcal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: total.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "calories",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Optional: Show progress bar
            if (target > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (total / target).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    total > target ? Colors.red : const Color.fromARGB(255, 76, 160, 175),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                total < target
                    ? '${target - total} kcal remaining'
                    : '${total - target} kcal over goal',
                style: TextStyle(
                  fontSize: 13,
                  color: total > target ? Colors.red[700] : const Color.fromARGB(255, 83, 56, 142),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

Widget _buildNutrientsSection(BuildContext context) {
  return Consumer<CalorieTrackerProvider>(
    builder: (context, provider, child) {
      final n = provider.nutrients;

      final proteinVal = (n['Protein']?['value'] ?? 0);
      final carbsVal = (n['Carbs']?['value'] ?? 0);
      final fatVal = (n['Fats']?['value'] ?? 0);

      final proteinMax = (n['Protein']?['max'] ?? 120);
      final carbsMax = (n['Carbs']?['max'] ?? 250);
      final fatsMax = (n['Fats']?['max'] ?? 70);

      print(
        '🏠 Nutrients - P: $proteinVal/$proteinMax, C: $carbsVal/$carbsMax, F: $fatVal/$fatsMax',
      );

      final normalized = <String, Map<String, int>>{
        'Protein': {'value': proteinVal, 'max': proteinMax},
        'Carbs': {'value': carbsVal, 'max': carbsMax},
        'Fats': {'value': fatVal, 'max': fatsMax},
      };

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _whiteCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nutrients",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ...normalized.entries.map((e) {
              final name = e.key;
              final value = e.value['value']!;
              final max = e.value['max']!;
              final color = {
                'Protein': Colors.orange,
                'Carbs': Colors.blue,
                'Fats': Colors.green,
              }[name]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _buildNutrientRow(name, value, max, color),
              );
            }),
          ],
        ),
      );
    },
  );
}

Widget _buildRecommendedNearby(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: _whiteCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Recommended Nearby",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    "0.3 mi",
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Map Preview Card with Button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          ),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                  'https://maps.googleapis.com/maps/api/staticmap?center=Pocatello,ID&zoom=14&size=600x300&markers=color:green%7CPocatello,ID',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Stack(
                children: [
                  // "View on Map" overlay button
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Explore Restaurants on Map",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.green[700],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Location indicator at top
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Pocatello, ID",
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Quick preview of restaurants
        Row(
          children: [
            const Text(
              "Quick Preview",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              ),
              icon: const Icon(Icons.restaurant_menu, size: 16),
              label: const Text("View All"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildRestaurantCard(
          "Green Leaf Cafe",
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
          4.5,
          "0.2 mi away",
        ),
        const SizedBox(height: 12),
        _buildRestaurantCard(
          "Fresh Garden Bistro",
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=200',
          4.7,
          "0.3 mi away",
        ),
      ],
    ),
  );
}

Widget _buildRestaurantCard(
  String name,
  String logoUrl,
  double rating,
  String location,
) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: CachedNetworkImageProvider(logoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.orange[400], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(Icons.location_on, size: 16, color: Colors.blue[400]),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildNutrientRow(String name, int value, int max, Color color) {
  final clamped = value.clamp(0, max);
  return Row(
    children: [
      Expanded(
        child: Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = max > 0
                    ? (clamped / max) * constraints.maxWidth
                    : 0.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 8,
                  width: width,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '$value/$max g',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    ],
  );
}

BoxDecoration _whiteCardDecoration() {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.10),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}
