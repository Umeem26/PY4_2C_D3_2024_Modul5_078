import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import 'models/log_model.dart';
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier<List<LogModel>>([]);

  final _myBox = Hive.box<LogModel>('offline_logs');

  List<LogModel> get logs => logsNotifier.value;

  Future<void> loadLogs() async {
    // 1. Tampilkan data dari Hive secara instan (Offline-First)
    logsNotifier.value = _myBox.values.toList();

    // 2. Coba sinkronisasi latar belakang dari Cloud
    try {
      // Ambil data terbaru dari MongoDB (Global Truth)
      final cloudData = await MongoService().getLogs();

      // Bersihkan Hive lokal dan timpa dengan data valid dari Cloud
      await _myBox.clear();

      // Simpan kembali ke Hive agar cache terbarui
      for (var log in cloudData) {
        await _myBox.put(log.id, log);
      }

      // Perbarui UI
      logsNotifier.value = cloudData;

    } catch (e) {
      // Jika internet mati, biarkan pengguna memakai data Hive tanpa memblokir layar
    }
  }

  Future<void> syncPendingData() async {
    final offlineData = _myBox.values.toList();
    if (offlineData.isEmpty) return; // Jika kosong, tidak perlu sync

    bool hasNewDataSynced = false;

    // Coba kirim semua data yang ada di Hive ke Cloud
    for (var log in offlineData) {
      try {
        // Jika data sudah ada di Cloud, MongoDB otomatis akan menolak (Duplicate Key Error).
        // Jika data baru (dibuat saat offline), maka akan berhasil masuk.
        await MongoService().insertLog(log);
        hasNewDataSynced = true;
      } catch (e) {
        // Abaikan error (artinya data tersebut memang sudah tersinkron sebelumnya)
      }
    }

    // Jika ada data baru yang berhasil naik ke awan, tarik ulang data ter-update
    if (hasNewDataSynced) {
      await loadLogs();
    }
  }

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId().oid, // Gunakan .oid karena id sekarang bertipe String
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: 'user_001', // Dummy role, akan diubah di Task 3
      teamId: 'team_alpha', // Dummy team, akan diubah di Task 3
    );

    await _myBox.put(newLog.id, newLog);

    await loadLogs();

    try {
      await MongoService().insertLog(newLog);

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Tambah data ke Cloud berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Add - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // DIUBAH: Sekarang menggunakan LogModel target, bukan index
  Future<void> updateLog(LogModel oldLog, String title, String desc, String category) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
    );

    await _myBox.put(oldLog.id, updatedLog);
    await loadLogs();

    try {
      await MongoService().updateLog(updatedLog);

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      // Cari posisi log yang sedang diedit berdasarkan ID-nya
      final index = currentLogs.indexWhere((log) => log.id == oldLog.id);

      if (index != -1) {
        currentLogs[index] = updatedLog;
        logsNotifier.value = currentLogs;
      }

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  // DIUBAH: Sekarang menggunakan LogModel target, bukan index
  Future<void> removeLog(LogModel targetLog) async {
    try {
      if (targetLog.id == null) {
        throw Exception("ID Log tidak ditemukan, tidak bisa menghapus di Cloud.");
      }

      await MongoService().deleteLog(targetLog.id!);

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      // Hapus data dari daftar lokal berdasarkan ID-nya
      currentLogs.removeWhere((log) => log.id == targetLog.id);
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  Future<void> loadFromDisk() async {
    try {
      final cloudData = await MongoService().getLogs();
      logsNotifier.value = cloudData;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal memuat data dari Cloud - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }
}