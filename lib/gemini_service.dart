import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found or empty in assets/.env file');
    }

    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String filename) async {
    // 1. Attempt local data lookup first (Manual Override)
    try {
      final localData = await _loadLocalData(filename);
      print('Local data found for "$filename". Skipping API call.');
      return localData;
    } catch (e) {
      print('No local data for "$filename" (or error loading): $e. Proceeding to Gemini API.');
    }

    // 2. Call Gemini API if local data isn't found
    try {
      final prompt = 'Identify this plant. Return a JSON object with strictly these keys: '
          '"commonName", "scientificName", and "funFact". '
          'Provide accurate information based on the visual features of the plant.';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Gemini returned an empty response.');
      }

      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (apiError) {
      print('Gemini API Error: $apiError');
      throw Exception('Failed to identify plant via local database or Gemini API.\n\nAPI Error: $apiError');
    }
  }

  Future<Map<String, dynamic>> _loadLocalData(String filename) async {
    try {
      final String response = await rootBundle.loadString('assets/plants/plants_data.json');
      final data = await json.decode(response);
      if (data[filename] != null) {
        return data[filename];
      }
      throw Exception('No local data found for "$filename"');
    } catch (e) {
      rethrow;
    }
  }
}
