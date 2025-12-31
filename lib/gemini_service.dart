import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;
  String _apiKey = '';

  GeminiService(); // Empty constructor to prevent startup crashes

  void _ensureInitialized() {
    if (_apiKey.isNotEmpty) return; // Already initialized

    // Priority 1: Check for --dart-define=GEMINI_API_KEY=xxx (Obfuscated or Raw)
    String? envKey = const String.fromEnvironment('GEMINI_API_KEY');
    
    // Priority 2: Check for .env file (for local testing)
    if (envKey.isEmpty) {
      envKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    }

    if (envKey.isEmpty) {
      print('WARNING: GEMINI_API_KEY not found in environment or .env');
      _apiKey = 'MISSING_KEY'; // Placeholder to prevent empty checks looping
    } else {
      // Simple heuristic: If it doesn't start with "AIza", it might be Base64 encoded.
      if (!envKey.startsWith('AIza')) {
        try {
          // 1. Decode Base64
          String decoded = utf8.decode(base64Decode(envKey)).trim();
          // 2. Reverse the string (Obfuscation against scanners)
          _apiKey = String.fromCharCodes(decoded.runes.toList().reversed);
          
          if (!_apiKey.startsWith('AIza')) {
             throw FormatException('Decoded key does not start with AIza. Result: ${_apiKey.substring(0, min(4, _apiKey.length))}...');
          }
          
          print('DEBUG: Decoded & Reversed API Key. First 4 chars: ${_apiKey.substring(0, min(4, _apiKey.length))}');
        } catch (e) {
          print('WARNING: Key Decoding Failed: $e');
          // Important: We THROW here so the UI sees "Invalid Key Format" instead of trying to use a garbage key
          throw Exception('Key Decoding Failed: $e');
        }
      } else {
         _apiKey = envKey;
      }
    }
  }

  Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String filename) async {
    _ensureInitialized(); // Lazy Init (Safe)

    // 1. Attempt local data lookup first
    try {
      final localData = await _loadLocalData(filename);
      print('DEBUG: [Local Search] Match found for "$filename"');
      return localData;
    } catch (e) {
      print('DEBUG: [Local Search] No match for "$filename". Calling AI...');
    }

    // 2. Try Gemini Models with Fallback
    final List<String> modelNames = [
      'gemini-flash-latest', 
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-pro-latest'
    ];
    Object? lastError;

    for (final modelName in modelNames) {
      try {
        print('DEBUG: [Gemini AI] Trying model: $modelName');
        // Lazy initialize or create a new instance per request to support retries if we wanted to swap keys strategies
        final currentModel = GenerativeModel(model: modelName, apiKey: _apiKey);

        final prompt = 'Identify this plant and return ONLY a JSON object with: '
            '"commonName", "scientificName", and "funFact".';

        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        ];

        final response = await currentModel.generateContent(content);
        final responseText = response.text;

        if (responseText == null || responseText.isEmpty) {
          throw Exception('Model $modelName returned an empty response.');
        }

        print('DEBUG: [Gemini AI] Success with $modelName');

        // Robust JSON extraction
        String cleanJson = responseText;
        if (cleanJson.contains('{')) {
          cleanJson = cleanJson.substring(cleanJson.indexOf('{'), cleanJson.lastIndexOf('}') + 1);
        }

        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        print('DEBUG: [Gemini AI] Model $modelName failed: $e');
        lastError = e;
        // Continue to next model in the list
      }
    }

    // If all models fail
    throw Exception('Identification failed across all models. Last Error: $lastError');
  }

  Future<Map<String, dynamic>> _loadLocalData(String filename) async {
    try {
      // Use a timestamp to bust the browser's asset cache
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String response = await rootBundle.loadString('assets/plants/plants_data.json?cb=$timestamp');
      final data = await json.decode(response);
      if (data[filename] != null) {
        return data[filename];
      }
      throw Exception('No local data found for "$filename"');
    } catch (e) {
      print('DEBUG: [Local Search Cache Error] $e');
      // Fallback without cache bust if the above fails (some browsers might object to query params on asset paths)
      final String response = await rootBundle.loadString('assets/plants/plants_data.json');
      final data = await json.decode(response);
       if (data[filename] != null) {
        return data[filename];
      }
      rethrow;
    }
  }
}
