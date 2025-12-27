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
    String? apiError;
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
    } catch (e) {
      apiError = e.toString();
      print('Gemini API Error: $apiError');
    }

    // Attempt fallback to local data
    try {
      return await _loadLocalData(filename);
    } catch (fallbackError) {
      // If even fallback fails, throw the original API error combined with fallback failure
      throw Exception('API Error: $apiError\n\nLocal Fallback Error: $fallbackError');
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
