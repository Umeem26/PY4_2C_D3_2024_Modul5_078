import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'models/log_model.dart';
import '../../services/mongo_service.dart';

class LogController {
  // --- PENYIMPANAN USER AKTIF ---
  static String currentUser = 'user_001'; // Default: Admin
  static String currentRole = 'Ketua';
  // ------------------------------

  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier<List<LogModel>>([]);
  final _myBox = Hive.box<LogModel>('offline_logs');

  List<LogModel> get logs => logsNotifier.value;

  Future<void> loadLogs() async {
    logsNotifier.value = List.from(_myBox.values);
    try {
      final cloudData = await MongoService().getLogs();
      await _myBox.clear();
      for (var log in cloudData) {
        await _myBox.put(log.id, log);
      }
      logsNotifier.value = List.from(cloudData);
    } catch (e) {
    }
  }

  Future<void> syncPendingData() async {
    final offlineData = _myBox.values.toList();
    if (offlineData.isEmpty) return;
    bool hasNewDataSynced = false;
    for (var log in offlineData) {
      try {
        await MongoService().insertLog(log);
        hasNewDataSynced = true;
      } catch (e) {
      }
    }
    if (hasNewDataSynced) {
      await loadLogs();
    }
  }

  Future<void> addLog(String title, String desc, String category, bool isPublic) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: currentUser, // <-- Menyimpan berdasarkan user yang sedang aktif
      teamId: 'team_alpha',
      isPublic: isPublic,
    );
    await _myBox.put(newLog.id, newLog);
    logsNotifier.value = List.from(_myBox.values);
    try {
      await MongoService().insertLog(newLog);
      await loadLogs();
    } catch (e) {
    }
  }

  Future<void> updateLog(LogModel oldLog, String title, String desc, String category, bool isPublic) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      isPublic: isPublic,
    );
    await _myBox.put(oldLog.id, updatedLog);
    logsNotifier.value = List.from(_myBox.values);
    try {
      await MongoService().updateLog(updatedLog);
      await loadLogs();
    } catch (e) {
    }
  }

  Future<void> removeLog(LogModel log) async {
    await _myBox.delete(log.id);
    logsNotifier.value = List.from(_myBox.values);
    try {
      await MongoService().deleteLog(log.id!);
      await loadLogs();
    } catch (e) {
    }
  }
}