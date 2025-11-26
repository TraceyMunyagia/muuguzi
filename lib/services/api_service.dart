import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
 
  static final String baseUrl = () {
    const overrideUrl = String.fromEnvironment('BACKEND_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;

    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    } catch (_) {
    }
    return 'http://localhost:5000';
  }();

  static const Duration _timeout = Duration(seconds: 75);

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final dynamic body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          throw HttpException('Error ${response.statusCode}: ${body['error']}');
        }
      } catch (_) {
      }
      throw HttpException(
        'HTTP ${response.statusCode} from server at ${response.request?.url}',
      );
    }
  }


  Future<Map<String, dynamic>> predictSurvival(
      Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/api/predict_survival');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    return _decodeResponse(response);
  }


  Future<Map<String, dynamic>> matchCaregivers(
      Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/api/match_caregivers');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> addCaregiver(
      Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/api/admin/caregivers');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    return _decodeResponse(response);
  }

  Future<List<dynamic>> getCaregivers() async {
    final uri = Uri.parse('$baseUrl/api/caregivers');
    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded;
      } else {
        throw const HttpException('Unexpected caregivers response format');
      }
    } else {
      throw HttpException(
        'HTTP ${response.statusCode} when fetching caregivers',
      );
    }
  }
}
