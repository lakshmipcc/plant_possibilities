import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GeminiService {
  GeminiService();

  Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String filename) async {
    // 1. Local cache (keep as is)
    try {
      final localData = await _loadLocalData(filename);
      return localData;
    } catch (_) {
      debugPrint('DEBUG: No local match for $filename. Consulting Cloud Function...');
    }

    // 2. Secure Server-Side Identification (VIA SDK)
    // The SDK automatically handles CORS and Authentication tokens.
    try {
      final functions = FirebaseFunctions.instance; // Defaults to us-central1
      final callable = functions.httpsCallable('identifyPlant');

      final result = await callable.call({
        'image': base64Encode(imageBytes),
      });

      // The cloud function returns the JSON object directly
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('ERROR calling Cloud Function: $e');
      throw Exception('Failed to identify plant via secure server. $e');
    }
  }

  Future<Map<String, dynamic>> _loadLocalData(String filename) async {
    final String response = await rootBundle.loadString('assets/plants/plants_data.json', cache: false);
    final data = json.decode(response);
    return data[filename] ?? (throw Exception());
  }
}