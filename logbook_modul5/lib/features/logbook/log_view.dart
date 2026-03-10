import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lottie/lottie.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'log_editor_page.dart';
import '../auth/login_view.dart';

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> with SingleTickerProviderStateMixin {
  late final LogController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filterScrollController = ScrollController();
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

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
    
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

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
    _glowController.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 10,
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String content, String confirmText) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
        content: Text(content, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 4,
              shadowColor: Colors.redAccent.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 48,
                height: 6,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: catColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(log.category.toUpperCase(), style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(log.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2)),
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
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, thickness: 1.5, color: Color(0xFFF0F0F0)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                physics: const BouncingScrollPhysics(),
                child: MarkdownBody(
                  data: log.description,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.6),
                    h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                    h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                    listBullet: TextStyle(color: Colors.deepPurple.shade500),
                    codeblockDecoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
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
      case 'Urgent': return const Color(0xFFFF006E);
      case 'Lainnya': return const Color(0xFFFB5607);
      case 'Mechanical': return const Color(0xFFFFBE0B);
      case 'Electronic': return const Color(0xFF8338EC);
      case 'Software': return const Color(0xFF38B000);
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
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade50, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20))),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 180, height: 18, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 12),
                    Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 20),
                    Container(width: 100, height: 30, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
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
          SizedBox(
            height: 250,
            child: Lottie.network(
              'https://lottie.host/971b8ee6-0a25-419b-ab29-b6bb523c9657/wV5Rz36w72.json', 
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  builder: (context, double val, child) {
                    return Transform.scale(
                      scale: val,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.note_add_rounded, size: 80, color: Colors.deepPurple.shade300),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text("Belum Ada Catatan", style: TextStyle(color: Colors.deepPurple.shade900, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text("Mulai tuangkan ide dan tugas Anda hari ini.\nKetuk tombol cahaya di bawah untuk memulai.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
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
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: catColor.withOpacity(0.15), blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            splashColor: catColor.withOpacity(0.1),
            highlightColor: catColor.withOpacity(0.05),
            onTap: () => _showLogDetail(log),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [catColor.withOpacity(0.2), catColor.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: catColor.withOpacity(0.2), width: 1.5),
                    ),
                    child: Icon(_getCategoryIcon(log.category), color: catColor, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.black87, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Text(log.category.toUpperCase(), style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                                      const SizedBox(width: 6),
                                      Text(_getTimeAgo(log.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w700)),
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
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                      child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
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
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                      child: Icon(Icons.delete_rounded, color: Colors.red.shade600, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500, size: 14),
                                    const SizedBox(width: 6),
                                    Text("Terkunci", style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFFF4F6FB),
      body: Stack(
        children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF311B92), Color(0xFF512DA8), Color(0xFF673AB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                shape: BoxShape.circle, 
                                boxShadow: [BoxShadow(color: Colors.deepPurple.shade900.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]
                              ),
                              child: const CircleAvatar(backgroundColor: Colors.white, radius: 24, child: Icon(Icons.face_retouching_natural, color: Color(0xFF512DA8), size: 32)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LogController.currentRole == 'Ketua' ? "Ketua Tim" : "Anggota Tim",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                  Text("${_getGreeting()}, punya rencana apa?", overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.deepPurple.shade100, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.greenAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _isOnline ? Colors.greenAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(seconds: 1),
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, 
                                    color: _isOnline ? Colors.greenAccent : Colors.orangeAccent,
                                    boxShadow: [BoxShadow(color: _isOnline ? Colors.greenAccent : Colors.orangeAccent, blurRadius: 6, spreadRadius: 1)],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(_isOnline ? "Online" : "Offline", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
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
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.deepPurple.shade900.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: "Cari judul, deskripsi, atau kategori...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF512DA8), size: 26),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    controller: _filterScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filterOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filterOptions[index];
                      final isSelected = _selectedFilter == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ChoiceChip(
                            label: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFilter = option);
                                double screenWidth = MediaQuery.of(context).size.width;
                                double targetOffset = (index * 100.0) - (screenWidth / 2) + 50.0;
                                targetOffset = targetOffset.clamp(0.0, _filterScrollController.position.maxScrollExtent);
                                _filterScrollController.animateTo(
                                  targetOffset,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF512DA8),
                            checkmarkColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: isSelected ? 4 : 0,
                            shadowColor: const Color(0xFF512DA8).withOpacity(0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
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
                                        margin: const EdgeInsets.only(bottom: 24),
                                        padding: const EdgeInsets.symmetric(horizontal: 32),
                                        alignment: Alignment.centerRight,
                                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(32)),
                                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 40),
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
      
      // --- ANIMASI GLOW PADA TOMBOL FLOATING ACTION BUTTON ---
      floatingActionButton: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF512DA8).withOpacity(0.6),
                  blurRadius: _glowAnimation.value + 10,
                  spreadRadius: (_glowAnimation.value / 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF512DA8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LogEditorPage(controller: _controller)));
              },
              icon: const Icon(Icons.edit_document, color: Colors.white),
              label: const Text("Catatan Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
            ),
          );
        },
      ),
    );
  }
}