import 'package:flutter_test/flutter_test.dart';
// Pastikan path import ini mengarah ke file model Anda yang benar
import 'package:logbook_modul5/features/logbook/models/log_model.dart'; 

void main() {
  group('Privacy Leak Test (Task 5 Enrichment)', () {
    // 1. Persiapan Data Simulasi (Mock Data)
    final List<LogModel> cloudData = [
      LogModel(
        id: '1',
        title: 'Rapat Rahasia Ketua',
        description: 'Bahas evaluasi anggota',
        category: 'Pekerjaan',
        date: '2026-03-10',
        authorId: 'user_ketua', // Milik Ketua
        teamId: 'team_alpha',
        isPublic: false, // PRIVATE (Hanya Ketua yang boleh lihat)
      ),
      LogModel(
        id: '2',
        title: 'Pengumuman Libur',
        description: 'Besok libur nasional',
        category: 'Lainnya',
        date: '2026-03-10',
        authorId: 'user_ketua',
        teamId: 'team_alpha',
        isPublic: true, // PUBLIK (Semua anggota tim boleh lihat)
      ),
      LogModel(
        id: '3',
        title: 'Keluhan Pribadi Anggota',
        description: 'Tugas terlalu banyak',
        category: 'Pribadi',
        date: '2026-03-10',
        authorId: 'user_anggota_1', // Milik Anggota 1
        teamId: 'team_alpha',
        isPublic: false, // PRIVATE (Hanya Anggota 1 yang boleh lihat)
      ),
    ];

    test('User Anggota HANYA bisa melihat catatannya sendiri ATAU catatan Publik', () {
      // 2. Skenario: Yang sedang login adalah 'user_anggota_1'
      const String currentUser = 'user_anggota_1';

      // 3. Eksekusi: Terapkan filter visibilitas (Sama persis seperti logika di log_view.dart)
      final List<LogModel> displayLogs = cloudData.where((log) {
        return log.authorId == currentUser || log.isPublic == true;
      }).toList();

      // 4. Verifikasi (Expectation)
      // A. Total catatan yang terlihat harusnya HANYA 2 (Pengumuman Libur & Keluhan Pribadi)
      expect(displayLogs.length, 2, reason: "Jumlah catatan yang tertampil tidak sesuai aturan visibilitas.");

      // B. PRIVACY LEAK CHECK: Catatan 'Rapat Rahasia Ketua' (ID: 1) TIDAK BOLEH ADA!
      final bool isLeak = displayLogs.any((log) => log.id == '1');
      expect(isLeak, false, reason: "BAHAYA FATAL: Catatan private milik orang lain bocor dan bisa dibaca!");

      // C. Catatan Publik (ID: 2) HARUS ADA
      final bool hasPublicLog = displayLogs.any((log) => log.id == '2');
      expect(hasPublicLog, true, reason: "Catatan publik gagal ditampilkan.");

      // D. Catatan Sendiri (ID: 3) HARUS ADA
      final bool hasOwnLog = displayLogs.any((log) => log.id == '3');
      expect(hasOwnLog, true, reason: "Catatan private milik sendiri gagal ditampilkan.");
    });
  });
}