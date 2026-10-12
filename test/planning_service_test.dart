import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mycpe_plus/core/utils/date_utils.dart' as date_utils;
import 'package:mycpe_plus/data/services/api_client.dart';
import 'package:mycpe_plus/data/services/planning_cache_service.dart';
import 'package:mycpe_plus/data/services/planning_service.dart';

typedef Du = date_utils.DateUtils;

/// In-memory cache, no platform channel.
class FakeCache extends PlanningCacheService {
  PlanningSnapshot stored;
  int saves = 0;

  FakeCache([this.stored = PlanningSnapshot.empty]);

  @override
  Future<PlanningSnapshot> load() async => stored;

  @override
  Future<void> save(PlanningSnapshot snapshot) async {
    stored = snapshot;
    saves++;
  }

  @override
  Future<void> clear() async => stored = PlanningSnapshot.empty;
}

Map<String, dynamic> course(int id, String start, String end, {String? room}) =>
    {
      'id': id,
      'date_debut': start,
      'date_fin': end,
      'matiere': 'Cours $id',
      'ressource': room,
    };

/// Day [n] relative to the Monday of the current week.
DateTime day(int n) => Du.addDays(Du.getMondayOfWeek(DateTime.now()), n);

String at(int n, String time) => '${Du.formatForApi(day(n))}T$time:00';

void main() {
  group('DateUtils', () {
    test('addDays stays at midnight across DST changes', () {
      // Europe: clocks go back on 2026-10-25 and forward on 2026-03-29.
      final monday = DateTime(2026, 10, 19);
      final next = Du.addDays(monday, 7);
      expect(next, DateTime(2026, 10, 26));
      expect(next.weekday, DateTime.monday);
      expect(Du.addDays(DateTime(2026, 3, 23), 7).weekday, DateTime.monday);
    });

    test('getMondayOfWeek', () {
      expect(
        Du.getMondayOfWeek(DateTime(2026, 10, 25, 23)),
        DateTime(2026, 10, 19),
      );
      expect(
        Du.getMondayOfWeek(DateTime(2026, 10, 19)),
        DateTime(2026, 10, 19),
      );
    });

    test('daysInRange is inclusive', () {
      final days = Du.daysInRange(
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 25),
      );
      expect(days.length, 7);
      expect(days.last, DateTime(2026, 10, 25));
    });
  });

  group('PlanningService', () {
    late List<Uri> requests;
    late List<Map<String, dynamic>> apiEvents;

    PlanningService buildService(FakeCache cache, {Completer<void>? gate}) {
      final client = MockClient((request) async {
        requests.add(request.url);
        if (gate != null) await gate.future;
        return http.Response(jsonEncode(apiEvents), 200);
      });
      return PlanningService(
        apiClient: ApiClient(client: client),
        cacheService: cache,
      );
    }

    setUp(() {
      requests = [];
      apiEvents = [];
    });

    test('a day never fetched is not loaded, a fetched empty day is', () async {
      final service = buildService(FakeCache());
      await service.loadCache();
      final monday = day(0);
      expect(service.isDayLoaded(monday), isFalse);

      await service.fetchRange(monday, Du.addDays(monday, 6));
      expect(service.isDayLoaded(monday), isTrue);
      expect(service.eventsForDay(monday), isEmpty);
    });

    test('Friday and last-day events are kept (no midnight cut-off)', () async {
      apiEvents = [
        course(1, at(4, '14:00'), at(4, '16:00')),
        course(2, at(26, '10:00'), at(26, '12:00')),
      ];
      final service = buildService(FakeCache());
      await service.fetchRange(day(-3), day(26));
      expect(service.eventsForDay(day(4)), hasLength(1));
      expect(service.eventsForDay(day(26)), hasLength(1));
    });

    test('refetch removes cancelled courses and keeps other ranges', () async {
      apiEvents = [
        course(1, at(1, '08:00'), at(1, '10:00')),
        course(2, at(15, '08:00'), at(15, '10:00')),
      ];
      final service = buildService(FakeCache());
      await service.fetchRange(day(0), day(20));

      // Course 1 cancelled, refetch only that week.
      apiEvents = [];
      final result = await service.fetchRange(day(0), day(6));
      expect(service.eventsForDay(day(1)), isEmpty);
      expect(service.eventsForDay(day(15)), hasLength(1));
      expect(result.when(success: (c) => c, failure: (_, _) => null), isTrue);
    });

    test('identical refetch reports no change', () async {
      apiEvents = [course(1, at(1, '08:00'), at(1, '10:00'))];
      final service = buildService(FakeCache());
      final week = (day(0), day(6));
      await service.fetchRange(week.$1, week.$2);
      final again = await service.fetchRange(week.$1, week.$2);
      expect(again.when(success: (c) => c, failure: (_, _) => null), isFalse);
    });

    test(
      'requests ask one extra day and concurrent calls are shared',
      () async {
        final gate = Completer<void>();
        final service = buildService(FakeCache(), gate: gate);
        final a = service.fetchRange(day(0), day(6));
        final b = service.fetchRange(day(0), day(6));
        await Future<void>.delayed(Duration.zero);
        gate.complete();
        await Future.wait([a, b]);
        expect(requests, hasLength(1));
        expect(
          requests.single.queryParameters['date_debut'],
          Du.formatForApi(day(0)),
        );
        expect(
          requests.single.queryParameters['date_fin'],
          Du.formatForApi(day(7)),
        );
      },
    );

    test('responses arriving after clearCache are dropped', () async {
      apiEvents = [course(1, at(1, '08:00'), at(1, '10:00'))];
      final gate = Completer<void>();
      final service = buildService(FakeCache(), gate: gate);
      final pending = service.fetchRange(day(0), day(6));
      await Future<void>.delayed(Duration.zero);
      await service.clearCache();
      gate.complete();
      await pending;
      expect(service.isDayLoaded(day(1)), isFalse);
      expect(service.allEvents, isEmpty);
    });

    test('cache round-trip restores events and sync info', () async {
      final cache = FakeCache();
      apiEvents = [course(1, at(1, '08:00'), at(1, '10:00'))];
      final first = buildService(cache);
      await first.fetchRange(day(0), day(6));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(cache.saves, 1);

      final second = buildService(cache);
      await second.loadCache();
      expect(second.eventsForDay(day(1)), hasLength(1));
      expect(second.isDayLoaded(day(5)), isTrue);
      expect(second.isDayLoaded(day(8)), isFalse);
    });
  });
}
