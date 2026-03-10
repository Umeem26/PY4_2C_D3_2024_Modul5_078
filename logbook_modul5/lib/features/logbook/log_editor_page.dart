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

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedCategory = 'Pribadi';
  final List<String> _categories = ['Pribadi', 'Pekerjaan', 'Urgent', 'Lainnya'];
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? 'Pribadi';
    _isPublic = widget.log?.isPublic ?? false;

    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan deskripsi tidak boleh kosong", style: TextStyle(fontWeight: FontWeight.bold))),
      );
      return;
    }

    if (widget.log == null) {
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
    } else {
      widget.controller.updateLog(
        widget.log!,
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan", style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.deepPurple.shade900,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Editor", icon: Icon(Icons.edit_note_rounded)),
              Tab(text: "Pratinjau", icon: Icon(Icons.preview_rounded)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.save_rounded), onPressed: _save)
          ],
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Judul",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      title: const Text("Publikasikan ke Tim", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_isPublic ? "Dapat dilihat oleh anggota tim" : "Hanya Anda yang dapat melihatnya", style: const TextStyle(fontSize: 12)),
                      value: _isPublic,
                      activeColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onChanged: (val) {
                        setState(() => _isPublic = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: "Tulis dengan format Markdown...\nContoh: \n# Judul Besar\n**Teks Tebal**\n- Poin 1",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: _descController.text.isEmpty ? "_Belum ada teks untuk ditampilkan..._" : _descController.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}