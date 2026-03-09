import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'models/log_model.dart';
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier<List<LogModel>>([]);

  List<LogModel> get logs => logsNotifier.value;

  LogController() {
    // Dikosongkan karena inisialisasi awal sudah ditangani oleh log_view.dart
  }

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toString(),
    );

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
  Future<void> updateLog(LogModel oldLog, String newTitle, String newDesc, String category) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: newTitle,
      description: newDesc,
      category: category,
      date: DateTime.now().toString(), // Update waktu saat diedit
    );

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