import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'calorie_tracker_provider.dart';

class WeeklyCaloriesPage extends StatefulWidget {
  const WeeklyCaloriesPage({super.key});

  @override
  State<WeeklyCaloriesPage> createState() => _WeeklyCaloriesPageState();
}

class _WeeklyCaloriesPageState extends State<WeeklyCaloriesPage> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _weekStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final targetCalories = context.watch<CalorieTrackerProvider>().targetCalories;

    final weekEnd = _weekStart.add(const Duration(days: 6));

    final q = db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_weekStart))
        .where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(
                DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Calories'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          // Bucket by day
          final buckets = <DateTime, int>{};
          for (int i = 0; i < 7; i++) {
            final d = _weekStart.add(Duration(days: i));
            buckets[d] = 0;
          }

          for (final d in docs) {
            final m = d.data() as Map<String, dynamic>;
            final ts = (m['createdAt'] as Timestamp?)?.toDate();
            if (ts == null) continue;
            final day = DateTime(ts.year, ts.month, ts.day);
            if (buckets.containsKey(day)) {
              buckets[day] =
                  (buckets[day] ?? 0) + ((m['calories'] ?? 0) as num).toInt();
            }
          }

          final rows = buckets.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key)); // oldest first

          final totalWeek = rows.fold<int>(0, (sum, e) => sum + e.value);
          final avgDaily = totalWeek ~/ 7;
          final maxDaily =
              rows.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);
          final minDaily = rows
              .where((e) => e.value > 0)
              .map((e) => e.value)
              .fold<int>(99999, (a, b) => a < b ? a : b);

          // Calculate target comparison
          final targetWeek = targetCalories * 7;
          final difference = totalWeek - targetWeek;
          final percentOfTarget =
              targetWeek > 0 ? ((totalWeek / targetWeek) * 100).toStringAsFixed(1) : '0.0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week navigation
                _buildWeekNavigation(),
                const SizedBox(height: 20),

                // Summary cards
                _buildSummaryCards(
                  totalWeek,
                  targetWeek,
                  difference,
                  percentOfTarget,
                  avgDaily,
                  maxDaily,
                  minDaily,
                ),
                const SizedBox(height: 24),

                // Chart
                _buildWeeklyChart(rows, targetCalories),
                const SizedBox(height: 24),

                // Daily breakdown
                _buildDailyBreakdown(rows),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final weekEndDate = _weekStart.add(const Duration(days: 6));
    final isCurrentWeek = _isCurrentWeek(_weekStart);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousWeek,
              ),
              Column(
                children: [
                  Text(
                    '${_formatDate(_weekStart)} - ${_formatDate(weekEndDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCurrentWeek)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: !isCurrentWeek ? _nextWeek : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    int totalWeek,
    int targetWeek,
    int difference,
    String percentOfTarget,
    int avgDaily,
    int maxDaily,
    int minDaily,
  ) {
    final exceeded = difference > 0;

    return Column(
      children: [
        // Total vs Target
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: exceeded
                  ? [Colors.orange.shade400, Colors.orange.shade600]
                  : [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (exceeded ? Colors.orange : Colors.green)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Weekly Total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalWeek kcal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '$targetWeek kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        exceeded ? 'Over Target' : 'Under Target',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${exceeded ? '+' : ''}$difference kcal ($percentOfTarget%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildStatCard('Avg Daily', '$avgDaily kcal', Colors.blue),
            _buildStatCard('Max Day', '$maxDaily kcal', Colors.purple),
            _buildStatCard('Min Day', '$minDaily kcal', Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(
      List<MapEntry<DateTime, int>> rows, int targetCalories) {
    final spots = <FlSpot>[];
    for (int i = 0; i < rows.length; i++) {
      spots.add(FlSpot(i.toDouble(), rows[i].value.toDouble()));
    }

    if (spots.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No data for this week'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Intake',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: (targetCalories / 2).toDouble(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= rows.length) return const Text('');
                        final day = rows[value.toInt()].key;
                        return Text(
                          _getDayLabel(day),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      interval: (targetCalories / 2).toDouble(),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  // Target line
                  LineChartBarData(
                    spots: [
                      FlSpot(0, targetCalories.toDouble()),
                      FlSpot(6, targetCalories.toDouble()),
                    ],
                    isCurved: false,
                    color: Colors.orange,
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Actual',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 2,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              const Text(
                'Target',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(List<MapEntry<DateTime, int>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...rows.map((e) {
          final day = e.key;
          final calories = e.value;
          final dayName = _getDayName(day.weekday);
          final percentage = ((calories / (context.read<CalorieTrackerProvider>().targetCalories)).clamp(0, 2) * 100).toInt();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
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
                          dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatDate(day),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$calories kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (calories / (context.read<CalorieTrackerProvider>().targetCalories)).clamp(0, 2),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      calories > context.read<CalorieTrackerProvider>().targetCalories
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$percentage% of daily target',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _getDayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  bool _isCurrentWeek(DateTime weekStart) {
    final today = DateTime.now();
    final currentWeekStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    return weekStart.day == currentWeekStart.day &&
        weekStart.month == currentWeekStart.month &&
        weekStart.year == currentWeekStart.year;
  }
}
