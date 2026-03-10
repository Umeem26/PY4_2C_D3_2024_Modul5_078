import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'models/log_model.dart';
import 'log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final LogController controller;

  const LogEditorPage({
    super.key,
    this.log,
    required this.controller,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  final List<String> _categories = [
    'Pribadi', 'Pekerjaan', 'Urgent', 'Lainnya', 
    'Mechanical', 'Electronic', 'Software'
  ];
  late String _selectedCategory;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _isPublic = widget.log?.isPublic ?? false;

    String existingCategory = widget.log?.category ?? 'Pribadi';
    if (!_categories.contains(existingCategory)) {
      existingCategory = 'Pribadi';
    }
    _selectedCategory = existingCategory;

    _descController.addListener(() {
      setState(() {});
    });

    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _glowController.dispose();
    super.dispose();
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

  void _showCustomToast(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: color,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        elevation: 10,
      ),
    );
  }

  void _save() {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      _showCustomToast("Judul dan isi catatan tidak boleh kosong!", Icons.warning_amber_rounded, Colors.orange.shade800);
      return;
    }

    if (widget.log == null) {
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
      _showCustomToast("Catatan baru berhasil diamankan.", Icons.check_circle_outline_rounded, Colors.green.shade600);
    } else {
      widget.controller.updateLog(
        widget.log!,
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
      _showCustomToast("Perubahan catatan berhasil disimpan.", Icons.update_rounded, Colors.blueAccent);
    }
    Navigator.pop(context);
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 48,
                height: 6,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text("Pilih Kategori", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final catColor = _getCategoryColor(cat);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _selectedCategory == cat ? catColor.withAlpha(26) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedCategory == cat ? catColor : Colors.grey.shade200, width: 2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: catColor.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_getCategoryIcon(cat), color: catColor),
                        ),
                        title: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedCategory == cat ? catColor : Colors.black87)),
                        trailing: _selectedCategory == cat ? Icon(Icons.check_circle_rounded, color: catColor) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color activeCatColor = _getCategoryColor(_selectedCategory);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 80,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF311B92), Color(0xFF512DA8), Color(0xFF673AB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 0.5)),
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(16)),
              child: TabBar(
                indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 8, offset: const Offset(0, 4))]),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF512DA8),
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit_document, size: 18), SizedBox(width: 8), Text("Tulis")])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.preview_rounded, size: 18), SizedBox(width: 8), Text("Pratinjau")])),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            // --- TAB EDITOR ---
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field Judul
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Judul Catatan",
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                        prefixIcon: Icon(Icons.title_rounded, color: Colors.deepPurple.shade300),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Row Kategori & Publikasi
                  Row(
                    children: [
                      // Tombol Kategori
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _showCategoryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: activeCatColor.withAlpha(38), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(_getCategoryIcon(_selectedCategory), color: activeCatColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Kategori", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(_selectedCategory, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Switch Publikasi
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: _isPublic ? Colors.deepPurple.withAlpha(13) : Colors.white,
                            border: Border.all(color: _isPublic ? Colors.deepPurple.shade200 : Colors.transparent, width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Visibilitas", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(_isPublic ? "Publik" : "Privat", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _isPublic ? Colors.deepPurple.shade700 : Colors.black87)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPublic,
                                activeColor: Colors.deepPurple.shade600,
                                activeTrackColor: Colors.deepPurple.shade200,
                                onChanged: (val) => setState(() => _isPublic = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Field Editor Markdown
                  const Text("  Isi Catatan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(height: 1.6, color: Colors.grey.shade800, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Tulis cerita, ide, atau dokumentasi di sini...\n\nMendukung Markdown:\n# Judul Besar\n**Teks Tebal**\n* Teks Miring\n- List Poin",
                        hintStyle: TextStyle(color: Colors.grey.shade400, height: 1.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Ruang ekstra untuk tombol floating
                ],
              ),
            ),
            
            // --- TAB PRATINJAU (PREVIEW) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _descController.text.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Icon(Icons.visibility_off_rounded, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("Belum ada teks untuk dilihat.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : MarkdownBody(
                        data: _descController.text,
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
            ),
          ],
        ),

        // --- TOMBOL SIMPAN GLOWING (SUDAH DIPINDAH KE DALAM SCAFFOLD) ---
        floatingActionButton: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF512DA8).withAlpha(153),
                    blurRadius: _glowAnimation.value + 15,
                    spreadRadius: (_glowAnimation.value / 3),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF512DA8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text("Simpan Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
              ),
            );
          },
        ),
      ),
    );
  }
}