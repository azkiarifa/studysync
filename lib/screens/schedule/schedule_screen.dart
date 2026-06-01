import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../database/db_helper.dart';
import '../../models/schedule_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/schedule_card.dart';
import '../../models/task_model.dart';
import '../../widgets/task_card.dart';
import 'add_schedule_screen.dart';
import 'edit_schedule_screen.dart';
import '../task/edit_task_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<ScheduleModel> _schedules = [];
  List<TaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await DbHelper.getAllSchedules();
      final tasks = await DbHelper.getAllTasks();
      setState(() {
        _schedules = schedules;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<ScheduleModel> get _selectedDaySchedules {
    return _schedules.where((s) {
      return s.date.year == _selectedDay.year &&
          s.date.month == _selectedDay.month &&
          s.date.day == _selectedDay.day;
    }).toList();
  }

  List<TaskModel> get _selectedDayTasks {
    return _tasks.where((t) {
      return t.dueDate.year == _selectedDay.year &&
          t.dueDate.month == _selectedDay.month &&
          t.dueDate.day == _selectedDay.day;
    }).toList();
  }

  Future<void> _deleteSchedule(int id) async {
    await DbHelper.deleteSchedule(id);
    _loadSchedules();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil dihapus')),
      );
    }
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await DbHelper.updateTask(updatedTask);
    _loadSchedules();
  }

  Future<void> _deleteTask(int id) async {
    await DbHelper.deleteTask(id);
    _loadSchedules();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSchedules,
          )
        ],
      ),
      body: Column(
        children: [
          // Table Calendar Widget
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Agenda Hari Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Schedules List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_selectedDaySchedules.isEmpty && _selectedDayTasks.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 64,
                              color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.5) : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada agenda hari ini',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _selectedDaySchedules.length + _selectedDayTasks.length,
                        itemBuilder: (context, index) {
                          if (index < _selectedDaySchedules.length) {
                            final schedule = _selectedDaySchedules[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Slidable(
                                key: ValueKey('schedule_${schedule.id}'),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.5,
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditScheduleScreen(schedule: schedule),
                                          ),
                                        ).then((_) => _loadSchedules());
                                      },
                                      backgroundColor: AppColors.info,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit_rounded,
                                      label: 'Edit',
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    SlidableAction(
                                      onPressed: (context) => _deleteSchedule(schedule.id!),
                                      backgroundColor: AppColors.danger,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_rounded,
                                      label: 'Hapus',
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                  ],
                                ),
                                child: ScheduleCard(
                                  schedule: schedule,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditScheduleScreen(schedule: schedule),
                                      ),
                                    ).then((_) => _loadSchedules());
                                  },
                                ),
                              ),
                            );
                          } else {
                            final taskIndex = index - _selectedDaySchedules.length;
                            final task = _selectedDayTasks[taskIndex];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Slidable(
                                key: ValueKey('task_${task.id}'),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.5,
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditTaskScreen(task: task),
                                          ),
                                        ).then((_) => _loadSchedules());
                                      },
                                      backgroundColor: AppColors.info,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit_rounded,
                                      label: 'Edit',
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    SlidableAction(
                                      onPressed: (context) => _deleteTask(task.id!),
                                      backgroundColor: AppColors.danger,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_rounded,
                                      label: 'Hapus',
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                  ],
                                ),
                                child: TaskCard(
                                  task: task,
                                  onStatusChanged: (val) => _toggleTaskStatus(task),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTaskScreen(task: task),
                                      ),
                                    ).then((_) => _loadSchedules());
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScheduleScreen(initialDate: _selectedDay),
            ),
          ).then((_) => _loadSchedules());
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
