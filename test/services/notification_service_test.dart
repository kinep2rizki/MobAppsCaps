import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/Services/NotificationService.dart';

void main() {
  group('NotificationApiService', () {
    test('getUnreadNotifications returns unread list from endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
            request.url.toString(), 'http://test.local/notifications/unread');

        return http.Response(
          jsonEncode([
            {
              'notif_id': 'notif-1',
              'title': 'Reminder Panen',
              'message': 'Panen kolam A1 dalam 2 hari',
              'is_read': false,
              'created_at': '2026-04-21T04:10:00Z',
            },
          ]),
          200,
        );
      });

      final result = await NotificationApiService.getUnreadNotifications(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'notif-1');
      expect(result.first.isRead, isFalse);
    });

    test('getUnreadCount parses count response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://test.local/notifications/unread/count',
        );

        return http.Response(jsonEncode({'count': 13}), 200);
      });

      final count = await NotificationApiService.getUnreadCount(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(count, 13);
    });

    test('getAllNotifications returns list from endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://test.local/notifications/');

        return http.Response(
          jsonEncode({
            'notifications': [
              {
                'id': 'notif-2',
                'title': 'Kalibrasi Sensor',
                'message': 'Kalibrasi sensor pH dijadwalkan hari ini',
                'status': 'unread',
                'created_at': '2026-04-21T06:00:00Z',
              }
            ]
          }),
          200,
        );
      });

      final result = await NotificationApiService.getAllNotifications(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'notif-2');
    });

    test('markAsRead calls patch endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.toString(),
          'http://test.local/notifications/notif-9/read',
        );

        return http.Response(jsonEncode({'success': true}), 200);
      });

      final result = await NotificationApiService.markAsRead(
        notificationId: 'notif-9',
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result['success'], true);
    });

    test('markAllAsRead calls patch endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
            request.url.toString(), 'http://test.local/notifications/read-all');

        return http.Response(jsonEncode({'updated': 6}), 200);
      });

      final result = await NotificationApiService.markAllAsRead(
        client: mockClient,
        overrideBaseUrl: 'http://test.local',
      );

      expect(result['updated'], 6);
    });
  });
}
