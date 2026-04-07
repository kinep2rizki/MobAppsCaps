import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/Services/api_service.dart';

void main() {
  group('ApiService.getSensorData', () {
    test('returns sensor list when response body is a list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'http://test.local/sensor');
        return http.Response(
          jsonEncode([
            {
              'temperature': 30,
              'ph': 7.2,
            }
          ]),
          200,
        );
      });

      final result = await ApiService.getSensorData(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result, isA<List<dynamic>>());
      expect(result, hasLength(1));
      expect((result.first as Map)['temperature'], 30);
    });

    test('returns sensor list when response body is wrapped in data key',
        () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'temperature': 28.5,
              }
            ],
          }),
          200,
        );
      });

      final result = await ApiService.getSensorData(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result, hasLength(1));
      expect((result.first as Map)['temperature'], 28.5);
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
