import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WeeklyCaloriesPage extends StatelessWidget {
  const WeeklyCaloriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 6));

    final q = db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Calories Intake')),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;

          // bucket by day
          final buckets = <DateTime, int>{};
          for (int i = 0; i < 7; i++) {
            final d = DateTime(start.year, start.month, start.day)
                .add(Duration(days: i));
            buckets[d] = 0;
          }
          for (final d in docs) {
            final m = d.data() as Map<String, dynamic>;
            final ts = (m['createdAt'] as Timestamp?)?.toDate();
            if (ts == null) continue;
            final day = DateTime(ts.year, ts.month, ts.day);
            if (buckets.containsKey(day)) {
              buckets[day] = (buckets[day] ?? 0) + ((m['calories'] ?? 0) as num).toInt();

            }
          }
          final rows = buckets.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key)); // newest first

          final totalWeek =
          rows.fold<int>(0, (sum, e) => sum + e.value);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Total last 7 days: $totalWeek kcal',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...rows.map((e) {
                final d = e.key;
                final label = '${d.month}/${d.day}/${d.year}';
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(label),
                  trailing: Text('${e.value} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
