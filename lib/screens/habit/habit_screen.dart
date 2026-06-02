import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../database/db_helper.dart';
import '../../models/habit_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../widgets/habit_card.dart';
import 'add_habit_screen.dart';
import 'edit_habit_screen.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  List<HabitModel> _habits = [];
  Map<int, List<HabitLogModel>> _habitLogs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      await DbHelper.deleteSeedHabits();
      final habits = await DbHelper.getAllHabits();
      Map<int, List<HabitLogModel>> logs = {};
      for (var h in habits) {
        logs[h.id!] = await DbHelper.getHabitLogsForHabit(h.id!);
      }
      if (mounted) {
        setState(() {
          _habits = habits;
          _habitLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

<<<<<<< HEAD
  Future<void> _toggleHabitComplete(HabitModel habit) async {
    HabitModel updatedHabit;
    if (habit.isCompletedForCurrentPeriod) {
      final newStreak = habit.streak > 0 ? habit.streak - 1 : 0;
      updatedHabit = habit.copyWith(
        streak: newStreak,
        clearLastCompleted: true,
      );
    } else {
      final now = DateTime.now();
      final newStreak = habit.wasCompletedInPreviousPeriod
          ? habit.streak + 1
          : 1;

      updatedHabit = habit.copyWith(streak: newStreak, lastCompleted: now);
    }
=======
  bool _isCompletedToday(int habitId) {
    final logs = _habitLogs[habitId] ?? [];
    final now = DateTime.now();
    return logs.any((log) => 
      log.dateCompleted.year == now.year &&
      log.dateCompleted.month == now.month &&
      log.dateCompleted.day == now.day
    );
  }
>>>>>>> 0adf14d3e21ec2ab8c2d5bc896a36b1a7417d553

  int _calculateStreak(int habitId) {
    final logs = _habitLogs[habitId] ?? [];
    if (logs.isEmpty) return 0;
    
    final sortedLogs = List<HabitLogModel>.from(logs)
      ..sort((a, b) => b.dateCompleted.compareTo(a.dateCompleted));
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    bool foundToday = false;
    
    if (_isCompletedToday(habitId)) {
      foundToday = true;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    for (var i = foundToday ? 1 : 0; i < sortedLogs.length; i++) {
        final logDate = sortedLogs[i].dateCompleted;
        if (logDate.year == checkDate.year && logDate.month == checkDate.month && logDate.day == checkDate.day) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (logDate.isBefore(DateTime(checkDate.year, checkDate.month, checkDate.day))) {
            break;
        }
    }
    return streak;
  }

  Future<void> _toggleHabitComplete(HabitModel habit) async {
    final isDone = _isCompletedToday(habit.id!);
    if (isDone) {
      await DbHelper.deleteHabitLogToday(habit.id!);
    } else {
      await DbHelper.insertHabitLog(HabitLogModel(habitId: habit.id!, dateCompleted: DateTime.now()));
    }
    _loadHabits();
  }

  Future<void> _deleteHabit(int id) async {
    await DbHelper.deleteHabit(id);
    _loadHabits();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.get('habitDeleted'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.get('habits')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHabits,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 72,
                    color: isDark
                        ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                        : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                  ),
<<<<<<< HEAD
                  const SizedBox(height: 16),
                  Text(
                    AppText.get('noHabits'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Slidable(
                    key: ValueKey(habit.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.5,
                      children: [
                        SlidableAction(
                          onPressed: (context) {
=======
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Slidable(
                        key: ValueKey(habit.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.5,
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditHabitScreen(habit: habit),
                                  ),
                                ).then((_) => _loadHabits());
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
                              onPressed: (context) => _deleteHabit(habit.id!),
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
                        child: HabitCard(
                          habit: habit,
                          isCompletedToday: _isCompletedToday(habit.id!),
                          currentStreak: _calculateStreak(habit.id!),
                          onCompleteToggle: () => _toggleHabitComplete(habit),
                          onTap: () {
>>>>>>> 0adf14d3e21ec2ab8c2d5bc896a36b1a7417d553
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditHabitScreen(habit: habit),
                              ),
                            ).then((_) => _loadHabits());
                          },
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          icon: Icons.edit_rounded,
                          label: AppText.get('edit'),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        SlidableAction(
                          onPressed: (context) => _deleteHabit(habit.id!),
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_rounded,
                          label: AppText.get('delete'),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ],
                    ),
                    child: HabitCard(
                      habit: habit,
                      onCompleteToggle: () => _toggleHabitComplete(habit),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditHabitScreen(habit: habit),
                          ),
                        ).then((_) => _loadHabits());
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddHabitScreen()),
          ).then((_) => _loadHabits());
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
