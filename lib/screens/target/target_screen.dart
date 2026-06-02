import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../database/db_helper.dart';
import '../../models/target_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import 'add_target_screen.dart';
import 'edit_target_screen.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  List<TargetModel> _targets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    setState(() => _isLoading = true);
    try {
      final targets = await DbHelper.getAllTargets();
      setState(() {
        _targets = targets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTarget(int id) async {
    await DbHelper.deleteTarget(id);
    _loadTargets();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.get('targetDeleted'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.get('courseTarget')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTargets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _targets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 72,
                    color: isDark
                        ? AppColors.darkTextSecondary.withOpacity(0.5)
                        : AppColors.lightTextSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppText.get('noTargets'),
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
              itemCount: _targets.length,
              itemBuilder: (context, index) {
                final target = _targets[index];
                final progress = (target.currentScore / target.targetScore)
                    .clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Slidable(
                    key: ValueKey(target.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.5,
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditTargetScreen(target: target),
                              ),
                            ).then((_) => _loadTargets());
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
                          onPressed: (context) => _deleteTarget(target.id!),
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
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditTargetScreen(target: target),
                            ),
                          ).then((_) => _loadTargets());
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      target.courseName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${AppText.get('target')}: ${target.targetGrade}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${AppText.get('currentScore')}: ${target.currentScore.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${AppText.get('targetScoreLabel')}: ${target.targetScore.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: isDark
                                      ? AppColors.darkBg
                                      : const Color(0xFFF1F5F9),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                ),
                              ),
                              if (target.notes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  target.notes,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                              .withOpacity(0.8)
                                        : AppColors.lightTextSecondary
                                              .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTargetScreen()),
          ).then((_) => _loadTargets());
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
