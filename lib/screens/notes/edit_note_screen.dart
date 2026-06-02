import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/note_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditNoteScreen extends StatefulWidget {
  final NoteModel note;

  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late bool _isPinned;
  late int _selectedColorValue;

  final List<int> _noteColors = const [
    0xFFFEE2E2, // Rose
    0xFFFEF3C7, // Amber
    0xFFD1FAE5, // Emerald
    0xFFE0F2FE, // Sky Blue
    0xFFE0E7FF, // Indigo
    0xFFF3E8FF, // Purple
    0xFFF1F5F9, // Slate Gray
    0xFFECFDF5, // Mint
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _isPinned = widget.note.isPinned;
    _selectedColorValue = widget.note.color;
  }

  Future<void> _updateNote() async {
    if (_formKey.currentState!.validate()) {
      final updatedNote = widget.note.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        color: _selectedColorValue,
        isPinned: _isPinned,
      );

      await DbHelper.updateNote(updatedNote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Notes'),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.primary : null,
            ),
            onPressed: () {
              setState(() => _isPinned = !_isPinned);
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: 'Judul Review',
              hintText: 'Masukkan judul review...',
              prefixIcon: Icons.title_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Judul'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _contentController,
              labelText: 'Isi Review',
              hintText: 'Tulis notes di sini...',
              maxLines: 8,
              validator: (value) => AppValidator.validateRequired(value, 'Isi Catatan'),
            ),
            const SizedBox(height: 24),

            // Color Picker Label
            const Text(
              'Pilih Warna Catatan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _noteColors.length,
                itemBuilder: (context, index) {
                  final colorVal = _noteColors[index];
                  final isSelected = _selectedColorValue == colorVal;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColorValue = colorVal);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.1),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Simpan Perubahan',
              onTap: _updateNote,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
