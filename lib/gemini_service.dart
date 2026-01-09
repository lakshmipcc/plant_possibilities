import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  String _apiKey = '';

  GeminiService();

  /// Manually override the key (e.g., via the "Double-Tap" hidden menu)
  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    debugPrint('DEBUG: API Key manually overridden.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_api_key', _apiKey);
  }

  Future<void> _ensureInitialized() async {
    // If already set and valid, don't re-run
    if (_apiKey.isNotEmpty && _apiKey != 'MISSING_KEY') return;

    // PRIORITY 1: The "Stealth" method (GitHub Actions / Production)
    // This bakes the key into the app at build-time using --dart-define
    const String k1 = String.fromEnvironment('K1');
    const String k2 = String.fromEnvironment('K2');

    if (k1.isNotEmpty && k2.isNotEmpty) {
      _apiKey = (k1 + k2).trim();
      debugPrint('DEBUG: Using reconstructed stealth key from build environment.');
      return;
    }

    // PRIORITY 2: Local Storage Fallback (Manual user entry)
    // If the user previously used the "Double-Tap" menu, use that key.
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKey = prefs.getString('saved_api_key');
      if (storedKey != null && storedKey.isNotEmpty) {
        _apiKey = storedKey.trim();
        debugPrint('DEBUG: Using saved API key from device storage.');
        return;
      }
    } catch (e) {
      debugPrint('WARNING: Storage check failed: $e');
    }

    // PRIORITY 3: Single Env Variable (For local 'flutter run' testing)
    const String directKey = String.fromEnvironment('GEMINI_API_KEY');
    if (directKey.isNotEmpty) {
      _apiKey = directKey.trim();
      debugPrint('DEBUG: Using direct GEMINI_API_KEY from dart-define.');
      return;
    }

    _apiKey = 'MISSING_KEY';
  }

  Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String filename) async {
    await _ensureInitialized();

    if (_apiKey == 'MISSING_KEY') {
      throw Exception('API Key Missing. Double-tap the version number to enter a key manually.');
    }

    // 1. Try Local JSON Cache first
    try {
      final localData = await _loadLocalData(filename);
      return localData;
    } catch (_) {
      debugPrint('DEBUG: No local match for $filename. Consulting Gemini...');
    }

    // 2. AI Identification (Modern 2026 Model List)
    final List<String> modelNames = [
      'gemini-3-flash',      // Highest Priority
      'gemini-2.5-flash',    // Stable 
      'gemini-1.5-flash',    // Legacy
    ];

    Object? lastError;

    for (final modelName in modelNames) {
      try {
        final currentModel = GenerativeModel(model: modelName, apiKey: _apiKey);
        
        final prompt = 'Identify this plant. Return ONLY JSON: {"commonName": "...", "scientificName": "...", "funFact": "..."}';

        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        ];

        final response = await currentModel.generateContent(content);
        final text = response.text;

        if (text == null || text.isEmpty) continue;

        // Extract JSON block even if model includes markdown
        String cleanJson = text.trim();
        if (cleanJson.contains('{')) {
          cleanJson = cleanJson.substring(cleanJson.indexOf('{'), cleanJson.lastIndexOf('}') + 1);
        }

        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        lastError = e;
        debugPrint('DEBUG: Model $modelName failed: $e');
      }
    }

    throw Exception('All AI models failed. Last Error: $lastError');
  }

  Future<Map<String, dynamic>> _loadLocalData(String filename) async {
    const String assetPath = 'assets/plants/plants_data.json';
    final String response = await rootBundle.loadString(assetPath, cache: false);
    final data = json.decode(response);
    
    if (data[filename] != null) {
      return data[filename];
    }
    throw Exception('Not in local database');
  }
}