import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/task_model.dart';
import '../../models/schedule_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../utils/date_helper.dart';
import '../../utils/validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _dateController;

  late DateTime _selectedDate;
  late String _selectedPriority;
  late String _selectedCategory;
  int? _selectedScheduleId;
  List<ScheduleModel> _availableSchedules = [];

  final List<String> _priorities = ['Low', 'Medium', 'High'];
  final List<String> _categories = ['Tugas', 'Projek', 'Ujian', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _dateController = TextEditingController();

    _selectedDate = widget.task.dueDate;
    _selectedPriority = widget.task.priority;
    _selectedCategory = widget.task.category;
    _selectedScheduleId = widget.task.scheduleId;

    _dateController.text = DateHelper.formatShortDate(_selectedDate);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final schedules = await DbHelper.getAllSchedules();
    setState(() {
      _availableSchedules = schedules;
    });
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

  Future<void> _updateTask() async {
    if (_formKey.currentState!.validate()) {
      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: _selectedDate,
        priority: _selectedPriority,
        category: _selectedCategory,
        scheduleId: _selectedScheduleId,
      );

      await DbHelper.updateTask(updatedTask);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppText.get('taskUpdated'))));
        Navigator.pop(context);
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
      appBar: AppBar(title: Text(AppText.get('editTask'))),
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
            DropdownButtonFormField<int?>(
              initialValue: _selectedScheduleId,
              decoration: InputDecoration(
                labelText: AppText.get('selectScheduleOptional'),
                prefixIcon: const Icon(Icons.schedule_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(AppText.get('noScheduleLink')),
                ),
                ..._availableSchedules.map((schedule) {
                  return DropdownMenuItem<int?>(
                    value: schedule.id,
                    child: Text(schedule.title),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedScheduleId = value);
              },
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
              text: AppText.get('saveChanges'),
              onTap: _updateTask,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
