import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/habit_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditHabitScreen extends StatefulWidget {
  final HabitModel habit;

  const EditHabitScreen({super.key, required this.habit});

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedFrequency;

  final List<String> _frequencies = ['Daily', 'Weekly'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _selectedFrequency = widget.habit.frequency;
  }

  Future<void> _updateHabit() async {
    if (_formKey.currentState!.validate()) {
      final updatedHabit = widget.habit.copyWith(
        name: _nameController.text.trim(),
        frequency: _selectedFrequency,
      );

      await DbHelper.updateHabit(updatedHabit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habit berhasil diperbarui')),
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
        title: const Text('Edit Habit'),
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

            // Frequency Selection
            const Text(
              'Frekuensi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: _frequencies.map((f) {
                final isSelected = _selectedFrequency == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFrequency = f);
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Simpan Perubahan',
              onTap: _updateHabit,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
