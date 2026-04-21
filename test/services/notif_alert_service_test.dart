import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/Services/NotifAlertService.dart';

void main() {
  group('NotifAlertService', () {
    test('getActiveAlerts returns list from /alerts/active', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://test.local/alerts/active');
        return http.Response(
          jsonEncode([
            {
              'id': 'alert-1',
              'title': 'Suhu Air Tinggi',
              'state': 'active',
            },
          ]),
          200,
        );
      });

      final result = await NotifAlertService.getActiveAlerts(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result, hasLength(1));
      expect(result.first['id'], 'alert-1');
      expect(result.first['state'], 'active');
    });

    test('getAlertHistory sends period query and parses data wrapper',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://test.local/alerts/history?period=24h',
        );

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'alert-2',
                'title': 'Stok Pakan Menipis',
                'state': 'resolved',
              },
            ],
          }),
          200,
        );
      });

      final result = await NotifAlertService.getAlertHistory(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
        period: '24h',
      );

      expect(result, hasLength(1));
      expect(result.first['id'], 'alert-2');
      expect(result.first['state'], 'resolved');
    });

    test('resolveAlert calls patch endpoint and handles empty body', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.toString(),
          'http://test.local/alerts/alert-9/resolve',
        );
        return http.Response('', 204);
      });

      final result = await NotifAlertService.resolveAlert(
        alertId: 'alert-9',
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result['success'], true);
      expect(result['state'], 'resolved');
    });

    test('resolveAllAlerts calls patch endpoint and parses json body',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), 'http://test.local/alerts/resolve-all');
        return http.Response(jsonEncode({'updated': 4, 'success': true}), 200);
      });

      final result = await NotifAlertService.resolveAllAlerts(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result['success'], true);
      expect(result['updated'], 4);
    });

    test('getActiveAlerts throws when status code is not 200', () async {
      final mockClient = MockClient((_) async => http.Response('error', 500));

      expect(
        () => NotifAlertService.getActiveAlerts(
          client: mockClient,
          overrideBaseUrl: 'http://test.local',
        ),
        throwsException,
      );
    });

    test('getNotificationSettings returns settings from data map', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://test.local/alerts/settings');

        return http.Response(
          jsonEncode({
            'data': {
              'parameter_air_abnormal': true,
              'stok_pakan_menipis': false,
            },
          }),
          200,
        );
      });

      final result = await NotifAlertService.getNotificationSettings(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result['parameter_air_abnormal'], true);
      expect(result['stok_pakan_menipis'], false);
    });

    test('getNotificationSettings falls back to next endpoint', () async {
      final calledPaths = <String>[];

      final mockClient = MockClient((request) async {
        calledPaths.add(request.url.path);

        if (request.url.path == '/alerts/settings') {
          return http.Response('not found', 404);
        }

        if (request.url.path == '/alerts/preferences') {
          return http.Response(
            jsonEncode({
              'settings': {
                'laporan_harian': true,
              },
            }),
            200,
          );
        }

        return http.Response('not found', 404);
      });

      final result = await NotifAlertService.getNotificationSettings(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(calledPaths, ['/alerts/settings', '/alerts/preferences']);
      expect(result['laporan_harian'], true);
    });

    test('updateNotificationSettings sends patch payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), 'http://test.local/alerts/settings');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['parameter_air_abnormal'], true);
        expect(body['kalibrasi_sensor'], false);

        return http.Response(jsonEncode({'success': true}), 200);
      });

      final result = await NotifAlertService.updateNotificationSettings(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
        settings: {
          'parameter_air_abnormal': true,
          'kalibrasi_sensor': false,
        },
      );

      expect(result['success'], true);
    });

    test('updateNotificationSettings falls back to PUT when PATCH unsupported',
        () async {
      final methods = <String>[];

      final mockClient = MockClient((request) async {
        methods.add('${request.method}:${request.url.path}');

        if (request.url.path == '/alerts/settings' &&
            request.method == 'PATCH') {
          return http.Response('method not allowed', 405);
        }

        if (request.url.path == '/alerts/settings' && request.method == 'PUT') {
          return http.Response(jsonEncode({'saved': true}), 200);
        }

        return http.Response('not found', 404);
      });

      final result = await NotifAlertService.updateNotificationSettings(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
        settings: {
          'jadwal_panen': true,
        },
      );

      expect(methods, ['PATCH:/alerts/settings', 'PUT:/alerts/settings']);
      expect(result['saved'], true);
    });
  });
}
