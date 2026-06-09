import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/habit_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
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
  String _selectedFrequency = 'Daily';

  final List<String> _frequencies = ['Daily', 'Weekly'];

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final habit = HabitModel(
        name: _nameController.text.trim(),
        frequency: _selectedFrequency,
        streak: 0,
        lastCompleted: null,
      );

      await DbHelper.insertHabit(habit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.get('habitSaved'))),
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
        title: Text(AppText.get('addHabit')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _nameController,
              labelText: AppText.get('habitName'),
              hintText: AppText.get('habitHint'),
              prefixIcon: Icons.repeat_rounded,
              validator: (value) => AppValidator.validateRequired(value, 'Nama Kebiasaan'),
            ),
            const SizedBox(height: 24),
            
            // Frequency Selection
            Text(
              AppText.get('frequency'),
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
              text: AppText.get('trackHabit'),
              onTap: _saveHabit,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
