import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mycpe_plus/data/services/api_client.dart';
import 'package:mycpe_plus/data/services/grades_service.dart';
import 'package:mycpe_plus/data/services/json_cache_service.dart';
import 'package:mycpe_plus/providers/grades_provider.dart';

/// In-memory cache, no platform channel.
class FakeJsonCache extends JsonCacheService {
  final Map<String, CachedJson> store = {};

  @override
  Future<CachedJson?> read(String key) async => store[key];

  @override
  Future<void> write(String key, dynamic json) async =>
      store[key] = CachedJson(jsonDecode(jsonEncode(json)), DateTime.now());

  @override
  Future<void> delete(String key) async => store.remove(key);
}

List<Map<String, dynamic>> coursesJson(String name) => [
  {'id': 1, 'cours_libelle': name, 'epreuves': <dynamic>[]},
];

void main() {
  late FakeJsonCache cache;
  late http.Response Function() respond;
  Completer<void>? gate;

  GradesProvider buildProvider() {
    final client = MockClient((_) async {
      if (gate != null) await gate!.future;
      return respond();
    });
    return GradesProvider(
      gradesService: GradesService(
        apiClient: ApiClient(client: client),
        cache: cache,
      ),
    );
  }

  setUp(() {
    cache = FakeJsonCache();
    gate = null;
    respond = () => http.Response(jsonEncode(coursesJson('Maths')), 200);
  });

  test('fetched grades are cached and shown first next time', () async {
    await buildProvider().loadGrades();

    respond = () => http.Response('', 500);
    final provider = buildProvider();
    await provider.loadGrades();

    expect(provider.state, GradesState.loaded);
    expect(provider.courses.single.displayName, 'Maths');
    expect(provider.isOffline, isTrue);
    expect(provider.lastUpdated, isNotNull);
  });

  test('no cache and no network is an error', () async {
    respond = () => http.Response('', 500);
    final provider = buildProvider();
    await provider.loadGrades();
    expect(provider.state, GradesState.error);
  });

  test('refresh keeps grades on screen while loading', () async {
    final provider = buildProvider();
    await provider.loadGrades();

    gate = Completer<void>();
    respond = () => http.Response(jsonEncode(coursesJson('Physique')), 200);
    final refreshing = provider.refresh();
    expect(provider.state, GradesState.loaded);
    expect(provider.isSyncing, isTrue);
    expect(provider.courses.single.displayName, 'Maths');

    gate!.complete();
    await refreshing;
    expect(provider.courses.single.displayName, 'Physique');
  });

  test('reset drops the cache and a late response', () async {
    final provider = buildProvider();
    await provider.loadGrades();

    gate = Completer<void>();
    final refreshing = provider.refresh();
    provider.reset();
    gate!.complete();
    await refreshing;

    expect(provider.state, GradesState.initial);
    expect(provider.courses, isEmpty);
    expect(cache.store, isEmpty);
  });
}
