import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/subject_model.dart';
import '../../models/glossary_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class GlossaryDetailScreen extends StatefulWidget {
  final SubjectModel subject;

  const GlossaryDetailScreen({super.key, required this.subject});

  @override
  State<GlossaryDetailScreen> createState() => _GlossaryDetailScreenState();
}

class _GlossaryDetailScreenState extends State<GlossaryDetailScreen> {
  List<GlossaryModel> _glossaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGlossaries();
  }

  Future<void> _loadGlossaries() async {
    setState(() => _isLoading = true);
    try {
      final glossaries = await DbHelper.getAllGlossaries(widget.subject.id!);
      setState(() {
        _glossaries = glossaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGlossary(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    await DbHelper.deleteGlossary(id);
    _loadGlossaries();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Istilah berhasil dihapus')),
    );
  }

  void _showAddGlossarySheet({GlossaryModel? editGlossary}) {
    final termController = TextEditingController(text: editGlossary?.term ?? '');
    final definitionController = TextEditingController(text: editGlossary?.definition ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  editGlossary != null ? 'Edit Istilah' : 'Tambah Istilah Baru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: termController,
                  labelText: 'Istilah',
                  hintText: 'Masukkan istilah...',
                  prefixIcon: Icons.title_rounded,
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: definitionController,
                  labelText: 'Definisi',
                  hintText: 'Tulis definisi di sini...',
                  prefixIcon: Icons.description_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: editGlossary != null ? 'Simpan Perubahan' : 'Tambah Istilah',
                  icon: Icons.save_rounded,
                  onTap: () async {
                    if (termController.text.trim().isEmpty ||
                        definitionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Istilah dan definisi harus diisi')),
                      );
                      return;
                    }

                    if (editGlossary != null) {
                      final updated = editGlossary.copyWith(
                        term: termController.text.trim(),
                        definition: definitionController.text.trim(),
                      );
                      await DbHelper.updateGlossary(updated);
                    } else {
                      final glossary = GlossaryModel(
                        subjectId: widget.subject.id!,
                        term: termController.text.trim(),
                        definition: definitionController.text.trim(),
                      );
                      await DbHelper.insertGlossary(glossary);
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadGlossaries();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = Color(widget.subject.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Subject header with stats
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        subjectColor,
                        subjectColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: subjectColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.subject.description.isNotEmpty)
                        Text(
                          widget.subject.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      if (widget.subject.description.isNotEmpty)
                        const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatChip(Icons.list_alt_rounded, '${_glossaries.length} Istilah'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Glossary list
                Expanded(
                  child: _glossaries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_add_rounded,
                                size: 64,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                                    : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada istilah',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap tombol + untuk menambahkan istilah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _glossaries.length,
                          itemBuilder: (context, index) {
                            final glossary = _glossaries[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: subjectColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.label_outline_rounded,
                                          color: subjectColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              glossary.term,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              glossary.definition,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showAddGlossarySheet(editGlossary: glossary);
                                          } else if (value == 'delete') {
                                            _deleteGlossary(glossary.id!);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                        ],
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGlossarySheet(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
