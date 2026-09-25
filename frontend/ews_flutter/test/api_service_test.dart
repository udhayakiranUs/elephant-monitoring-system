import 'package:flutter_test/flutter_test.dart';

import 'package:ews_flutter/database/local_database.dart';
import 'package:ews_flutter/models/alert_model.dart';
import 'package:ews_flutter/models/elephant_model.dart';
import 'package:ews_flutter/models/report_model.dart';

void main() {
  group('LocalDatabase (memory fallback, init() not called)', () {
    test('starts with zero pending items', () async {
      final db = LocalDatabase();
      expect(await db.pendingCount(), 0);
      expect(await db.pending(), isEmpty);
    });

    test('enqueue adds an item and increments pendingCount', () async {
      final db = LocalDatabase();
      await db.enqueue('alert', {'id': 'a1'});
      expect(await db.pendingCount(), 1);
    });

    test('pending() returns items in the order they were added', () async {
      final db = LocalDatabase();
      await db.enqueue('report', {'id': 'r1'});
      await db.enqueue('report', {'id': 'r2'});
      await db.enqueue('alert', {'id': 'a1'});

      final items = await db.pending();
      expect(items.length, 3);
      expect(items[0].payload['id'], 'r1');
      expect(items[1].payload['id'], 'r2');
      expect(items[2].payload['id'], 'a1');
      expect(items[2].kind, 'alert');
    });

    test('remove() deletes the matching item and nothing else', () async {
      final db = LocalDatabase();
      await db.enqueue('report', {'id': 'r1'});
      await db.enqueue('report', {'id': 'r2'});

      final items = await db.pending();
      await db.remove(items[0].id);

      final remaining = await db.pending();
      expect(remaining.length, 1);
      expect(remaining[0].payload['id'], 'r2');
      expect(await db.pendingCount(), 1);
    });

    test('remove() on an unknown id is a no-op, not an error', () async {
      final db = LocalDatabase();
      await db.enqueue('alert', {'id': 'a1'});
      await db.remove(9999);
      expect(await db.pendingCount(), 1);
    });

    test('each enqueued item gets a distinct incrementing id', () async {
      final db = LocalDatabase();
      await db.enqueue('alert', {'id': 'a1'});
      await db.enqueue('alert', {'id': 'a2'});
      final items = await db.pending();
      expect(items[0].id, isNot(equals(items[1].id)));
    });
  });

  group('ElephantCounts', () {
    test('starts at zero for every type and totals zero', () {
      final counts = ElephantCounts();
      for (final t in ElephantType.values) {
        expect(counts[t], 0);
      }
      expect(counts.total, 0);
    });

    test('change() adjusts a single type and updates total', () {
      final counts = ElephantCounts().change(ElephantType.loneMale, 3);
      expect(counts[ElephantType.loneMale], 3);
      expect(counts.total, 3);
    });

    test('change() clamps at zero and does not go negative', () {
      final counts = ElephantCounts().change(ElephantType.femaleGroup, -5);
      expect(counts[ElephantType.femaleGroup], 0);
    });

    test('toJson/fromJson round-trips all counts correctly', () {
      final counts = ElephantCounts()
          .change(ElephantType.loneMale, 2)
          .change(ElephantType.femaleCalf, 1);
      final restored = ElephantCounts.fromJson(counts.toJson());
      expect(restored[ElephantType.loneMale], 2);
      expect(restored[ElephantType.femaleCalf], 1);
      expect(restored.total, 3);
    });
  });

  group('ReportModel', () {
    ReportModel buildReport({int loneMale = 0}) {
      return ReportModel(
        id: 'r1',
        range: 'North Range',
        beat: 'Beat 3',
        lat: 11.18,
        lon: 76.88,
        locationDescription: 'Near the river crossing',
        dateTime: DateTime(2026, 9, 20, 14, 30),
        officer: 'Ranger Kumar',
        designation: 'Range Officer',
        team: 'Alpha',
        counts: ElephantCounts().change(ElephantType.loneMale, loneMale),
        damage: false,
        damageType: '',
        damageDescription: '',
        chaseStart: '',
        chaseResult: '',
        remarks: 'All clear',
      );
    }

    test('severity is low for small totals', () {
      expect(buildReport(loneMale: 2).severity, ThreatLevel.low);
    });

    test('severity is medium above 4', () {
      expect(buildReport(loneMale: 5).severity, ThreatLevel.medium);
    });

    test('severity is high above 10', () {
      expect(buildReport(loneMale: 11).severity, ThreatLevel.high);
    });

    test('toJson/fromJson round-trips the core fields', () {
      final report = buildReport(loneMale: 4);
      final restored = ReportModel.fromJson(report.toJson());

      expect(restored.id, report.id);
      expect(restored.range, report.range);
      expect(restored.beat, report.beat);
      expect(restored.lat, report.lat);
      expect(restored.lon, report.lon);
      expect(restored.remarks, report.remarks);
      expect(restored.counts.total, report.counts.total);
      expect(
        restored.dateTime.isAtSameMomentAs(report.dateTime),
        isTrue,
      );
    });

    test('copyWith(pendingSync: true) marks the report as queued', () {
      final report = buildReport();
      final queued = report.copyWith(pendingSync: true);
      expect(queued.pendingSync, isTrue);
      expect(report.pendingSync, isFalse); // original is unchanged
    });
  });

  group('AlertModel', () {
    AlertModel buildAlert() {
      return AlertModel(
        id: 'a1',
        type: AlertType.warn,
        title: 'Elephant movement spotted',
        range: 'North Range',
        elephants: 3,
        threat: ThreatLevel.medium,
        officer: 'Ranger Kumar',
        gps: '11.18,76.88',
        damage: 'none',
        sentTo: 'HQ',
        message: 'Herd moving towards village boundary',
        time: DateTime(2026, 9, 20, 9, 15),
      );
    }

    test('toJson/fromJson round-trips correctly', () {
      final alert = buildAlert();
      final restored = AlertModel.fromJson(alert.toJson());

      expect(restored.id, alert.id);
      expect(restored.type, alert.type);
      expect(restored.title, alert.title);
      expect(restored.range, alert.range);
      expect(restored.elephants, alert.elephants);
      expect(restored.threat, alert.threat);
      expect(restored.resolved, isFalse);
      expect(
        restored.time.isAtSameMomentAs(alert.time),
        isTrue,
      );
    });

    test('copyWith(resolved: true) flips resolved without changing type', () {
      final alert = buildAlert();
      final resolved = alert.copyWith(resolved: true);
      expect(resolved.resolved, isTrue);
      expect(resolved.type, alert.type);
    });
  });
}
