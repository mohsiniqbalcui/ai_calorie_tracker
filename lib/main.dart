import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/cloud/cloud_backend.dart';
import 'data/remote/open_food_facts.dart';
import 'presentation/cubit/account_cubit.dart';
import 'data/repositories/food_repository.dart';
import 'data/services/reminder_service.dart';
import 'presentation/cubit/reminders_cubit.dart';
import 'data/services/food_service.dart';
import 'data/local/preference_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/local/tracker_store.dart';
import 'presentation/cubit/food_log_cubit.dart';
import 'presentation/cubit/settings_cubit.dart';
import 'presentation/cubit/tracker_cubit.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/splash_screen.dart';

Future<void> _loadEnvironmentFile() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
    // Provide a fallback or handle error as needed
  }
}

/// Starts Firebase when the platform config file is present
/// (`google-services.json` / `GoogleService-Info.plist`). Without it the app
/// keeps working offline, so a fresh checkout still runs.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
    return true;
  } catch (e) {
    debugPrint('Firebase not configured: $e');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironmentFile();
  await _initFirebase();

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

  final trackerStore = TrackerStore(prefs);
  final remindersCubit = RemindersCubit(prefs, ReminderService());
  // Re-register saved reminders in the background; never block start-up on it.
  remindersCubit.syncAll();

  runApp(MyApp(
    showOnboarding: showOnboarding,
    foodRepository: foodRepository,
    trackerStore: trackerStore,
    settingsCubit: SettingsCubit(prefs),
    remindersCubit: remindersCubit,
    prefs: prefs,
  ));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final FoodRepository foodRepository;
  final TrackerStore trackerStore;
  final SettingsCubit settingsCubit;
  final RemindersCubit remindersCubit;
  final SharedPreferences prefs;

  const MyApp({
    super.key,
    required this.showOnboarding,
    required this.foodRepository,
    required this.trackerStore,
    required this.settingsCubit,
    required this.remindersCubit,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: trackerStore),
        RepositoryProvider(create: (_) => OpenFoodFactsSource()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settingsCubit),
          BlocProvider.value(value: remindersCubit),
          BlocProvider(
              create: (_) => AccountCubit(FirebaseBackend(), prefs)),
          BlocProvider(
              create: (_) =>
                  FoodLogCubit(foodRepository, trackerStore)..loadDailyLog()),
          BlocProvider(create: (_) => TrackerCubit(trackerStore)),
        ],
        child: BlocBuilder<SettingsCubit, AppSettings>(
          buildWhen: (a, b) =>
              a.uiMode != b.uiMode || a.themeMode != b.themeMode,
          builder: (context, settings) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Calorie Lens',
              // Pro is a white, professional look; it only goes dark when chosen explicitly.
              themeMode:
                  settings.isPro && settings.themeMode == ThemeMode.system
                      ? ThemeMode.light
                      : settings.themeMode,
              theme: AppTheme.build(settings.uiMode, Brightness.light),
              darkTheme: AppTheme.build(settings.uiMode, Brightness.dark),
              home: SplashScreen(
                nextBuilder: () =>
                    showOnboarding ? OnboardingScreen() : const MainScreen(),
                durationMs: 2000,
              ),
              routes: {
                '/main': (context) => const MainScreen(),
                '/home': (context) => const HomeScreen(),
                '/onboarding': (context) => OnboardingScreen(),
                '/settings': (context) => const SettingsScreen(),
              },
            );
          },
        ),
      ),
    );
  }
}
