import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionTest {
  static Future<void> testMicrophonePermission() async {
    print('Testing microphone permission...');

    // Check current status
    final status = await Permission.microphone.status;
    print('Current microphone permission status: $status');

    // Request permission if needed
    if (status == PermissionStatus.denied) {
      print('Requesting microphone permission...');
      final newStatus = await Permission.microphone.request();
      print('New microphone permission status: $newStatus');
    }

    // Test speech recognition availability
    print('Permission test completed');
  }
}
