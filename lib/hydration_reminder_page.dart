import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HydrationReminderPage extends StatefulWidget {
  const HydrationReminderPage({super.key});

  @override
  State<HydrationReminderPage> createState() => _HydrationReminderPageState();
}

class _HydrationReminderPageState extends State<HydrationReminderPage> {
  final _intervalCtrl = TextEditingController(); // minutes
  final _targetCtrl = TextEditingController(); // cups/day
  Timer? _timer;
  Timer? _countdownTimer;
  bool _enabled = false;
  int _remainingSeconds = 0;
  int _cupsConsumedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _intervalCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final interval = p.getInt('hydration_interval') ?? 60;
    final target = p.getInt('hydration_target') ?? 8;
    final enabled = p.getBool('hydration_enabled') ?? false;
    
    // Load today's water intake
    final today = _getTodayKey();
    final cupsToday = p.getInt('water_cups_$today') ?? 0;
    
    setState(() {
      _intervalCtrl.text = interval.toString();
      _targetCtrl.text = target.toString();
      _enabled = enabled;
      _cupsConsumedToday = cupsToday;
    });
    if (enabled) _startTimer(interval);
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    final interval = int.tryParse(_intervalCtrl.text) ?? 60;
    final target = int.tryParse(_targetCtrl.text) ?? 8;
    await p.setInt('hydration_interval', interval);
    await p.setInt('hydration_target', target);
    await p.setBool('hydration_enabled', _enabled);
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _addWaterCup() async {
    final p = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    
    setState(() => _cupsConsumedToday++);
    await p.setInt('water_cups_$today', _cupsConsumedToday);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💧 Great job! $_cupsConsumedToday cups consumed'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resetWater() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reset Water Intake?'),
        content: const Text(
          'This will reset today\'s water consumption count to 0.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final p = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    await p.setInt('water_cups_$today', 0);
    
    setState(() => _cupsConsumedToday = 0);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Water intake reset'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    _countdownTimer?.cancel();

    // Set initial countdown
    setState(() {
      _remainingSeconds = minutes * 60;
    });

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }
      });
    });

    // Main timer for notifications
    _timer = Timer.periodic(Duration(minutes: minutes), (_) async {
      if (!mounted) return;

      // Reset countdown
      setState(() {
        _remainingSeconds = minutes * 60;
      });

      // Vibrate device
      await _triggerNotification();

      // Show dialog notification
      if (mounted) {
        _showWaterReminderDialog();
      }
    });
  }

  Future<void> _triggerNotification() async {
    try {
      // Vibrate the device (works on most devices)
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Haptic feedback failed: $e');
    }
  }

  void _showWaterReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue, size: 32),
            SizedBox(width: 12),
            Text('Time to Hydrate!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_drink, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Don\'t forget to drink water! 💧',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Remind me later'),
          ),
          FilledButton(
            onPressed: () {
              _addWaterCup();
              Navigator.pop(context);
            },
            child: const Text('I drank water'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _enabled && _remainingSeconds > 0
        ? 1.0 -
              (_remainingSeconds /
                  ((int.tryParse(_intervalCtrl.text) ?? 60) * 60))
        : 0.0;
    
    final targetCups = int.tryParse(_targetCtrl.text) ?? 8;
    final remainingCups = (targetCups - _cupsConsumedToday).clamp(0, targetCups);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration Reminder'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's Water Intake Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Today\'s Water Intake',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Cup counter display
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_drink,
                              size: 48,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_cupsConsumedToday / $targetCups',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'cups today',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_cupsConsumedToday / targetCups).clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation(
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (remainingCups > 0)
                          Text(
                            '$remainingCups cups remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          )
                        else
                          const Text(
                            '✓ Goal achieved! Great work!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Add water cup buttons
                  Text(
                    'Log a cup of water',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Add cup button
                      FloatingActionButton.extended(
                        onPressed: _addWaterCup,
                        backgroundColor: Colors.blue,
                        label: const Text('Add Cup'),
                        icon: const Icon(Icons.add),
                        heroTag: 'add_cup',
                      ),
                      const SizedBox(width: 12),
                      // Reset button
                      FloatingActionButton.extended(
                        onPressed: _resetWater,
                        backgroundColor: Colors.orange,
                        label: const Text('Reset'),
                        icon: const Icon(Icons.refresh),
                        heroTag: 'reset_water',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Cup buttons grid for quick adding
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Add',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: List.generate(8, (i) {
                    return GestureDetector(
                      onTap: () {
                        for (int j = 0; j < i + 1; j++) {
                          _addWaterCup();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.blue.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_drink,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${i + 1}x',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Timer Display Card
          if (_enabled)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Next Reminder In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.water_drop,
                                size: 40,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(_remainingSeconds),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_targetCtrl.text} cups daily goal',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Enable Switch
          Card(
            child: SwitchListTile(
              value: _enabled,
              title: const Text('Enable Reminders'),
              subtitle: Text(_enabled ? 'Active' : 'Paused'),
              activeColor: Colors.blue,
              onChanged: (v) async {
                setState(() => _enabled = v);
                await _savePrefs();
                final interval = int.tryParse(_intervalCtrl.text) ?? 60;
                if (v) {
                  _startTimer(interval);
                } else {
                  _timer?.cancel();
                  _countdownTimer?.cancel();
                  setState(() => _remainingSeconds = 0);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Interval Input
          TextField(
            controller: _intervalCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Reminder Interval (minutes)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.timer),
              helperText: 'How often to remind you',
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (_) => _savePrefs(),
          ),
          const SizedBox(height: 16),

          // Target Input
          TextField(
            controller: _targetCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Target Cups Per Day',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.local_drink),
              helperText: 'Daily hydration goal',
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (_) => _savePrefs(),
          ),
          const SizedBox(height: 24),

          // Save Button
          FilledButton.icon(
            onPressed: () {
              final interval = int.tryParse(_intervalCtrl.text) ?? 60;
              _savePrefs();
              if (_enabled) _startTimer(interval);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Settings saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // Test Button
          OutlinedButton.icon(
            onPressed: () {
              _triggerNotification();
              _showWaterReminderDialog();
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Test Notification'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }
}
