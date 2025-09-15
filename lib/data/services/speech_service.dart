import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    try {
      // Check if we're on web platform
      if (kIsWeb) {
        // On web, speech recognition might not be available
        final available = await _speechToText.initialize();
        _isInitialized = available;
        return available;
      }

      // For mobile platforms, check and request microphone permission
      PermissionStatus status = await Permission.microphone.status;
      
      if (status == PermissionStatus.denied) {
        // Request permission
        status = await Permission.microphone.request();
      }
      
      if (status == PermissionStatus.permanentlyDenied) {
        _isInitialized = false;
        return false;
      }
      
      if (status != PermissionStatus.granted) {
        _isInitialized = false;
        return false;
      }

      // Initialize speech to text
      final available = await _speechToText.initialize();
      _isInitialized = available;
      
      if (!available) {
        print('Speech recognition initialization failed');
      }
      
      return available;
    } catch (e) {
      print('Error initializing speech service: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<String?> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!await initialize()) {
      onError('Speech recognition not available or permission denied');
      return null;
    }

    if (_isListening) {
      stopListening();
    }

    _isListening = true;
    String? recognizedText;

    await _speechToText.listen(
      onResult: (result) {
        print('Speech recognition result: ${result.recognizedWords}');
        print('Final result: ${result.finalResult}');
        recognizedText = result.recognizedWords;
        onResult(result.recognizedWords);
      },
      listenFor: Duration(seconds: 20),
      pauseFor: Duration(seconds: 2),
      partialResults: true,
      localeId: 'en_US',
      onSoundLevelChange: (level) {
        // Optional: Handle sound level changes
        print('Sound level: $level');
      },
    );

    return recognizedText;
  }

  void stopListening() {
    if (_isListening) {
      print('Stopping speech recognition...');
      _speechToText.stop();
      _isListening = false;
      print('Speech recognition stopped');
    }
  }

  void cancelListening() {
    if (_isListening) {
      _speechToText.cancel();
      _isListening = false;
    }
  }

  Future<bool> isAvailable() async {
    return await _speechToText.initialize();
  }

  Future<PermissionStatus> getMicrophonePermissionStatus() async {
    if (kIsWeb) {
      return PermissionStatus.granted; // Web doesn't need explicit permission
    }
    return await Permission.microphone.status;
  }

  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) {
      return true; // Web doesn't need explicit permission
    }
    
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  bool get isCurrentlyListening => _isListening;
}
