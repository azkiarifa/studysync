import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/note_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isPinned = false;
  int _selectedColorValue = 0xFFFEE2E2; // Soft Rose default

  // Soft pastel colors that contrast nicely with dark/light text
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

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final note = NoteModel(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        color: _selectedColorValue,
        isPinned: _isPinned,
      );

      await DbHelper.insertNote(note);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppText.get('noteSaved'))));
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
        title: Text(AppText.get('addNote')),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.primary : null,
            ),
            onPressed: () {
              setState(() => _isPinned = !_isPinned);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: AppText.get('noteTitle'),
              hintText: AppText.get('noteTitleHint'),
              prefixIcon: Icons.title_rounded,
              validator: (value) =>
                  AppValidator.validateRequired(value, 'Judul'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _contentController,
              labelText: AppText.get('noteContent'),
              hintText: AppText.get('noteContentHint'),
              maxLines: 8,
              validator: (value) =>
                  AppValidator.validateRequired(value, 'Isi Catatan'),
            ),
            const SizedBox(height: 24),

            // Color Picker Label
            Text(
              AppText.get('chooseNoteColor'),
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
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black.withValues(alpha: 0.1),
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
              text: AppText.get('saveNote'),
              onTap: _saveNote,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
