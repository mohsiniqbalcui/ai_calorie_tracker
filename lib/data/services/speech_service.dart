import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  final Stopwatch _sessionStopwatch = Stopwatch();

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    try {
      // Check if we're on web platform
      if (kIsWeb) {
        // On web, speech recognition might not be available
        final available = await _speechToText.initialize(
          onStatus: _handleStatus,
          onError: (err) {
            print('Speech error (web): ${err.errorMsg}');
          },
        );
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
      final available = await _speechToText.initialize(
        onStatus: _handleStatus,
        onError: (err) {
          print('Speech error: ${err.errorMsg}');
        },
      );
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
    required Function(String) onPartial,
    required Function(String) onFinal,
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
    _sessionStopwatch
      ..reset()
      ..start();
    String? recognizedText;

    void startSession() {
      _speechToText.listen(
        onResult: (result) {
          print('Speech recognition result: ${result.recognizedWords}');
          print('Final result: ${result.finalResult}');
          recognizedText = result.recognizedWords;
          if (result.finalResult) {
            onFinal(result.recognizedWords);
          } else {
            onPartial(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
      );
    }

    startSession();

    return recognizedText;
  }

  void stopListening() {
    if (_isListening) {
      print('Stopping speech recognition...');
      _speechToText.stop();
      _isListening = false;
      _sessionStopwatch.stop();
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

  void _handleStatus(String status) {
    if (status == 'notListening' && _isListening) {
      if (_sessionStopwatch.isRunning &&
          _sessionStopwatch.elapsed < const Duration(seconds: 20)) {
        try {
          _speechToText.listen(
            onResult: (result) {},
            listenFor: const Duration(seconds: 20),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            localeId: 'en_US',
            listenMode: ListenMode.dictation,
            cancelOnError: false,
          );
        } catch (e) {
          print('Error auto-restarting listening: $e');
        }
      }
    }
  }
}
