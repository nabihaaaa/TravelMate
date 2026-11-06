import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();

    _isDarkMode = ThemeService.themeMode.value == ThemeMode.dark;
  }

  Future<void> _changeTheme(bool value) async {
    await ThemeService.setDarkMode(value);

    if (!mounted) return;

    setState(() {
      _isDarkMode = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colors.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              secondary: Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: colors.primary,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(
                _isDarkMode
                    ? 'Dark theme is enabled'
                    : 'Light theme is enabled',
              ),
              value: _isDarkMode,
              onChanged: _changeTheme,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          const Card(
            child: ListTile(
              leading: Icon(Icons.flight_takeoff),
              title: Text('TravelMate'),
              subtitle: Text('Your personal travel planning companion'),
            ),
          ),
        ],
      ),
    );
  }
}
