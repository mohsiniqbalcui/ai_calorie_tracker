import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/speech_service.dart';
import 'text_input_dialog.dart';
import 'permission_dialog.dart';

class SpeechInputDialog extends StatefulWidget {
  final Function(String) onSubmitted;

  const SpeechInputDialog({
    Key? key,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<SpeechInputDialog> createState() => _SpeechInputDialogState();
}

class _SpeechInputDialogState extends State<SpeechInputDialog> {
  final SpeechService _speechService = SpeechService();
  String _recognizedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isInitializing = true;
  int _recordingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialize speech after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeech();
    });
  }

  void _showWebNotSupportedError() {
    setState(() {
      _isInitializing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Voice input is not supported on web browsers. Please use text input instead.'),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Use Text Input',
          onPressed: () {
            Navigator.of(context).pop();
            _showTextInputDialog();
          },
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _initializeSpeech() async {
    try {
      debugPrint('Starting speech initialization...');

      if (kIsWeb) {
        setState(() {
          _isInitializing = false;
        });
        _showWebNotSupportedError();
        return;
      }

      // Check permission status first
      final permissionStatus =
          await _speechService.getMicrophonePermissionStatus();
      debugPrint('Permission status: $permissionStatus');

      if (permissionStatus == PermissionStatus.denied) {
        setState(() {
          _isInitializing = false;
        });
        // Show permission dialog
        PermissionDialog.showMicrophonePermissionDialog(
          context,
          onGranted: () async {
            await _tryInitializeSpeech();
          },
          onDenied: () {
            _showTextInputDialog();
          },
        );
        return;
      }

      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        setState(() {
          _isInitializing = false;
        });
        _showPermissionDeniedError();
        return;
      }

      await _tryInitializeSpeech();
    } catch (e) {
      debugPrint('Error in _initializeSpeech: $e');
      setState(() {
        _isInitializing = false;
      });
      _showErrorAndFallback('Failed to initialize speech recognition: $e');
    }
  }

  Future<void> _tryInitializeSpeech() async {
    debugPrint('Attempting to initialize speech recognition...');
    final available = await _speechService.initialize();
    debugPrint('Speech recognition available: $available');

    setState(() {
      _isInitializing = false;
    });

    if (!available && mounted) {
      debugPrint('Speech recognition not available, showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Speech recognition not available. Please try text input instead.'),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Use Text Input',
            onPressed: () {
              Navigator.of(context).pop();
              _showTextInputDialog();
            },
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      debugPrint('Speech recognition initialized successfully');
    }
  }

  void _showPermissionDeniedError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Microphone permission is permanently denied. Please enable it in device settings.'),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Use Text Input',
          onPressed: () {
            Navigator.of(context).pop();
            _showTextInputDialog();
          },
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  void _showErrorAndFallback(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Speech recognition error: $error'),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Use Text Input',
          onPressed: () {
            Navigator.of(context).pop();
            _showTextInputDialog();
          },
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (context) => TextInputDialog(
        title: 'Add Food Item',
        hintText:
            'Describe the food you ate (e.g., "Grilled chicken breast with rice")',
        onSubmitted: (text) async {
          await widget.onSubmitted(text);
        },
      ),
    );
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _recordingTime = 0;
    });

    // Start the timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTime++;
      });

      // Auto-stop after 30 seconds
      if (_recordingTime >= 30) {
        _stopListening();
        // Auto-submit if there's recognized text
        if (_recognizedText.trim().isNotEmpty) {
          _handleSubmit();
        }
      }
    });

    await _speechService.startListening(onPartial: (text) {
      debugPrint('Speech partial: $text');
      setState(() {
        _recognizedText = text;
      });
    }, onFinal: (text) {
      debugPrint('Speech final: $text');
      setState(() {
        if (_recognizedText.isEmpty) {
          _recognizedText = text;
        } else if (!_recognizedText.trim().endsWith(text.trim())) {
          _recognizedText = '${_recognizedText.trim()} ${text.trim()}'.trim();
        }
      });
    }, onError: (error) {
      _stopListening();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition error: $error')),
      );
    });
  }

  void _stopListening() {
    _speechService.stopListening();
    _timer?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  void _handleSubmit() async {
    if (_recognizedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please speak a food description')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await widget.onSubmitted(_recognizedText.trim());
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Voice Input'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Loading state
          if (_isInitializing) ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initializing speech recognition...',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Fallback UI when speech is not available
            if (!_speechService.isInitialized) ...[
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Speech recognition not available',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please use text input instead',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showTextInputDialog();
                      },
                      child: Text('Use Text Input'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Timer display
              if (_isListening) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '${_recordingTime}s / 30s',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Progress bar
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _recordingTime / 30.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Microphone button
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : Colors.blue,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: _isProcessing
                      ? null
                      : (_isListening ? _stopListening : _startListening),
                ),
              ),
              SizedBox(height: 16),
              Text(
                _isListening
                    ? (_recordingTime >= 25
                        ? 'Recording will stop soon...'
                        : 'Listening... Tap to stop')
                    : 'Tap to start speaking',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isListening && _recordingTime >= 25
                          ? Colors.orange
                          : null,
                      fontWeight: _isListening && _recordingTime >= 25
                          ? FontWeight.bold
                          : null,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_recognizedText.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _isListening ? Colors.blue : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: _isListening
                        ? Colors.blue.withValues(alpha: 0.05)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recognized Text:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _recognizedText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              if (_isProcessing) ...[
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: (_isProcessing || _isInitializing)
              ? null
              : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              (_isProcessing || _isInitializing || _recognizedText.isEmpty)
                  ? null
                  : _handleSubmit,
          child: _isProcessing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Add Food'),
        ),
      ],
    );
  }
}
