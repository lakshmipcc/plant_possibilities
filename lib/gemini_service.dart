import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  String _apiKey = '';

  GeminiService();

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    debugPrint('DEBUG: API Key manually overridden. Length: ${_apiKey.length}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_api_key', _apiKey);
  }

  Future<void> _ensureInitialized() async {
    if (_apiKey.isNotEmpty && _apiKey != 'MISSING_KEY') return;

    // PRIORITY 1: The "Stealth" method (Split keys from deploy.yml)
    const String k1 = String.fromEnvironment('K1');
    const String k2 = String.fromEnvironment('K2');

    if (k1.isNotEmpty && k2.isNotEmpty) {
      _apiKey = (k1 + k2).trim();
      debugPrint('DEBUG: API Key reconstructed from stealth environment variables.');
      return;
    }

    // PRIORITY 2: Fallback to single environment key (Local development)
    String envKey = const String.fromEnvironment('GEMINI_API_KEY').trim();
    if (envKey.isEmpty) {
      envKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    }

    if (envKey.isNotEmpty) {
      _apiKey = envKey;
      debugPrint('DEBUG: Using single environment API key.');
      return;
    }

    // PRIORITY 3: Local Storage (Manual user entry)
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKey = prefs.getString('saved_api_key');
      if (storedKey != null && storedKey.isNotEmpty) {
        _apiKey = storedKey.trim();
        debugPrint('DEBUG: Using saved API key from storage.');
        return;
      }
    } catch (e) {
      debugPrint('WARNING: Internal Storage Check Failed: $e');
    }

    _apiKey = 'MISSING_KEY';
  }

  Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String filename) async {
    await _ensureInitialized();

    if (_apiKey == 'MISSING_KEY') {
      throw Exception('API Key is missing. Please check your GitHub Secrets or local .env file.');
    }

    // 1. Local Lookup
    try {
      final localData = await _loadLocalData(filename);
      debugPrint('DEBUG: [Local Search] Match found for "$filename"');
      return localData;
    } catch (e) {
      debugPrint('DEBUG: [Local Search] No match for "$filename". Calling AI...');
    }

    // 2. AI Identification with Fallback
    final List<String> modelNames = [
      'gemini-3-flash',      // 2026 Default
      'gemini-2.5-flash',    // Stable Fallback
      'gemini-2.0-flash',    // Legacy Fallback
      'gemini-flash-latest'  // Alias
    ];

    Object? lastError;

    for (final modelName in modelNames) {
      try {
        debugPrint('DEBUG: [Gemini AI] Trying model: $modelName');
        final currentModel = GenerativeModel(model: modelName, apiKey: _apiKey);

        final prompt = 'Identify this plant and return ONLY a JSON object with: '
            '"commonName", "scientificName", and "funFact". No markdown backticks.';

        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        ];

        final response = await currentModel.generateContent(content);
        final responseText = response.text;

        if (responseText == null || responseText.isEmpty) continue;

        // Clean and Parse JSON
        String cleanJson = responseText.trim();
        if (cleanJson.contains('{')) {
          cleanJson = cleanJson.substring(cleanJson.indexOf('{'), cleanJson.lastIndexOf('}') + 1);
        }

        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('DEBUG: [Gemini AI] Model $modelName failed: $e');
        lastError = e;
      }
    }

    throw Exception('Identification failed across all models. Last Error: $lastError');
  }

  Future<Map<String, dynamic>> _loadLocalData(String filename) async {
    // rootBundle doesn't support query parameters like ?cb=. 
    // Instead, use cache: false to force a fresh read from the bundle.
    const String assetPath = 'assets/plants/plants_data.json';
    final String response = await rootBundle.loadString(assetPath, cache: false);
    final data = json.decode(response);
    
    if (data[filename] != null) {
      return data[filename];
    }
    throw Exception('No local data found');
  }
}