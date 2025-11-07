import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:first_project/calorie_tracker_provider.dart';
import 'package:first_project/map_screen.dart';
import 'package:first_project/app_drawer.dart';
import 'package:first_project/add_food_screen.dart';
import 'package:first_project/log_food_page.dart';

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
                Colors.black.withOpacity(0.30),
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
                Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black26),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildActionButtons(BuildContext context) {
  return Row(
    children: [
      _buildActionButton(
        context,
        Icons.restaurant_menu,
        "Log Food",
            () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LogFoodPage(
                onCaloriesLogged: (calories) {
                  context.read<CalorieTrackerProvider>().addCalories(calories);
                },
              ),
            ),
          );
        },
      ),
    ],
  );
}

Widget _buildTodaysIntake(BuildContext context) {
  return Consumer<CalorieTrackerProvider>(
    builder: (context, provider, child) {
      final total = provider.calories;
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: _whiteCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Intake",
              style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
    //          crossAxisAlignment: TextBaseline.alphabetic,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: total.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "calories",
                  style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildNutrientsSection(BuildContext context) {
  return Consumer<CalorieTrackerProvider>(
    builder: (context, provider, child) {
      // provider.nutrients is: { 'Protein': {'value': int, 'max': int}, ... }
      final n = provider.nutrients;

      final proteinVal = (n['Protein']?['value'] ?? 0);
      final carbsVal   = (n['Carbs']?['value']   ?? 0);
      final fatVal     = (n['Fats']?['value']    ?? 0);

      final proteinMax = (n['Protein']?['max'] ?? 120);
      final carbsMax   = (n['Carbs']?['max']   ?? 250);
      final fatsMax    = (n['Fats']?['max']    ?? 70);

      final normalized = <String, Map<String, int>>{
        'Protein': {'value': proteinVal, 'max': proteinMax},
        'Carbs'  : {'value': carbsVal,   'max': carbsMax},
        'Fats'   : {'value': fatVal,     'max': fatsMax},
      };

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _whiteCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nutrients",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 20),
            ...normalized.entries.map((e) {
              final name = e.key;
              final value = e.value['value']!;
              final max = e.value['max']!;
              final color = {
                'Protein': Colors.orange,
                'Carbs'  : Colors.blue,
                'Fats'   : Colors.green,
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
            const Text("Recommended Nearby", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text("0.3 mi", style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen())),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: CachedNetworkImageProvider(
                  // NOTE: don't commit real API keys to git. Replace with your own key in local dev.
                  'https://maps.googleapis.com/maps/api/staticmap?center=Central+Park,NY&zoom=15&size=600x300&key=AIzaSyB6Ew262fBnzeasoWFrBESzq5F9A6E96MM',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildRestaurantCard(
          "McDonald's",
          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/McDonald%27s_logo.svg/1200px-McDonald%27s_logo.svg.png',
          4.1,
          "5 min away",
        ),
        const SizedBox(height: 12),
        _buildRestaurantCard(
          "Subway",
          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Subway_2016_logo.svg/2560px-Subway_2016_logo.svg.png',
          4.0,
          "7 min away",
        ),
      ],
    ),
  );
}

Widget _buildRestaurantCard(String name, String logoUrl, double rating, String location) {
  return Container(
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: CachedNetworkImageProvider(logoUrl), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.orange[400], size: 16),
                  const SizedBox(width: 4),
                  Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.location_on, size: 16, color: Colors.blue[400]),
                  const SizedBox(width: 4),
                  Text(location, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButton(BuildContext context, IconData icon, String text, VoidCallback onTap) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (clamped / max) * constraints.maxWidth;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 8,
                  width: width,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
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
          Text('$value/$max g', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
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
      BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 5)),
    ],
  );
}
