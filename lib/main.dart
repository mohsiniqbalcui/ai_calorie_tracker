import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositories/food_repository.dart';
import 'data/services/food_service.dart';
import 'data/local/preference_manager.dart';
import 'presentation/cubit/food_log_cubit.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/splash_screen.dart';

Future<void> _loadEnvironmentFile() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Error loading .env file: $e');
    // Provide a fallback or handle error as needed
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironmentFile();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final preferenceManager = PreferenceManager(prefs);
  
  // Check if user has already completed onboarding by checking if user data exists
  final userData = preferenceManager.getUserData();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  // Skip onboarding if either user data exists OR onboarding was marked complete previously
  final showOnboarding = !(onboardingComplete || userData != null);

  // Initialize services and repositories
  final foodService = FoodService();
  final foodRepository = FoodRepository(foodService, prefs);
  
  runApp(MyApp(
    showOnboarding: showOnboarding,
    foodRepository: foodRepository,
  ));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final FoodRepository foodRepository;
  
  const MyApp({
    required this.showOnboarding,
    required this.foodRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FoodLogCubit(foodRepository)..loadDailyLog(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Calorie Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(
          nextBuilder: () => showOnboarding ? OnboardingScreen() : MainScreen(),
          durationMs: 3000,
        ),
        routes: {
          '/main': (context) => MainScreen(),
          '/home': (context) => HomeScreen(), 
          '/onboarding': (context) => OnboardingScreen(),
          '/settings': (context) => SettingsScreen(),
// Ensures `/home` route is defined
        },
      ),
    );
  }
}