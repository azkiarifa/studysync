import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/subject_model.dart';
import '../../models/glossary_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'glossary_detail_screen.dart';

class GlossarySubjectScreen extends StatefulWidget {
  const GlossarySubjectScreen({super.key});

  @override
  State<GlossarySubjectScreen> createState() => _GlossarySubjectScreenState();
}

class _GlossarySubjectScreenState extends State<GlossarySubjectScreen> {
  List<SubjectModel> _subjects = [];
  Map<int, List<GlossaryModel>> _subjectGlossaries = {};
  bool _isLoading = true;

  final List<int> _colorOptions = [
    0xFF6366F1, // Indigo
    0xFFEC4899, // Pink
    0xFF10B981, // Emerald
    0xFFF59E0B, // Amber
    0xFF3B82F6, // Blue
    0xFFEF4444, // Red
    0xFF8B5CF6, // Violet
    0xFF14B8A6, // Teal
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await DbHelper.getAllSubjects();
      final Map<int, List<GlossaryModel>> glossaryMap = {};
      for (final subject in subjects) {
        if (subject.id != null) {
          glossaryMap[subject.id!] = await DbHelper.getAllGlossaries(subject.id!);
        }
      }
      setState(() {
        _subjects = subjects;
        _subjectGlossaries = glossaryMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSubject(int id) async {
    await DbHelper.deleteSubject(id);
    _loadSubjects();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mata Kuliah/Subjek berhasil dihapus')),
      );
    }
  }

  void _showAddSubjectSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int selectedColor = _colorOptions[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    // Handle bar
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
                      'Buat Subjek Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: titleController,
                      labelText: 'Nama Subjek',
                      hintText: 'Contoh: Pemrograman Mobile',
                      prefixIcon: Icons.book_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: descController,
                      labelText: 'Deskripsi',
                      hintText: 'Materi yang akan dipelajari...',
                      prefixIcon: Icons.description_rounded,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pilih Warna',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colorOptions.length,
                        itemBuilder: (context, index) {
                          final colorVal = _colorOptions[index];
                          final isSelected = selectedColor == colorVal;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => selectedColor = colorVal);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Color(colorVal).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Simpan Subjek',
                      icon: Icons.save_rounded,
                      onTap: () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama subjek tidak boleh kosong')),
                          );
                          return;
                        }
                        final subject = SubjectModel(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          color: selectedColor,
                        );
                        await DbHelper.insertSubject(subject);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        _loadSubjects();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Concept Glossary'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_rounded,
                        size: 72,
                        color: isDark
                            ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                            : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada subjek',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan subjek baru untuk menyimpan glosarium!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    final glossaries = _subjectGlossaries[subject.id] ?? [];
                    final totalCount = glossaries.length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GlossaryDetailScreen(subject: subject),
                            ),
                          ).then((_) => _loadSubjects());
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Subjek?'),
                              content: Text('Apakah Anda yakin ingin menghapus subjek "${subject.title}" beserta semua isinya?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteSubject(subject.id!);
                                  },
                                  child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Color(subject.color),
                                Color(subject.color).withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(subject.color).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.view_carousel_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        subject.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$totalCount istilah',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (subject.description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    subject.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectSheet,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
