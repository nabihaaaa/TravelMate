import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/trip_service.dart';
import 'services/theme_service.dart';

//Import our notification service.
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved trip information.
  await TripService.instance.loadAllData();

  // Load the user's saved theme preference.
  await ThemeService.loadTheme();

  // NEW: Initialize local notifications.
  await NotificationService.instance.initialize();

  // Start TravelMate.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'TravelMate',
          debugShowCheckedModeBanner: false,

          // Light theme.
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.pink,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // Dark theme.
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.pink,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          // Theme selected by the user.
          themeMode: currentTheme,

          initialRoute: Routes.home,
          onGenerateRoute: Routes.generate,
        );
      },
    );
  }
}
