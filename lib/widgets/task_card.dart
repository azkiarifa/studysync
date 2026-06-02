import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../utils/date_helper.dart';
import '../screens/study_session/add_session_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Function(bool?) onStatusChanged;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color priorityColor;
    switch (task.priority.toLowerCase()) {
      case 'high':
        priorityColor = AppColors.danger;
        break;
      case 'medium':
        priorityColor = AppColors.warning;
        break;
      default:
        priorityColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: onStatusChanged,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.priority,
                            style: TextStyle(
                              fontSize: 11,
                              color: priorityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Due Date Info
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateHelper.formatShortDate(task.dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (task.scheduleId != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Terkait jadwal',
                            style: TextStyle(fontSize: 11, color: AppColors.primary),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // Start Study Session button
                        IconButton(
                          tooltip: 'Mulai Sesi Belajar',
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          color: AppColors.primary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddSessionScreen(
                                  initialTaskId: task.id,
                                  initialSubject: task.title,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
