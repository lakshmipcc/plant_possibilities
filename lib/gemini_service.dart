import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final String _apiKey;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    _apiKey = apiKey;
    final maskedKey = "${_apiKey.substring(0, 5)}...${_apiKey.substring(_apiKey.length - 4)}";
    print('DEBUG: [Gemini Service] Initialized with Key: $maskedKey');
    
    // Default model
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String filename) async {
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
      'gemini-1.5-flash', 
      'gemini-1.5-pro',
      'gemini-pro',
      'gemini-1.0-pro'
    ];
    Object? lastError;

    for (final modelName in modelNames) {
      try {
        print('DEBUG: [Gemini AI] Trying model: $modelName');
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
