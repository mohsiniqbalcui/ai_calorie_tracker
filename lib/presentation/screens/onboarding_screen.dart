import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../data/local/preference_manager.dart';
import '../../data/models/user_data.dart';
import '../cubit/settings_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  double? weight;
  double? height; // Added height field
  int? age;
  String? activityLevel;
  String? gender;
  int estimatedCalories = 0;
  String? userGoal;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  static const _draftWeightKey = 'onboarding_draft_weight';
  static const _draftHeightKey = 'onboarding_draft_height';
  static const _draftAgeKey = 'onboarding_draft_age';
  static const _draftActivityKey = 'onboarding_draft_activity_level';
  static const _draftGenderKey = 'onboarding_draft_gender';
  static const _draftGoalKey = 'onboarding_draft_goal';
  static const _draftPageKey = 'onboarding_draft_page';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Restores whatever the user entered before the app was closed.
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = (prefs.getInt(_draftPageKey) ?? 0).clamp(0, 5);
    if (!mounted) return;
    setState(() {
      weight = prefs.getDouble(_draftWeightKey);
      height = prefs.getDouble(_draftHeightKey);
      age = prefs.getInt(_draftAgeKey);
      activityLevel = prefs.getString(_draftActivityKey);
      gender = prefs.getString(_draftGenderKey);
      userGoal = prefs.getString(_draftGoalKey);
      _weightController.text = prefs.getString('${_draftWeightKey}_text') ?? '';
      _heightController.text = prefs.getString('${_draftHeightKey}_text') ?? '';
      _ageController.text = prefs.getString('${_draftAgeKey}_text') ?? '';
    });
    if (savedPage > 0) {
      _pageController.jumpToPage(savedPage);
    }
  }

  Future<void> _saveDraftValue(String key, Object? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _draftWeightKey,
      _draftHeightKey,
      _draftAgeKey,
      _draftActivityKey,
      _draftGenderKey,
      _draftGoalKey,
      _draftPageKey,
      '${_draftWeightKey}_text',
      '${_draftHeightKey}_text',
      '${_draftAgeKey}_text',
    ]) {
      await prefs.remove(key);
    }
  }

  // Activity level descriptions for better user understanding
  final Map<String, String> activityLevelDescriptions = {
    'Sedentary': 'Little or no exercise, desk job',
    'Light': '1-3 days/week of exercise',
    'Moderate': '3-5 days/week of moderate activity',
    'Active': '6-7 days/week of exercise',
    'Very Active': 'Very intense exercise/sports & physical job'
  };

  Future<void> _savePreferences() async {
    final maintenanceCalories = CalorieCalculator.fallbackEstimateCalories(
      weight: weight!,
      height: height!, // Added height parameter
      age: age!,
      activityLevel: activityLevel!,
      gender: gender!,
    );

    final adjustedCalories = CalorieCalculator.calculateCaloriesBasedOnGoal(
      maintenanceCalories: maintenanceCalories,
      goal: userGoal!,
    );

    final macroGoals = CalorieCalculator.calculateMacroGoals(
      calories: adjustedCalories,
      goal: userGoal!,
    );

    setState(() {
      estimatedCalories = adjustedCalories;
    });

    final userData = UserData(
      weight: weight!,
      height: height!, // Added height
      age: age!,
      activityLevel: activityLevel!,
      gender: gender!,
      goal: userGoal!,
      estimatedCalories: adjustedCalories,
      proteinGoal: macroGoals['proteinGoal']!,
      fatGoal: macroGoals['fatGoal']!,
      carbsGoal: macroGoals['carbsGoal']!,
    );

    final prefs = await SharedPreferences.getInstance();
    final prefManager = PreferenceManager(prefs);
    await prefManager.saveUserData(userData);
    
    // Mark onboarding as complete
    await prefs.setBool('onboarding_complete', true);
    await _clearDraft();
    if (mounted) context.read<SettingsCubit>().reload();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      if (_currentPage == 5) {
        _savePreferences();
      }
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _skipToMain() async {
    // Mark onboarding as complete even when skipped
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    Navigator.pushReplacementNamed(context, '/main');
  }

  Widget _buildPage(String title, String assetPath, Widget inputField) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - bottomInset),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: (constraints.maxHeight - bottomInset) * 0.55,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    inputField,
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityLevelDropdown() {
    return Column(
      children: [
        DropdownButton<String>(
          value: activityLevel,
          isExpanded: true,
          items: activityLevelDescriptions.entries
              .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          entry.value,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => activityLevel = value);
            _saveDraftValue(_draftActivityKey, value);
          },
          hint: Text('Select Activity Level'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing up content
      appBar: _currentPage == 0 ? AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skipToMain,
            child: Text('Skip'),
          ),
        ],
      ) : null,
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          if (index < 6) _saveDraftValue(_draftPageKey, index);
        },
        children: [
          _buildPage(
            'Enter Your Weight',
            'assets/onboarding/onboarding_weight.png',
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                weight = double.tryParse(value);
                _saveDraftValue(_draftWeightKey, weight);
                _saveDraftValue('${_draftWeightKey}_text', value);
              },
              decoration: InputDecoration(labelText: 'Weight in kg'),
            ),
          ),
          _buildPage(
            'Enter Your Height',
            'assets/onboarding/onboarding_height.png',
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                height = double.tryParse(value);
                _saveDraftValue(_draftHeightKey, height);
                _saveDraftValue('${_draftHeightKey}_text', value);
              },
              decoration: InputDecoration(labelText: 'Height in cm'),
            ),
          ),
          _buildPage(
            'Enter Your Age',
            'assets/onboarding/onboarding_age.png',
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                age = int.tryParse(value);
                _saveDraftValue(_draftAgeKey, age);
                _saveDraftValue('${_draftAgeKey}_text', value);
              },
              decoration: InputDecoration(labelText: 'Age in years'),
            ),
          ),
          _buildPage(
            'Select Your Activity Level',
            'assets/onboarding/onboarding_activity_level.png',
            _buildActivityLevelDropdown(),
          ),
          _buildPage(
            'Select Your Gender',
            'assets/onboarding/onboarding_gender.png',
            DropdownButton<String>(
              value: gender,
              isExpanded: true,
              items: ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (value) {
                setState(() => gender = value);
                _saveDraftValue(_draftGenderKey, value);
              },
              hint: Text('Select Your Gender'),
            ),
          ),
          _buildPage(
            'What is your goal?',
            'assets/onboarding/onboarding_goal.png',
            DropdownButton<String>(
              value: userGoal,
              isExpanded: true,
              items: ['Weight Loss', 'Maintenance', 'Muscle Gain']
                  .map((goal) => DropdownMenuItem(value: goal, child: Text(goal)))
                  .toList(),
              onChanged: (value) {
                setState(() => userGoal = value);
                _saveDraftValue(_draftGoalKey, value);
              },
              hint: Text('Select Your Goal'),
            ),
          ),
          _buildWelcomePage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 48,
                width: 120,
                child: TextButton(
                  onPressed: _currentPage > 0 
                    ? () => _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                  child: Text(
                    _currentPage > 0 ? 'Back' : '',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                width: 120,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == 6 ? 'Finish' : 'Next',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
            child: Image.asset(
              'assets/onboarding/onboarding_welcome.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  'Welcome to Calorie Lens!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Your Daily Calorie Target',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$estimatedCalories kcal',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}