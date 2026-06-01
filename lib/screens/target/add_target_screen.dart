import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/target_model.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddTargetScreen extends StatefulWidget {
  const AddTargetScreen({super.key});

  @override
  State<AddTargetScreen> createState() => _AddTargetScreenState();
}

class _AddTargetScreenState extends State<AddTargetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  final _targetScoreController = TextEditingController(text: '85');
  final _currentScoreController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  String _selectedGrade = 'A';
  final List<String> _grades = ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E'];

  Future<void> _saveTarget() async {
    if (_formKey.currentState!.validate()) {
      final target = TargetModel(
        courseName: _courseController.text.trim(),
        targetGrade: _selectedGrade,
        targetScore: double.parse(_targetScoreController.text),
        currentScore: double.parse(_currentScoreController.text),
        notes: _notesController.text.trim(),
      );

      await DbHelper.insertTarget(target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target berhasil disimpan')),
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
        title: const Text('Add Target'),
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
              text: 'Simpan Sasaran',
              onTap: _saveTarget,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
