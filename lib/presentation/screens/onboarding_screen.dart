import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../data/local/preference_manager.dart';
import '../../data/models/user_data.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/settings_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
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
  Map<String, int> macros = const {};
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

  static const _activityLevels = <_Choice>[
    _Choice(
        'Sedentary', 'Little or no exercise, desk job', Icons.weekend_rounded),
    _Choice(
        'Light', '1-3 days/week of exercise', Icons.directions_walk_rounded),
    _Choice('Moderate', '3-5 days/week of moderate activity',
        Icons.directions_bike_rounded),
    _Choice(
        'Active', '6-7 days/week of exercise', Icons.fitness_center_rounded),
    _Choice('Very Active', 'Intense training or a physical job',
        Icons.bolt_rounded),
  ];

  static const _genders = <_Choice>[
    _Choice('Male', 'Used for your metabolic rate', Icons.male_rounded),
    _Choice('Female', 'Used for your metabolic rate', Icons.female_rounded),
    _Choice('Other', 'We use an average of both', Icons.person_rounded),
  ];

  static const _goals = <_Choice>[
    _Choice('Weight Loss', '20% calorie deficit, higher protein',
        Icons.trending_down_rounded),
    _Choice(
        'Maintenance', 'Stay at your current weight', Icons.balance_rounded),
    _Choice('Muscle Gain', '15% calorie surplus for growth',
        Icons.trending_up_rounded),
  ];

  static const _lastInputPage = 5;
  static const _welcomePage = 6;

  Future<void> _savePreferences() async {
    final maintenanceCalories = CalorieCalculator.fallbackEstimateCalories(
      weight: weight!,
      height: height!,
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
      macros = macroGoals;
    });

    final userData = UserData(
      weight: weight!,
      height: height!,
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

  bool get _canContinue => switch (_currentPage) {
        0 => weight != null && weight! >= 20 && weight! <= 400,
        1 => height != null && height! >= 80 && height! <= 260,
        2 => age != null && age! >= 10 && age! <= 110,
        3 => activityLevel != null,
        4 => gender != null,
        5 => userGoal != null,
        _ => true,
      };

  void _goTo(int page) {
    FocusManager.instance.primaryFocus?.unfocus();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _next() async {
    if (!_canContinue) return;
    HapticFeedback.selectionClick();
    if (_currentPage == _lastInputPage) {
      await _savePreferences();
      if (!mounted) return;
      _goTo(_welcomePage);
    } else if (_currentPage == _welcomePage) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      _goTo(_currentPage + 1);
    }
  }

  Future<void> _skipToMain() async {
    // Mark onboarding as complete even when skipped
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/main');
  }

  // ---- UI ---------------------------------------------------------------

  Widget _illustration(String assetPath) {
    final size = MediaQuery.of(context).size;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: keyboardOpen
          ? const SizedBox(width: double.infinity)
          : Container(
              height: size.height * 0.32,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
    );
  }

  Widget _stepPage({
    required String title,
    required String subtitle,
    required String asset,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _illustration(asset),
          Text(title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String unit,
    required String hint,
    required bool decimal,
    required void Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(decimal ? r'[0-9.]' : r'[0-9]')),
        LengthLimitingTextInputFormatter(5),
      ],
      textAlign: TextAlign.center,
      style:
          theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      onChanged: (v) {
        onChanged(v);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: hint,
        suffixText: unit,
        suffixStyle: theme.textTheme.titleLarge
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      ),
    );
  }

  Widget _choiceList(
      List<_Choice> choices, String? selected, void Function(String) onSelect) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        for (final c in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              button: true,
              selected: selected == c.key,
              label: '${c.key}. ${c.subtitle}',
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(c.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected == c.key
                        ? scheme.primaryContainer
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected == c.key
                          ? scheme.primary
                          : scheme.outlineVariant,
                      width: selected == c.key ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: selected == c.key
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        child: Icon(c.icon,
                            color: selected == c.key
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.key,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(c.subtitle,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (selected == c.key)
                        Icon(Icons.check_circle_rounded, color: scheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWelcome = _currentPage == _welcomePage;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            if (!isWelcome)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: _currentPage > 0
                          ? IconButton(
                              tooltip: 'Back',
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => _goTo(_currentPage - 1),
                            )
                          : null,
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                              end: (_currentPage + 1) / (_lastInputPage + 1)),
                          duration: const Duration(milliseconds: 300),
                          builder: (_, v, __) =>
                              LinearProgressIndicator(value: v, minHeight: 6),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: TextButton(
                          onPressed: _skipToMain, child: const Text('Skip')),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  if (index < _welcomePage)
                    _saveDraftValue(_draftPageKey, index);
                },
                children: [
                  _stepPage(
                    title: 'What is your weight?',
                    subtitle: 'We use it to work out your daily energy needs.',
                    asset: 'assets/onboarding/onboarding_weight.png',
                    child: _numberField(
                      controller: _weightController,
                      unit: 'kg',
                      hint: '70',
                      decimal: true,
                      onChanged: (value) {
                        weight = double.tryParse(value);
                        _saveDraftValue(_draftWeightKey, weight);
                        _saveDraftValue('${_draftWeightKey}_text', value);
                      },
                    ),
                  ),
                  _stepPage(
                    title: 'How tall are you?',
                    subtitle: 'Height helps us estimate your metabolic rate.',
                    asset: 'assets/onboarding/onboarding_height.png',
                    child: _numberField(
                      controller: _heightController,
                      unit: 'cm',
                      hint: '170',
                      decimal: true,
                      onChanged: (value) {
                        height = double.tryParse(value);
                        _saveDraftValue(_draftHeightKey, height);
                        _saveDraftValue('${_draftHeightKey}_text', value);
                      },
                    ),
                  ),
                  _stepPage(
                    title: 'How old are you?',
                    subtitle: 'Metabolism changes with age.',
                    asset: 'assets/onboarding/onboarding_age.png',
                    child: _numberField(
                      controller: _ageController,
                      unit: 'years',
                      hint: '30',
                      decimal: false,
                      onChanged: (value) {
                        age = int.tryParse(value);
                        _saveDraftValue(_draftAgeKey, age);
                        _saveDraftValue('${_draftAgeKey}_text', value);
                      },
                    ),
                  ),
                  _stepPage(
                    title: 'How active are you?',
                    subtitle: 'Pick what fits a typical week.',
                    asset: 'assets/onboarding/onboarding_activity_level.png',
                    child: _choiceList(_activityLevels, activityLevel, (v) {
                      setState(() => activityLevel = v);
                      _saveDraftValue(_draftActivityKey, v);
                    }),
                  ),
                  _stepPage(
                    title: 'Select your gender',
                    subtitle: 'This only affects the calorie formula.',
                    asset: 'assets/onboarding/onboarding_gender.png',
                    child: _choiceList(_genders, gender, (v) {
                      setState(() => gender = v);
                      _saveDraftValue(_draftGenderKey, v);
                    }),
                  ),
                  _stepPage(
                    title: 'What is your goal?',
                    subtitle: 'You can change this any time in Settings.',
                    asset: 'assets/onboarding/onboarding_goal.png',
                    child: _choiceList(_goals, userGoal, (v) {
                      setState(() => userGoal = v);
                      _saveDraftValue(_draftGoalKey, v);
                    }),
                  ),
                  _buildWelcomePage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _canContinue ? _next : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    textStyle: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: Text(switch (_currentPage) {
                    _lastInputPage => 'See my plan',
                    _welcomePage => 'Start tracking',
                    _ => 'Continue',
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget macro(String label, int grams, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('${grams}g',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          _illustration('assets/onboarding/onboarding_welcome.png'),
          Text('Your plan is ready',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Welcome to Calorie Lens',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.78)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text('Daily calorie target',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.85))),
                const SizedBox(height: 6),
                Text('$estimatedCalories',
                    style: theme.textTheme.displayMedium?.copyWith(
                        color: scheme.onPrimary, fontWeight: FontWeight.w900)),
                Text('kcal / day',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              macro('Protein', macros['proteinGoal'] ?? 0, MacroColors.protein),
              const SizedBox(width: 10),
              macro('Carbs', macros['carbsGoal'] ?? 0, MacroColors.carbs),
              const SizedBox(width: 10),
              macro('Fat', macros['fatGoal'] ?? 0, MacroColors.fat),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice {
  final String key;
  final String subtitle;
  final IconData icon;
  const _Choice(this.key, this.subtitle, this.icon);
}
