import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Voice recognition service for continuous item input
/// Handles permissions, speech-to-text, and real-time transcription
class VoiceRecognitionService extends ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _currentTranscript = '';
  String _selectedLanguage = 'te-IN'; // Telugu by default
  bool _hasPermission = false;
  String? _errorMessage;
  bool _disposed = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get currentTranscript => _currentTranscript;
  String get selectedLanguage => _selectedLanguage;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  /// Available languages for voice input
  /// All major Indian languages supported by Google Speech API
  static const Map<String, String> availableLanguages = {
    'te-IN': 'Telugu (తెలుగు)',
    'hi-IN': 'Hindi (हिन्दी)',
    'en-IN': 'English',
    'ta-IN': 'Tamil (தமிழ்)',
    'kn-IN': 'Kannada (ಕನ್ನಡ)',
    'ml-IN': 'Malayalam (മലയാളം)',
    'mr-IN': 'Marathi (मराठी)',
    'gu-IN': 'Gujarati (ગુજરાતી)',
    'pa-IN': 'Punjabi (ਪੰਜਾਬੀ)',
    'bn-IN': 'Bengali (বাংলা)',
    'or-IN': 'Odia (ଓଡ଼ିଆ)',
  };

  /// Initialize speech recognition and check permissions
  Future<bool> initialize() async {
    try {
      _errorMessage = null;

      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      _hasPermission = permissionStatus.isGranted;

      if (!_hasPermission) {
        _errorMessage = 'Microphone permission is required for voice input';
        _notifyListeners();
        return false;
      }

      // Initialize speech recognition
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _errorMessage = error.errorMsg;
          _isListening = false;
          _notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _notifyListeners();
          }
        },
      );

      _notifyListeners();
      return _isInitialized;
    } catch (e) {
      _errorMessage = 'Failed to initialize voice recognition: ${e.toString()}';
      _isInitialized = false;
      _notifyListeners();
      return false;
    }
  }

  /// Change the selected language
  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    _notifyListeners();
  }

  /// Start listening for voice input
  /// Supports continuous mode for merchant billing workflow
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    bool continuousMode = false, // NEW: Keep listening after each phrase
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (_isListening) return;

    try {
      _errorMessage = null;
      _currentTranscript = '';

      await _speechToText.listen(
        onResult: (result) {
          _currentTranscript = result.recognizedWords;

          if (result.finalResult) {
            // Final result - process item
            final transcript = _currentTranscript;

            // In continuous mode, keep listening; otherwise stop
            if (!continuousMode) {
              _currentTranscript = '';
              _isListening = false;
            } else {
              // Clear transcript but stay listening for next phrase
              _currentTranscript = '';
              print(
                '🔄 Continuous mode: Cleared transcript, still listening...',
              );
            }

            onResult(transcript);
          } else if (onPartialResult != null) {
            // Partial result - show live transcription
            onPartialResult(_currentTranscript);
          }

          _notifyListeners();
        },
        localeId: _selectedLanguage,
        listenMode: stt.ListenMode.dictation, // Continuous listening
        pauseFor: continuousMode
            ? const Duration(seconds: 3) // Shorter pause in continuous mode
            : const Duration(seconds: 8), // Longer pause for single-shot
        partialResults: true, // Enable live transcription
        cancelOnError: false,
        listenFor: continuousMode
            ? const Duration(minutes: 10) // 10 minutes in continuous mode
            : const Duration(seconds: 30), // 30 seconds in single-shot
      );

      _isListening = true;
      _notifyListeners();
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        _errorMessage =
            'No internet connection. Voice recognition requires internet.';
      } else if (e.toString().contains('permission')) {
        _errorMessage =
            'Microphone permission denied. Please enable it in settings.';
      } else {
        _errorMessage = 'Could not start microphone. Please try again';
      }
      _isListening = false;
      _notifyListeners();
      print('❌ Voice recognition error: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _currentTranscript = '';
      _notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not stop microphone';
      _notifyListeners();
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      _currentTranscript = '';
      _notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not cancel';
      _notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    _notifyListeners();
  }

  /// Safely notify listeners only if not disposed
  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _speechToText.stop();
    super.dispose();
  }
}
