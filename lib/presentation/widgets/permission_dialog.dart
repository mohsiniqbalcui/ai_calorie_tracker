import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGranted;
  final VoidCallback? onDenied;

  const PermissionDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onGranted,
    this.onDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDenied?.call();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final status = await Permission.microphone.request();
            if (status == PermissionStatus.granted) {
              onGranted();
            } else {
              onDenied?.call();
            }
          },
          child: Text('Grant Permission'),
        ),
      ],
    );
  }

  static void showMicrophonePermissionDialog(
    BuildContext context, {
    required VoidCallback onGranted,
    VoidCallback? onDenied,
  }) {
    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
        title: 'Microphone Permission Required',
        message: 'This app needs microphone access to use voice input for food logging. Please grant permission to continue.',
        onGranted: onGranted,
        onDenied: onDenied,
      ),
    );
  }
}
