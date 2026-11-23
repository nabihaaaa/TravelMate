
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/theme_service.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _isLoggingOut = false;

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

  // Open registration so a guest can create a permanent account.
  Future<void> _upgradeGuest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );

    // Refresh the account details after returning.
    if (mounted) setState(() {});
  }

  // Sign out and return to the welcome screen.
  Future<void> _logout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of TravelMate?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      await AuthService.instance.logout();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Unable to log out.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to log out.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = AuthService.instance.currentUser;
    final isGuest = user?.isAnonymous ?? false;

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
            'Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: Icon(
                isGuest ? Icons.person_outline : Icons.account_circle,
                color: colors.primary,
              ),
              title: Text(isGuest ? 'Guest Account' : 'Signed In'),
              subtitle: Text(
                isGuest
                    ? 'You are exploring TravelMate as a guest.'
                    : user?.email ?? 'No email available',
              ),
            ),
          ),

          // Only guests see the option to create a permanent account.
          if (isGuest) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.person_add_alt_1,
                  color: colors.primary,
                ),
                title: const Text('Upgrade to Free Account'),
                subtitle: const Text(
                  'Create an account to keep your guest profile.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _upgradeGuest,
              ),
            ),
          ],

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              subtitle: const Text('Return to the welcome screen'),
              trailing: _isLoggingOut
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.chevron_right),
              onTap: _isLoggingOut ? null : _logout,
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
