import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'log_editor_page.dart';
import '../auth/login_view.dart';

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    Future.microtask(() => _initDatabase());

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        _showElegantToast("Koneksi terputus. Beralih ke mode offline.", icon: Icons.wifi_off, bgColor: Colors.orange.shade800);
      } else if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.mobile)) {
        _controller.syncPendingData().then((_) {
          _showElegantToast("Sistem online. Sinkronisasi data berhasil!", icon: Icons.cloud_done, bgColor: Colors.green.shade600);
        });
      }
    });
  }

  Future<void> _initDatabase() async {
    if (mounted && _controller.logs.isEmpty) setState(() => _isLoading = true);
    try {
      await _controller.loadLogs();
    } catch (e) {
      if (mounted) _showElegantToast("Gagal terhubung ke Cloud. Periksa koneksi internet.", icon: Icons.error_outline, bgColor: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    try {
      await _controller.loadLogs();
      _showElegantToast("Data terbaru berhasil dimuat.", icon: Icons.refresh, bgColor: Colors.blueAccent);
    } catch (e) {
      if (mounted) _showElegantToast("Gagal menyegarkan data.", icon: Icons.warning_amber_rounded, bgColor: Colors.redAccent);
    }
  }

  void _showElegantToast(String message, {IconData icon = Icons.info_outline, Color? bgColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: bgColor ?? Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String content, String confirmText) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pribadi': return Colors.teal;
      case 'Pekerjaan': return Colors.blueAccent;
      case 'Urgent': return Colors.redAccent;
      case 'Lainnya': return Colors.orangeAccent;
      case 'Mechanical': return Colors.deepOrange;
      case 'Electronic': return Colors.indigo;
      case 'Software': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pribadi': return Icons.person;
      case 'Pekerjaan': return Icons.work;
      case 'Urgent': return Icons.local_fire_department;
      case 'Lainnya': return Icons.widgets;
      case 'Mechanical': return Icons.settings;
      case 'Electronic': return Icons.electrical_services;
      case 'Software': return Icons.code;
      default: return Icons.note;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy • HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 100),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 18, color: Colors.grey.shade200),
                    const SizedBox(height: 10),
                    Container(width: double.infinity, height: 14, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
            child: Icon(Icons.cloud_off_rounded, size: 72, color: Colors.deepPurple.shade200),
          ),
          const SizedBox(height: 24),
          Text("Area Cloud Masih Kosong", style: TextStyle(color: Colors.deepPurple.shade900, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Belum ada catatan yang ditambahkan.\nKetuk tombol + untuk mulai menulis.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogModel log, bool isOwner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _getCategoryColor(log.category).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(_getCategoryIcon(log.category), color: _getCategoryColor(log.category), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 6),
                Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: _getCategoryColor(log.category).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(log.category.toUpperCase(), style: TextStyle(color: _getCategoryColor(log.category), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Text(_formatDate(log.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (isOwner) ...[
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LogEditorPage(log: log, controller: _controller)));
                        },
                        child: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () async {
                          bool? confirm = await _showConfirmationDialog(
                            "Hapus Catatan", 
                            "Apakah Anda yakin ingin menghapus catatan ini secara permanen?", 
                            "Hapus"
                          );
                          if (confirm == true) {
                            _controller.removeLog(log);
                            _showElegantToast("Catatan telah dihapus secara permanen.", icon: Icons.delete_outline, bgColor: Colors.redAccent);
                          }
                        }, 
                        child: const Icon(Icons.delete, color: Colors.redAccent, size: 20)
                      ),
                    ] else ...[
                      const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade900,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 26,
                            child: Icon(Icons.person, color: Colors.deepPurple, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: LogController.currentUser,
                                  dropdownColor: Colors.deepPurple.shade800,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  items: const [
                                    DropdownMenuItem(value: 'user_001', child: Text("Halo, Ketua \uD83D\uDC4B")),
                                    DropdownMenuItem(value: 'user_002', child: Text("Halo, Anggota \uD83D\uDC4B")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        LogController.currentUser = val;
                                        LogController.currentRole = val == 'user_001' ? 'Ketua' : 'Anggota';
                                      });
                                    }
                                  },
                                ),
                              ),
                              Text("Punya rencana apa hari ini?", style: TextStyle(color: Colors.deepPurple.shade100, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          bool? confirm = await _showConfirmationDialog(
                            "Konfirmasi Logout", 
                            "Apakah Anda yakin ingin keluar dari sesi saat ini?", 
                            "Keluar"
                          );
                          if (confirm == true) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginView()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Cari logbook...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? _buildSkeletonLoading()
                      : ValueListenableBuilder<List<LogModel>>(
                          valueListenable: _controller.logsNotifier,
                          builder: (context, currentLogs, child) {
                            
                            List<LogModel> displayLogs = currentLogs.where((log) {
                              return log.authorId == LogController.currentUser || log.isPublic == true;
                            }).toList();

                            String searchQuery = _searchController.text.toLowerCase();
                            if (searchQuery.isNotEmpty) {
                              displayLogs = displayLogs.where((log) =>
                                  log.title.toLowerCase().contains(searchQuery) ||
                                  log.description.toLowerCase().contains(searchQuery) ||
                                  log.category.toLowerCase().contains(searchQuery)).toList();
                            }

                            if (displayLogs.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: _refreshData,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.5, child: _buildEmptyState()),
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: _refreshData,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 100),
                                itemCount: displayLogs.length,
                                itemBuilder: (context, index) {
                                  final log = displayLogs[index];
                                  final bool isOwner = log.authorId == LogController.currentUser;
                                  
                                  if (isOwner) {
                                    return Dismissible(
                                      key: Key(log.id.toString()),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        return await _showConfirmationDialog(
                                          "Hapus Catatan", 
                                          "Apakah Anda yakin ingin menghapus catatan ini secara permanen?", 
                                          "Hapus"
                                        );
                                      },
                                      background: Container(
                                        margin: const EdgeInsets.only(bottom: 20),
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        alignment: Alignment.centerRight,
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
                                      ),
                                      onDismissed: (direction) {
                                        _controller.removeLog(log);
                                        _showElegantToast("Catatan telah dihapus secara permanen.", icon: Icons.delete_outline, bgColor: Colors.redAccent);
                                      },
                                      child: _buildLogCard(log, isOwner),
                                    );
                                  }
                                  
                                  return _buildLogCard(log, isOwner);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LogEditorPage(controller: _controller)));
        },
        child: const Icon(Icons.edit_document, color: Colors.white),
      ),
    );
  }
}