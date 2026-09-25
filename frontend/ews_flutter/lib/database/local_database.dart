import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart' as sb;
import 'package:sembast_web/sembast_web.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class PendingItem {
  final int id;
  final String kind; // 'alert' | 'report' | 'photos'
  final Map<String, dynamic> payload;
  const PendingItem(this.id, this.kind, this.payload);
}

/// Offline queue: alerts/reports that could not reach the server are stored
/// here and pushed later by SyncService.
///
/// - Android / iOS: sqflite (survives app restarts).
/// - Web: IndexedDB via sembast_web (survives page refreshes, and handles
///   large photo payloads).
/// - If [init] was never called (e.g. unit tests): plain memory.
class LocalDatabase {
  sqflite.Database? _db; // mobile
  sb.Database? _webDb; // web
  final _webStore = sb.intMapStoreFactory.store('pending_sync');

  final List<PendingItem> _memory = [];
  int _memId = 0;

  Future<void> init() async {
    if (kIsWeb) {
      _webDb = await databaseFactoryWeb.openDatabase('ews_local');
      return;
    }
    final dir = await sqflite.getDatabasesPath();
    _db = await sqflite.openDatabase(
      p.join(dir, 'ews_local.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE pending_sync('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'kind TEXT NOT NULL, '
        'payload TEXT NOT NULL, '
        'created_at TEXT NOT NULL)',
      ),
    );
  }

  Future<void> enqueue(String kind, Map<String, dynamic> payload) async {
    final web = _webDb;
    if (web != null) {
      await _webStore.add(web, {
        'kind': kind,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = _db;
    if (db == null) {
      _memory.add(PendingItem(++_memId, kind, payload));
      return;
    }
    await db.insert('pending_sync', {
      'kind': kind,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<PendingItem>> pending() async {
    final web = _webDb;
    if (web != null) {
      final records = await _webStore.find(
        web,
        finder: sb.Finder(sortOrders: [sb.SortOrder(sb.Field.key)]),
      );
      return [
        for (final r in records)
          PendingItem(
            r.key,
            r.value['kind'] as String,
            jsonDecode(r.value['payload'] as String) as Map<String, dynamic>,
          ),
      ];
    }
    final db = _db;
    if (db == null) return List.of(_memory);
    final rows = await db.query('pending_sync', orderBy: 'id ASC');
    return [
      for (final r in rows)
        PendingItem(
          r['id'] as int,
          r['kind'] as String,
          jsonDecode(r['payload'] as String) as Map<String, dynamic>,
        ),
    ];
  }

  Future<void> remove(int id) async {
    final web = _webDb;
    if (web != null) {
      await _webStore.record(id).delete(web);
      return;
    }
    final db = _db;
    if (db == null) {
      _memory.removeWhere((e) => e.id == id);
      return;
    }
    await db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> pendingCount() async {
    final web = _webDb;
    if (web != null) return _webStore.count(web);
    final db = _db;
    if (db == null) return _memory.length;
    return sqflite.Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM pending_sync')) ??
        0;
  }
}
