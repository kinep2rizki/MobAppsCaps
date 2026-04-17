import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/Services/api_service.dart';

void main() {
  group('ApiService.getSensorData', () {
    final sampleSensorRecord = <String, dynamic>{
      'id': 1414,
      'device_id': 'sensor-01',
      'tds': 372.02,
      'ph': 8.17,
      'do_level': 5.36,
      'temperature': 28.8,
      'turbidity': 4.14,
      'created_at': '2026-04-15T20:34:53.719493',
    };

    test('returns sensor list when response body is a list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://test.local/sensor-data');
        return http.Response(
          jsonEncode([sampleSensorRecord]),
          200,
        );
      });

      final result = await ApiService.getSensorData(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result, isA<List<dynamic>>());
      expect(result, hasLength(1));
      expect((result.first as Map)['temperature'], sampleSensorRecord['temperature']);
    });

    test('returns sensor list when response body is wrapped in data key',
        () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'data': [sampleSensorRecord],
          }),
          200,
        );
      });

      final result = await ApiService.getSensorData(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result, hasLength(1));
      expect((result.first as Map)['temperature'], sampleSensorRecord['temperature']);
    });

    test('throws exception when status code is not 200', () async {
      final mockClient = MockClient((_) async => http.Response('error', 500));

      expect(
        () => ApiService.getSensorData(
          client: mockClient,
          overrideBaseUrl: 'http://test.local',
        ),
        throwsException,
      );
    });
  });
}
