import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  String _apiKey = '';

  GeminiService();

  Future<void> _ensureInitialized() async {
    if (_apiKey.isNotEmpty && _apiKey != 'MISSING_KEY') return;

    // 1. RECONSTRUCT: Pulls pieces from deploy.yml (Production)
    const String k1 = String.fromEnvironment('K1');
    const String k2 = String.fromEnvironment('K2');

    if (k1.isNotEmpty && k2.isNotEmpty) {
      _apiKey = (k1 + k2).trim();
      debugPrint('DEBUG: Using reconstructed stealth key.');
      return;
    }

    // 2. MANUAL OVERRIDE: Using your Double-Tap menu (Testing)
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString('saved_api_key');
    if (storedKey != null && storedKey.isNotEmpty) {
      _apiKey = storedKey.trim();
      debugPrint('DEBUG: Using manually saved key.');
      return;
    }

    _apiKey = 'MISSING_KEY';
  }

  Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String filename) async {
    await _ensureInitialized();
    if (_apiKey == 'MISSING_KEY') throw Exception('API Key Missing. Double-tap version to enter.');

    // Always try local JSON first to save API costs
    try {
      final localData = await _loadLocalData(filename);
      return localData;
    } catch (_) {}

    // Identification Logic (Gemini 3 Flash is the 2026 standard)
    final model = GenerativeModel(model: 'gemini-3-flash', apiKey: _apiKey);
    final prompt = 'Identify this plant. Return ONLY JSON: {"commonName": "...", "scientificName": "...", "funFact": "..."}';
    
    final content = [Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])];
    final response = await model.generateContent(content);
    
    String cleanJson = response.text!.trim();
    if (cleanJson.contains('{')) {
      cleanJson = cleanJson.substring(cleanJson.indexOf('{'), cleanJson.lastIndexOf('}') + 1);
    }
    return jsonDecode(cleanJson);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_api_key', key.trim());
    _apiKey = key.trim();
  }

  Future<Map<String, dynamic>> _loadLocalData(String filename) async {
    final String response = await rootBundle.loadString('assets/plants/plants_data.json', cache: false);
    final data = json.decode(response);
    return data[filename] ?? (throw Exception());
  }
}