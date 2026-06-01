import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/target_model.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditTargetScreen extends StatefulWidget {
  final TargetModel target;

  const EditTargetScreen({super.key, required this.target});

  @override
  State<EditTargetScreen> createState() => _EditTargetScreenState();
}

class _EditTargetScreenState extends State<EditTargetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _courseController;
  late TextEditingController _targetScoreController;
  late TextEditingController _currentScoreController;
  late TextEditingController _notesController;

  late String _selectedGrade;
  final List<String> _grades = ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _courseController = TextEditingController(text: widget.target.courseName);
    _targetScoreController = TextEditingController(text: widget.target.targetScore.toStringAsFixed(0));
    _currentScoreController = TextEditingController(text: widget.target.currentScore.toStringAsFixed(0));
    _notesController = TextEditingController(text: widget.target.notes);
    _selectedGrade = widget.target.targetGrade;
  }

  Future<void> _updateTarget() async {
    if (_formKey.currentState!.validate()) {
      final updatedTarget = widget.target.copyWith(
        courseName: _courseController.text.trim(),
        targetGrade: _selectedGrade,
        targetScore: double.parse(_targetScoreController.text),
        currentScore: double.parse(_currentScoreController.text),
        notes: _notesController.text.trim(),
      );

      await DbHelper.updateTarget(updatedTarget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _courseController.dispose();
    _targetScoreController.dispose();
    _currentScoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Target'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _courseController,
              labelText: 'Mata Kuliah',
              hintText: 'Struktur Data / Kalkulus...',
              prefixIcon: Icons.book_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Mata Kuliah'),
            ),
            const SizedBox(height: 20),

            // Dropdown Target Grade
            DropdownButtonFormField<String>(
              value: _selectedGrade,
              decoration: InputDecoration(
                labelText: 'Target Indeks Huruf',
                prefixIcon: const Icon(Icons.grade_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              items: _grades.map((String grade) {
                return DropdownMenuItem<String>(
                  value: grade,
                  child: Text(grade),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedGrade = newValue);
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _currentScoreController,
                    labelText: 'Nilai Sekarang',
                    hintText: '0-100',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.percent_rounded,
                    validator: (value) => AppValidator.validatePercentage(value, 'Nilai'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _targetScoreController,
                    labelText: 'Target Nilai Angka',
                    hintText: '0-100',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.ads_click_rounded,
                    validator: (value) => AppValidator.validatePercentage(value, 'Target Nilai'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _notesController,
              labelText: 'Catatan Tambahan',
              hintText: 'Tugas harian minimal 80, UAS minimal 85...',
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Simpan Perubahan',
              onTap: _updateTarget,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
