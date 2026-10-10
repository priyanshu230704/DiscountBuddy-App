import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:discount_buddy/services/api_service.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  ApiService build(MockClient client) => ApiService.forTesting(client);

  test('401 -> refresh succeeds -> request retried once with new token', () async {
    var calls = 0;
    final seenAuth = <String?>[];
    final api = build(MockClient((req) async {
      calls++;
      seenAuth.add(req.headers['Authorization']);
      if (req.headers['Authorization'] == 'Bearer old') {
        return http.Response('{"detail":"expired"}', 401);
      }
      return http.Response('{"ok":true}', 200);
    }));
    api.setAuthToken('old');
    api.onUnauthorized = () async {
      api.setAuthToken('new');
      return true;
    };

    final res = await api.get('/me');
    expect(res['ok'], true);
    expect(calls, 2);
    expect(seenAuth, ['Bearer old', 'Bearer new']);
  });

  test('concurrent 401s trigger a single refresh', () async {
    var refreshes = 0;
    final api = build(MockClient((req) async {
      return req.headers['Authorization'] == 'Bearer old'
          ? http.Response('{}', 401)
          : http.Response('{"ok":true}', 200);
    }));
    api.setAuthToken('old');
    api.onUnauthorized = () async {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      api.setAuthToken('new');
      return true;
    };
    final results = await Future.wait([api.get('/a'), api.get('/b'), api.get('/c')]);
    expect(results.every((r) => r['ok'] == true), isTrue);
    expect(refreshes, 1);
  });

  test('refresh failure surfaces the original 401', () async {
    final api = build(MockClient((_) async => http.Response('{"detail":"nope"}', 401)));
    api.setAuthToken('old');
    api.onUnauthorized = () async => false;
    await expectLater(
      api.get('/me'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('regression: a 401 raised while a refresh is in progress cannot hang forever', () async {
    // Old behaviour: refresh handler made an authenticated call (logout) that
    // 401'd, queued behind the very refresh it was part of, and deadlocked.
    final api = build(MockClient((_) async => http.Response('{}', 401)));
    api.refreshWaitTimeout = const Duration(milliseconds: 200);
    api.setAuthToken('old');
    api.onUnauthorized = () async {
      try {
        await api.post('/logout', body: {'refresh': 'r'}); // authenticated -> 401
      } catch (_) {}
      return false;
    };
    await expectLater(
      api.get('/me').timeout(const Duration(seconds: 5)),
      throwsA(isA<ApiException>()),
    );
  });

  test('HTML error page is never shown to the user', () async {
    final api = build(MockClient(
      (_) async => http.Response('<html><body>502 Bad Gateway</body></html>', 502),
    ));
    try {
      await api.get('/x');
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.statusCode, 502);
      expect(e.message.toLowerCase().contains('<html'), isFalse);
    }
  });

  test('HTML body on a 2xx is an error, not a success', () async {
    final api = build(MockClient(
      (_) async => http.Response('<!DOCTYPE html><html></html>', 200),
    ));
    await expectLater(api.get('/x'), throwsA(isA<ApiException>()));
  });

  test('timeouts map to a friendly message without internals', () async {
    final api = build(MockClient((_) async => throw TimeoutException('boom')));
    try {
      await api.get('/x');
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.message, contains('timed out'));
      expect(e.message.contains('TimeoutException'), isFalse);
    }
  });
}
