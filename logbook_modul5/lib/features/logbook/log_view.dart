import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import '../auth/login_view.dart';
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';
import '../../services/access_control_service.dart';
import 'log_editor_page.dart'; // Import halaman editor baru

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

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
    Future.microtask(() => _controller.loadLogs());
  }

  Future<void> _initDatabase() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Koneksi Cloud Timeout."),
      );
      await _controller.loadLogs();
    } catch (e) {
      if (mounted) {
        _showCustomToast("Gagal terhubung ke Cloud. Periksa koneksi internet Anda.", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCustomToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Urgent': return const Color(0xFFFF5252);
      case 'Pekerjaan': return const Color(0xFF448AFF);
      case 'Pribadi': return const Color(0xFF00BFA5);
      default: return const Color(0xFFFFB300);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Urgent': return Icons.local_fire_department_rounded;
      case 'Pekerjaan': return Icons.work_rounded;
      case 'Pribadi': return Icons.person_rounded;
      default: return Icons.dashboard_customize_rounded;
    }
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: 4,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                height: 120,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: double.infinity, height: 20, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                          const SizedBox(height: 12),
                          Container(width: 150, height: 14, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                          const Spacer(),
                          Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: Icon(Icons.exit_to_app_rounded, size: 48, color: Colors.red.shade500)),
                const SizedBox(height: 24),
                const Text("Sampai Jumpa!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text("Apakah Anda yakin ingin keluar dari sesi ini?", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: const Text("Batal", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNGSI NAVIGASI KE HALAMAN EDITOR BARU ---
  void _goToEditor({LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)), boxShadow: [BoxShadow(color: Colors.deepPurple.shade200, blurRadius: 20, offset: const Offset(0, 10))]),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.person_rounded, size: 28, color: Colors.deepPurple.shade700))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Halo, ${widget.username} 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 4), Text("Punya rencana apa hari ini?", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)))])),
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    splashRadius: 24,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 26),
                    onPressed: _showLogoutConfirmation,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))]),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Cari logbook...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.deepPurple.shade400),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() {}); })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, currentLogs, child) {
                if (_isLoading) {
                  return _buildSkeletonLoading();
                }

                List<LogModel> displayLogs = currentLogs;
                String searchQuery = _searchController.text.toLowerCase();
                
                if (searchQuery.isNotEmpty) {
                  displayLogs = currentLogs.where((log) => log.title.toLowerCase().contains(searchQuery) || log.description.toLowerCase().contains(searchQuery) || log.category.toLowerCase().contains(searchQuery)).toList();
                }

                if (currentLogs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async { 
                      try { 
                        await _controller.loadLogs(); 
                      } catch (e) { 
                        _showCustomToast("Koneksi terputus. Gagal menyegarkan data.", isError: true); 
                      } 
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOutSine,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 15 * math.sin(value * 3.14)),
                                    child: child,
                                  );
                                },
                                child: Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))]), child: Icon(Icons.cloud_off_rounded, size: 70, color: Colors.deepPurple.shade200)),
                              ),
                              const SizedBox(height: 32), 
                              const Text("Area Cloud Masih Kosong", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 8),
                              const Text("Tarik layar ke bawah untuk refresh,\natau tekan + untuk membuat logbook.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5))
                            ]
                          )
                        ),
                      ],
                    ),
                  );
                }

                if (displayLogs.isEmpty && searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 70, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Tidak ada hasil untuk '$searchQuery'", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Colors.deepPurple,
                  onRefresh: () async { 
                    try { 
                      await _controller.loadLogs(); 
                    } catch (e) { 
                      _showCustomToast("Koneksi terputus. Gagal menyegarkan data.", isError: true); 
                    } 
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: displayLogs.length,
                    itemBuilder: (context, index) {
                      final log = displayLogs[index];
                      Color categoryColor = _getCategoryColor(log.category);

                      // --- GATEKEEPER ROLE CHECK ---
                      final bool isOwner = log.authorId == 'user_001'; 
                      final String currentRole = 'Anggota';
                      
                      String formattedDate = log.date;
                      try {
                        DateTime parsedDate = DateTime.parse(log.date);
                        formattedDate = DateFormat('dd MMM yyyy • HH:mm').format(parsedDate);
                      } catch (e) {}
                      
                      return Dismissible(
                        key: Key(log.id ?? log.date),
                        // CEK IZIN HAPUS UNTUK DISMISSIBLE
                        direction: AccessControlService.canPerform(currentRole, AccessControlService.actionDelete, isOwner: isOwner) 
                                   ? DismissDirection.endToStart 
                                   : DismissDirection.none,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.3),
                            builder: (BuildContext context) {
                              return BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
                                  title: const Text("Hapus Catatan?", style: TextStyle(fontWeight: FontWeight.bold)), 
                                  content: const Text("Catatan ini akan dihapus secara permanen dari Cloud."), 
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))), 
                                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade500, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.of(context).pop(true), child: const Text("Hapus"))
                                  ]
                                ),
                              );
                            },
                          );
                        },
                        background: Container(margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(color: Colors.red.shade500, borderRadius: BorderRadius.circular(24)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 28), child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 36)),
                        onDismissed: (direction) {
                          _controller.removeLog(log);
                          _showCustomToast("Catatan dihapus dari Cloud", isError: true);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: categoryColor.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))]),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                // CEK IZIN EDIT SEBELUM MEMBUKA HALAMAN EDITOR
                                if (AccessControlService.canPerform(currentRole, AccessControlService.actionUpdate, isOwner: isOwner)) {
                                  _goToEditor(log: log);
                                } else {
                                  _showCustomToast("Akses Ditolak: Anda tidak memiliki izin mengedit catatan ini.", isError: true);
                                }
                              },
                              splashColor: categoryColor.withOpacity(0.1),
                              highlightColor: categoryColor.withOpacity(0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(22.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: categoryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Icon(_getCategoryIcon(log.category), color: categoryColor, size: 28)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(log.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87, letterSpacing: -0.5)),
                                          const SizedBox(height: 6),
                                          Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: categoryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(log.category.toUpperCase(), style: TextStyle(fontSize: 10, color: categoryColor, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                                                    const SizedBox(width: 8),
                                                    Flexible(child: Text(formattedDate, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600))),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // CEK IZIN TOMBOL EDIT
                                                  if (AccessControlService.canPerform(currentRole, AccessControlService.actionUpdate, isOwner: isOwner))
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                                      onPressed: () => _goToEditor(log: log),
                                                    ),
                                                  // CEK IZIN TOMBOL HAPUS
                                                  if (AccessControlService.canPerform(currentRole, AccessControlService.actionDelete, isOwner: isOwner))
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                                      onPressed: () {
                                                        _controller.removeLog(log);
                                                        _showCustomToast("Catatan dihapus", isError: true);
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]),
        child: FloatingActionButton(
          onPressed: () => _goToEditor(), // LANGSUNG KE EDITOR PAGE
          backgroundColor: Colors.deepPurple.shade600,
          splashColor: Colors.white.withOpacity(0.3),
          elevation: 0,
          child: const Icon(Icons.edit_document, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}