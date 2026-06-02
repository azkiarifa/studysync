import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/task_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddTaskScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final DateTime? initialDate;
  final String? initialPriority;
  final String? initialCategory;
  final int? initialScheduleId;

  const AddTaskScreen({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.initialDate,
    this.initialPriority,
    this.initialCategory,
    this.initialScheduleId,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Tugas';
  int? _selectedScheduleId;

  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<String> _categories = ['Tugas', 'Projek', 'Ujian', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null)
      _titleController.text = widget.initialTitle!;
    if (widget.initialDescription != null)
      _descController.text = widget.initialDescription!;
    if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    if (widget.initialPriority != null)
      _selectedPriority = widget.initialPriority!;
    if (widget.initialCategory != null)
      _selectedCategory = widget.initialCategory!;
    if (widget.initialScheduleId != null) {
      _selectedScheduleId = widget.initialScheduleId;
    }
    _dateController.text = DateHelper.formatShortDate(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateHelper.formatShortDate(_selectedDate);
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final task = TaskModel(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: _selectedDate,
        priority: _selectedPriority,
        category: _selectedCategory,
        isCompleted: false,
        scheduleId: _selectedScheduleId,
      );

      final newId = await DbHelper.insertTask(task);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppText.get('taskAdded'))));
        Navigator.pop(context, newId);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppText.get('addTask'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: AppText.get('taskTitle'),
              hintText: AppText.get('taskTitleHint'),
              prefixIcon: Icons.title_rounded,
              validator: (value) =>
                  AppValidator.validateRequired(value, 'Judul'),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _descController,
              labelText: AppText.get('description'),
              hintText: AppText.get('taskDescHint'),
              prefixIcon: Icons.description_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _dateController,
              labelText: AppText.get('dueDate'),
              prefixIcon: Icons.calendar_today_rounded,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 24),

            // Priority Selection
            Text(
              AppText.get('priority'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _priorities.map((p) {
                final isSelected = _selectedPriority == p;
                Color chipColor = AppColors.success;
                if (p == 'High') chipColor = AppColors.danger;
                if (p == 'Medium') chipColor = AppColors.warning;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedPriority = p);
                      }
                    },
                    selectedColor: chipColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              AppText.get('category'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = c);
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
              text: AppText.get('saveTask'),
              onTap: _saveTask,
              icon: Icons.save_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
