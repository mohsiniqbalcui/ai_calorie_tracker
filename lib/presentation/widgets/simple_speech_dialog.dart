import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/speech_service.dart';
import 'text_input_dialog.dart';

class SimpleSpeechDialog extends StatefulWidget {
  final Function(String) onSubmitted;

  const SimpleSpeechDialog({
    Key? key,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<SimpleSpeechDialog> createState() => _SimpleSpeechDialogState();
}

class _SimpleSpeechDialogState extends State<SimpleSpeechDialog> {
  final SpeechService _speechService = SpeechService();
  String _recognizedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  int _recordingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      print('Initializing speech service...');
      final available = await _speechService.initialize();
      print('Speech service available: $available');
    } catch (e) {
      print('Error initializing speech: $e');
    }
  }

  void _startListening() async {
    print('Starting to listen...');
    
    if (!_speechService.isInitialized) {
      print('Speech service not initialized, trying to initialize...');
      final available = await _speechService.initialize();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available. Please use text input.')),
        );
        return;
      }
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _recordingTime = 0;
    });

    print('Starting timer...');
    // Start timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTime++;
      });
      
      if (_recordingTime >= 20) {
        print('Timer reached 20 seconds, stopping...');
        _stopListening();
        // Add a small delay to ensure stopListening completes
        Future.delayed(Duration(milliseconds: 500), () {
          if (_recognizedText.trim().isNotEmpty) {
            print('Auto-submitting recognized text: $_recognizedText');
            _handleSubmit();
          }
        });
      }
    });

    print('Starting speech recognition...');
    await _speechService.startListening(
      onResult: (text) {
        print('Speech result: $text');
        setState(() {
          _recognizedText = text;
        });
      },
      onError: (error) {
        print('Speech error: $error');
        _stopListening();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: $error')),
        );
      },
    );
  }

  void _stopListening() {
    print('Stopping listening...');
    _speechService.stopListening();
    _timer?.cancel();
    setState(() {
      _isListening = false;
    });
    print('Stopped listening. Current recognized text: $_recognizedText');
  }

  void _handleManualStop() {
    print('Manual stop triggered');
    _stopListening();
    // Add a small delay to ensure stopListening completes
    Future.delayed(Duration(milliseconds: 500), () {
      if (_recognizedText.trim().isNotEmpty) {
        print('Manual submission with recognized text: $_recognizedText');
        _handleSubmit();
      } else {
        print('No text recognized, showing message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No speech detected. Please try again or use text input.')),
        );
      }
    });
  }

  void _handleSubmit() async {
    print('=== HANDLE SUBMIT CALLED ===');
    print('Recognized text: "$_recognizedText"');
    print('Text length: ${_recognizedText.length}');
    print('Text trimmed: "${_recognizedText.trim()}"');
    print('Text trimmed length: ${_recognizedText.trim().length}');
    
    if (_recognizedText.trim().isEmpty) {
      print('Text is empty, showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please speak a food description')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('Calling widget.onSubmitted with: "${_recognizedText.trim()}"');
      await widget.onSubmitted(_recognizedText.trim());
      print('Successfully submitted to Gemini API');
      Navigator.of(context).pop();
    } catch (e) {
      print('Error submitting to Gemini API: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (context) => TextInputDialog(
        title: 'Add Food Item',
        hintText: 'Describe the food you ate (e.g., "Grilled chicken breast with rice")',
        onSubmitted: (text) async {
          await widget.onSubmitted(text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Voice Input'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer display
          if (_isListening) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child:                   Text(
                    '${_recordingTime}s / 20s',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
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
              boxShadow: _isListening ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ] : null,
            ),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 50,
              ),
              onPressed: _isProcessing ? null : (_isListening ? _handleManualStop : _startListening),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _isListening ? 'Listening... Tap to stop' : 'Tap to start speaking',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          
          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: _isListening ? Colors.blue : Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: _isListening ? Colors.blue.withOpacity(0.05) : null,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isListening) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Listening... Speak now',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Processing indicator
          if (_isProcessing) ...[
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _isProcessing ? null : () {
            Navigator.of(context).pop();
            _showTextInputDialog();
          },
          child: Text('Text Input'),
        ),
        ElevatedButton(
          onPressed: _isProcessing || _recognizedText.isEmpty ? null : _handleSubmit,
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
