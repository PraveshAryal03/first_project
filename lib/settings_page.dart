import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _goalCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final goal = (doc.data()?['dailyGoal'] ?? 2000).toString();
    setState(() => _goalCtrl.text = goal);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final goal = int.tryParse(_goalCtrl.text) ?? 2000;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'dailyGoal': goal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetCalories() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reset All Calories?'),
        content: const Text(
          'This will delete all your calorie entries. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();
      
      // Get all meals and delete them
      final mealsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .get();
      
      for (final doc in mealsSnap.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ All calorie data has been reset'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _goalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily calorie goal (kcal)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          // Reset Calories Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Text(
                      'Reset Calorie Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Delete all your logged calories and start fresh',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _resetCalories,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Reset All Calories'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const ListTile(
            title: Text('Theme'),
            subtitle: Text('Follow system (placeholder)'),
          ),
        ],
      ),
    );
  }
}
