import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import '../cubit/food_log_cubit.dart';
import '../widgets/daily_tracker.dart';
import '../widgets/meal_list.dart';
import '../widgets/alert_message_widget.dart';
import '../widgets/text_input_dialog.dart';
import '../widgets/speech_input_dialog.dart';
import '../widgets/simple_speech_dialog.dart';
    import 'package:device_info_plus/device_info_plus.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final picker = ImagePicker();
  File? _image;

  Future<void> getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      scanImage();
    }
  }

  void scanImage() async {
    context.read<FoodLogCubit>().addMealFromImage(_image!);
  }

  void showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              getImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Gallery'),
            onTap: () {
              Navigator.pop(context);
              getImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Text Input'),
            onTap: () {
              Navigator.pop(context);
              _showTextInputDialog(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.mic),
            title: Text('Voice Input'),
            subtitle: kIsWeb ? Text('Not available on web') : null,
            enabled: !kIsWeb,
            onTap: kIsWeb ? null : () {
              Navigator.pop(context);
              _showSpeechInputDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _ensurePermissions() async {
    if (kIsWeb) return true; // Web handles permissions differently

    // Check Android API level to determine if we need storage permission
    bool needsStoragePermission = true;

// In _ensurePermissions():
if (Platform.isAndroid) {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  needsStoragePermission = androidInfo.version.sdkInt < 33; // API 33 = Android 13
}

    List<Permission> permissionsToRequest = [
      Permission.camera,
      Permission.microphone,
    ];

    // Only add storage permission for older Android versions
    if (needsStoragePermission) {
      permissionsToRequest.add(Permission.storage);
    }

    final Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

    final allGranted = statuses.values.every((s) => s.isGranted);

    if (!allGranted) {
      String permissionText = needsStoragePermission 
          ? 'Please grant Camera, Microphone, and Storage permissions.'
          : 'Please grant Camera and Microphone permissions.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(permissionText)),
      );
    }

    return allGranted;
  }

  void _showTextInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TextInputDialog(
        title: 'Add Food Item',
        hintText: 'Describe the food you ate (e.g., "Grilled chicken breast with rice")',
        onSubmitted: (text) async {
          await context.read<FoodLogCubit>().addMealFromText(text);
        },
      ),
    );
  }

  void _showSpeechInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleSpeechDialog(
        onSubmitted: (text) async {
          await context.read<FoodLogCubit>().addMealFromText(text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calorie Tracker'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's trackers", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 16),
                BlocBuilder<FoodLogCubit, FoodLogState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      // Tracker Section
                      DailyTracker(
                        calories: state.totalCalories,
                        protein: state.totalProtein,
                        carbs: state.totalCarbs,
                        fat: state.totalFat,
                      ),
                      SizedBox(height: 24),

                      // Inline Alert Section for Success or Error
                      if (state.successMessage != null || state.error != null)
                          AlertMessageWidget(
                            errorMessage: state.error,
                            successMessage: state.successMessage,
                            onClose: () => context.read<FoodLogCubit>().clearMessages(),
                          ),

                      // Meals Section
                      Text('Meals', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 16),
                      MealList(meals: state.meals),
                    ],
                  );
                },
              ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await _ensurePermissions();
          if (ok) {
            showImageSourceActionSheet(context);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}