import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://haematological-jovan-bloomless.ngrok-free.dev';

  static Future<List<dynamic>> getSensorData({
    http.Client? client,
    String? overrideBaseUrl,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final response = await httpClient.get(
        Uri.parse('${overrideBaseUrl ?? baseUrl}/sensor-data/history'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load data');
      }

      final decodedBody = json.decode(response.body);
      if (decodedBody is List<dynamic>) {
        return decodedBody;
      }

      if (decodedBody is Map && decodedBody['data'] is List<dynamic>) {
        return decodedBody['data'] as List<dynamic>;
      }

      throw Exception('Unexpected response format');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}