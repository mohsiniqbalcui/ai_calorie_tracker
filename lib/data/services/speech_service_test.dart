import 'package:flutter/foundation.dart';
import 'speech_service.dart';

// Simple test to check speech service availability
class SpeechServiceTest {
  static Future<void> testSpeechService() async {
    print('Testing Speech Service...');
    print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    
    final speechService = SpeechService();
    
    try {
      final isAvailable = await speechService.initialize();
      print('Speech service available: $isAvailable');
      
      if (isAvailable) {
        print('✅ Speech recognition is working!');
      } else {
        print('❌ Speech recognition not available');
        if (kIsWeb) {
          print('   Reason: Web browsers have limited speech recognition support');
        } else {
          print('   Reason: Microphone permission denied or service not available');
        }
      }
    } catch (e) {
      print('❌ Error testing speech service: $e');
    }
  }
}
