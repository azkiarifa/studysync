import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/habit_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _targetDays = 7;

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final habit = HabitModel(
        name: _nameController.text.trim(),
        targetDaysPerWeek: _targetDays,
        color: 0xFF6366F1, // Default indigo
        createdAt: DateTime.now(),
      );

      await DbHelper.insertHabit(habit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit berhasil disimpan')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _nameController,
              labelText: 'Nama Kebiasaan',
              hintText: 'Membaca buku / Minum air / Olahraga...',
              prefixIcon: Icons.repeat_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Nama Kebiasaan'),
            ),
            const SizedBox(height: 24),
            
            // Target Selection
            const Text(
              'Target Hari per Minggu',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_targetDays Hari', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Slider(
                  value: _targetDays.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _targetDays = value.toInt());
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Mulai Lacak Kebiasaan',
              onTap: _saveHabit,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
