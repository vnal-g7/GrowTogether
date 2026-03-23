import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin_panel.dart';
import 'screens/challenges_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/fraud_monitor_screen.dart';

///import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, themeMode, __) {
        return MaterialApp(
          title: 'GrowTogether',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FE),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3D5AFE),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3D5AFE),
              brightness: Brightness.dark,
            ),
          ),
          home: StreamBuilder(
            stream: authService.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return snapshot.hasData ? const DashboardScreen() : const LoginScreen();
            },
          ),
          routes: {
                   '/login': (context) => const LoginScreen(),
                   '/signup': (context) => const SignupScreen(),
                   '/dashboard': (context) => const DashboardScreen(),
                   '/leaderboard': (context) => const LeaderboardScreen(),
                   '/challenges': (context) => const ChallengesScreen(),
                   '/admin': (context) => const AdminPanel(),
                   '/admin-analytics': (context) => const AdminAnalyticsScreen(),
                   '/edit-profile': (context) => const EditProfileScreen(),
                  '/fraud-monitor': (context) => const FraudMonitorScreen(),
                   },
        );
      },
    );
  }
}
