import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_info_page.dart';
import 'weekly_calories_page.dart';
import 'hydration_reminder_page.dart';
import 'settings_page.dart';
import 'login_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2e7d32)),
            accountName: Text(user?.displayName ?? 'Your Name'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person, size: 36),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile Info'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileInfoPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.stacked_bar_chart),
            title: const Text('Weekly Calories Intake'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklyCaloriesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.opacity),
            title: const Text('Hydration Reminder'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HydrationReminderPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
