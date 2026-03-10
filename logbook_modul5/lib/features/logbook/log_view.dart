import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'log_editor_page.dart';
import '../auth/login_view.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filterScrollController = ScrollController();
  bool _isLoading = true;
  bool _isOnline = true;
  String _selectedFilter = 'Semua';

  final List<String> _filterOptions = [
    'Semua', 'Pribadi', 'Pekerjaan', 'Urgent', 'Lainnya', 'Mechanical', 'Electronic', 'Software'
  ];

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    _checkInitialConnectivity();

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool isConnected = !results.contains(ConnectivityResult.none);
      if (mounted && _isOnline != isConnected) {
        setState(() => _isOnline = isConnected);
      }
      
      if (!isConnected) {
        _showElegantToast("Koneksi terputus. Beralih ke mode offline.", icon: Icons.wifi_off, bgColor: Colors.orange.shade800);
      } else {
        _controller.syncPendingData().then((_) {
          _showElegantToast("Sistem online. Sinkronisasi data berhasil!", icon: Icons.cloud_done, bgColor: Colors.green.shade600);
        });
      }
    });

    Future.microtask(() => _initDatabase());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    var results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = !results.contains(ConnectivityResult.none);
      });
    }
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
      _showElegantToast("Data terbaru berhasil dimuat.", icon: Icons.check_circle_outline, bgColor: Colors.blueAccent);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        content: Text(content, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogDetail(LogModel log) {
    Color catColor = _getCategoryColor(log.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(log.category.toUpperCase(), style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close_rounded, color: Colors.grey.shade600, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(log.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(_getTimeAgo(log.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(log.authorId == 'user_001' ? 'Ketua Tim' : 'Anggota Tim', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, thickness: 1),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: MarkdownBody(
                  data: log.description,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6),
                    h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    listBullet: TextStyle(color: Colors.deepPurple.shade500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pribadi': return const Color(0xFF00B4D8);
      case 'Pekerjaan': return const Color(0xFF4361EE);
      case 'Urgent': return const Color(0xFFF72585);
      case 'Lainnya': return const Color(0xFFF8961E);
      case 'Mechanical': return const Color(0xFFE85D04);
      case 'Electronic': return const Color(0xFF3F37C9);
      case 'Software': return const Color(0xFF2DC653);
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pribadi': return Icons.face_retouching_natural_rounded;
      case 'Pekerjaan': return Icons.work_rounded;
      case 'Urgent': return Icons.whatshot_rounded;
      case 'Lainnya': return Icons.dashboard_customize_rounded;
      case 'Mechanical': return Icons.settings_suggest_rounded;
      case 'Electronic': return Icons.electrical_services_rounded;
      case 'Software': return Icons.code_rounded;
      default: return Icons.note_rounded;
    }
  }

  String _getTimeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 8) {
        return DateFormat('dd MMM yyyy').format(date);
      } else if (difference.inDays >= 1) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 100),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 160, height: 16, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 12),
                    Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 16),
                    Container(width: 90, height: 28, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
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
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            builder: (context, double val, child) {
              return Transform.scale(
                scale: val,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.note_add_rounded, size: 80, color: Colors.deepPurple.shade300),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text("Belum Ada Catatan", style: TextStyle(color: Colors.deepPurple.shade900, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text("Mulai tuangkan ide dan tugas Anda hari ini.\nKetuk tombol di bawah untuk memulai.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogModel log, bool isOwner, int index) {
    Color catColor = _getCategoryColor(log.category);
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 500)),
      curve: Curves.easeOutQuart,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(color: catColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _showLogDetail(log),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [catColor.withOpacity(0.15), catColor.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(_getCategoryIcon(log.category), color: catColor, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(log.category.toUpperCase(), style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text(_getTimeAgo(log.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isOwner) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => LogEditorPage(log: log, controller: _controller)));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                      child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      bool? confirm = await _showConfirmationDialog(
                                        "Hapus Catatan", 
                                        "Catatan ini akan dihapus secara permanen dan tidak dapat dipulihkan.", 
                                        "Hapus"
                                      );
                                      if (confirm == true) {
                                        _controller.removeLog(log);
                                        _showElegantToast("Catatan telah dihapus.", icon: Icons.delete_outline, bgColor: Colors.redAccent);
                                      }
                                    }, 
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                      child: Icon(Icons.delete_rounded, color: Colors.red.shade600, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500, size: 14),
                                    const SizedBox(width: 4),
                                    Text("Terkunci", style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ]
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF311B92), Color(0xFF512DA8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                              child: const CircleAvatar(backgroundColor: Colors.white, radius: 22, child: Icon(Icons.face_retouching_natural, color: Color(0xFF512DA8), size: 28)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LogController.currentRole == 'Ketua' ? "Ketua Tim" : "Anggota Tim",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                  Text("${_getGreeting()}, punya rencana apa?", overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.deepPurple.shade100, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: _isOnline ? Colors.greenAccent : Colors.orangeAccent),
                                ),
                                const SizedBox(width: 4),
                                Text(_isOnline ? "Online" : "Offline", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                            ),
                            onPressed: () async {
                              bool? confirm = await _showConfirmationDialog("Logout", "Yakin ingin keluar dari sesi aplikasi?", "Keluar");
                              if (confirm == true) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
                            },
                          ),
                        ],
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Cari judul, deskripsi, atau kategori...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF512DA8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    controller: _filterScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filterOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filterOptions[index];
                      final isSelected = _selectedFilter == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
                        child: ChoiceChip(
                          label: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = option);
                              double screenWidth = MediaQuery.of(context).size.width;
                              double targetOffset = (index * 90.0) - (screenWidth / 2) + 45.0;
                              targetOffset = targetOffset.clamp(0.0, _filterScrollController.position.maxScrollExtent);
                              _filterScrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF512DA8),
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _isLoading
                      ? _buildSkeletonLoading()
                      : ValueListenableBuilder<List<LogModel>>(
                          valueListenable: _controller.logsNotifier,
                          builder: (context, currentLogs, child) {
                            
                            List<LogModel> displayLogs = currentLogs.where((log) {
                              bool isVisible = log.authorId == LogController.currentUser || log.isPublic == true;
                              bool matchesFilter = _selectedFilter == 'Semua' || log.category == _selectedFilter;
                              return isVisible && matchesFilter;
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
                                color: const Color(0xFF512DA8),
                                onRefresh: _refreshData,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.5, child: _buildEmptyState()),
                                ),
                              );
                            }

                            return RefreshIndicator(
                              color: const Color(0xFF512DA8),
                              onRefresh: _refreshData,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 120),
                                itemCount: displayLogs.length,
                                itemBuilder: (context, index) {
                                  final log = displayLogs[index];
                                  final bool isOwner = log.authorId == LogController.currentUser;
                                  
                                  if (isOwner) {
                                    return Dismissible(
                                      key: Key(log.id.toString()),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        return await _showConfirmationDialog("Hapus Catatan", "Tindakan ini tidak bisa dibatalkan.", "Hapus");
                                      },
                                      background: Container(
                                        margin: const EdgeInsets.only(bottom: 20),
                                        padding: const EdgeInsets.symmetric(horizontal: 28),
                                        alignment: Alignment.centerRight,
                                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(28)),
                                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 36),
                                      ),
                                      onDismissed: (direction) {
                                        _controller.removeLog(log);
                                        _showElegantToast("Catatan telah dihapus.", icon: Icons.delete_outline, bgColor: Colors.redAccent);
                                      },
                                      child: _buildLogCard(log, isOwner, index),
                                    );
                                  }
                                  return _buildLogCard(log, isOwner, index);
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF512DA8),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LogEditorPage(controller: _controller)));
        },
        icon: const Icon(Icons.edit_document, color: Colors.white),
        label: const Text("Catatan Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}