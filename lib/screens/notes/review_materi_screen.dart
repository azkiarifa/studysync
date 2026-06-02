import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helper.dart';

class ReviewMateriScreen extends StatefulWidget {
  const ReviewMateriScreen({super.key});

  @override
  State<ReviewMateriScreen> createState() => _ReviewMateriScreenState();
}

class _ReviewMateriScreenState extends State<ReviewMateriScreen> {
  static const String _reviewsKey = 'review_materi_cards';
  static const List<int> _cardColors = [
    0xFFFFEDD5,
    0xFFE0F2FE,
    0xFFF3E8FF,
    0xFFDCFCE7,
    0xFFFFE4E6,
  ];

  final _searchController = TextEditingController();
  List<_ReviewMateri> _reviews = [];
  List<_ReviewMateri> _filteredReviews = [];
  bool _isLoading = true;

  int get _totalSubMateri =>
      _reviews.fold(0, (total, review) => total + review.subMateri.length);

  int get _completedSubMateri => _reviews.fold(
    0,
    (total, review) =>
        total + review.subMateri.where((item) => item.isDone).length,
  );

  double get _reviewProgress =>
      _totalSubMateri == 0 ? 0 : _completedSubMateri / _totalSubMateri;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_reviewsKey);

    List<_ReviewMateri> reviews = [];
    if (rawJson != null) {
      try {
        final decoded = json.decode(rawJson) as List<dynamic>;
        reviews = decoded
            .map(
              (item) => _ReviewMateri.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList();
      } catch (_) {
        reviews = [];
      }
    }

    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
    _onSearchChanged();
  }

  Future<void> _saveReviews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reviewsKey,
      json.encode(_reviews.map((review) => review.toMap()).toList()),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReviews = _reviews;
      } else {
        _filteredReviews = _reviews.where((review) {
          final subMateriMatch = review.subMateri.any(
            (item) => item.title.toLowerCase().contains(query),
          );

          return review.title.toLowerCase().contains(query) ||
              review.content.toLowerCase().contains(query) ||
              subMateriMatch;
        }).toList();
      }
    });
  }

  Future<void> _showReviewDialog({_ReviewMateri? review}) async {
    final titleController = TextEditingController(text: review?.title ?? '');
    final contentController = TextEditingController(
      text: review?.content ?? '',
    );

    final result = await showDialog<_ReviewMateriInput>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: Text(review == null ? 'Tambah Materi' : 'Edit Materi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: _dialogInputDecoration(
                  isDark,
                  'Judul materi',
                  Icons.menu_book_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                minLines: 3,
                maxLines: 5,
                decoration: _dialogInputDecoration(
                  isDark,
                  'Catatan singkat',
                  Icons.notes_rounded,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                Navigator.pop(
                  context,
                  _ReviewMateriInput(
                    title: title,
                    content: contentController.text.trim(),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    contentController.dispose();
    if (result == null) return;

    setState(() {
      if (review == null) {
        final index = _reviews.length % _cardColors.length;
        _reviews.insert(
          0,
          _ReviewMateri(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: result.title,
            content: result.content,
            createdAt: DateTime.now(),
            color: _cardColors[index],
            subMateri: const [],
          ),
        );
      } else {
        final index = _reviews.indexWhere((item) => item.id == review.id);
        if (index != -1) {
          _reviews[index] = review.copyWith(
            title: result.title,
            content: result.content,
          );
        }
      }
    });
    _onSearchChanged();
    await _saveReviews();
  }

  InputDecoration _dialogInputDecoration(
    bool isDark,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDark ? AppColors.darkCard : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> _showAddSubMateriDialog(_ReviewMateri review) async {
    final controller = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: const Text('Tambah Sub Materi'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: _dialogInputDecoration(
              isDark,
              'Contoh: Routing statis',
              Icons.playlist_add_rounded,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (title == null || title.isEmpty) return;

    _updateReview(
      review.id,
      (item) => item.copyWith(
        subMateri: [
          ...item.subMateri,
          _ReviewSubMateri(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            isDone: false,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSubMateri(_ReviewMateri review, String itemId) async {
    _updateReview(
      review.id,
      (item) => item.copyWith(
        subMateri: item.subMateri.map((subMateri) {
          if (subMateri.id != itemId) return subMateri;
          return subMateri.copyWith(isDone: !subMateri.isDone);
        }).toList(),
      ),
    );
  }

  Future<void> _deleteSubMateri(_ReviewMateri review, String itemId) async {
    _updateReview(
      review.id,
      (item) => item.copyWith(
        subMateri: item.subMateri
            .where((subMateri) => subMateri.id != itemId)
            .toList(),
      ),
    );
  }

  Future<void> _updateReview(
    String reviewId,
    _ReviewMateri Function(_ReviewMateri review) update,
  ) async {
    setState(() {
      final index = _reviews.indexWhere((review) => review.id == reviewId);
      if (index == -1) return;
      _reviews[index] = update(_reviews[index]);
    });
    _onSearchChanged();
    await _saveReviews();
  }

  Future<void> _deleteReview(String id) async {
    setState(() {
      _reviews.removeWhere((review) => review.id == id);
    });
    _onSearchChanged();
    await _saveReviews();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review materi berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = (_reviewProgress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Materi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari materi review...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: _inputBorder(isDark),
                enabledBorder: _inputBorder(isDark),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReviews.isEmpty
                ? _buildEmptyState(isDark)
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                    itemCount: _filteredReviews.length,
                    itemBuilder: (context, index) {
                      final review = _filteredReviews[index];

                      return Slidable(
                        key: ValueKey(review.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.8,
                          children: [
                            SlidableAction(
                              onPressed: (context) =>
                                  _showReviewDialog(review: review),
                              backgroundColor: AppColors.info,
                              foregroundColor: Colors.white,
                              icon: Icons.edit_rounded,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (context) => _deleteReview(review.id),
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'Hapus',
                            ),
                          ],
                        ),
                        child: _ReviewMateriCard(
                          review: review,
                          onAddSubMateri: () => _showAddSubMateriDialog(review),
                          onToggleSubMateri: (itemId) =>
                              _toggleSubMateri(review, itemId),
                          onDeleteSubMateri: (itemId) =>
                              _deleteSubMateri(review, itemId),
                          onTap: () => _showReviewDialog(review: review),
                        ),
                      );
                    },
                  ),
          ),
          _buildProgressPanel(isDark, percent),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReviewDialog(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  OutlineInputBorder _inputBorder(bool isDark) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 72,
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                : AppColors.lightTextSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada materi review',
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
    );
  }

  Widget _buildProgressPanel(bool isDark, int percent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$_completedSubMateri/$_totalSubMateri sub materi',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _reviewProgress,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.darkBg
                  : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percent% sub materi sudah direview',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewMateriCard extends StatelessWidget {
  final _ReviewMateri review;
  final VoidCallback onAddSubMateri;
  final ValueChanged<String> onToggleSubMateri;
  final ValueChanged<String> onDeleteSubMateri;
  final VoidCallback onTap;

  const _ReviewMateriCard({
    required this.review,
    required this.onAddSubMateri,
    required this.onToggleSubMateri,
    required this.onDeleteSubMateri,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reviewColor = Color(review.color);
    final luminance = reviewColor.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black87 : Colors.white;
    final textSecondaryColor = luminance > 0.5
        ? Colors.black54
        : Colors.white70;
    final completedCount = review.subMateri.where((item) => item.isDone).length;
    final cardProgress = review.subMateri.isEmpty
        ? 0.0
        : completedCount / review.subMateri.length;

    return Card(
      color: reviewColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cardProgress == 1 && review.subMateri.isNotEmpty
              ? AppColors.success
              : Colors.black.withValues(alpha: 0.05),
          width: cardProgress == 1 && review.subMateri.isNotEmpty ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    child: Text(
                      review.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onAddSubMateri,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: Icon(
                    Icons.add_circle_rounded,
                    color: textColor,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review.content.isEmpty ? 'Belum ada catatan' : review.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: textSecondaryColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: cardProgress,
                      minHeight: 6,
                      backgroundColor: textSecondaryColor.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedCount/${review.subMateri.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: review.subMateri.isEmpty
                  ? Center(
                      child: TextButton.icon(
                        onPressed: onAddSubMateri,
                        icon: const Icon(Icons.playlist_add_rounded, size: 18),
                        label: const Text('Sub materi'),
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: review.subMateri.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = review.subMateri[index];

                        return _SubMateriRow(
                          item: item,
                          textColor: textColor,
                          textSecondaryColor: textSecondaryColor,
                          onToggle: () => onToggleSubMateri(item.id),
                          onDelete: () => onDeleteSubMateri(item.id),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 13,
                  color: textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  DateHelper.formatShortDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubMateriRow extends StatelessWidget {
  final _ReviewSubMateri item;
  final Color textColor;
  final Color textSecondaryColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SubMateriRow({
    required this.item,
    required this.textColor,
    required this.textSecondaryColor,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggle,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: Icon(
              item.isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.isDone ? AppColors.success : textSecondaryColor,
              size: 19,
            ),
          ),
          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: item.isDone ? textSecondaryColor : textColor,
                decoration: item.isDone ? TextDecoration.lineThrough : null,
                decorationColor: textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 30),
            icon: Icon(
              Icons.close_rounded,
              color: textSecondaryColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewMateriInput {
  final String title;
  final String content;

  const _ReviewMateriInput({required this.title, required this.content});
}

class _ReviewMateri {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int color;
  final List<_ReviewSubMateri> subMateri;

  const _ReviewMateri({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.color,
    required this.subMateri,
  });

  _ReviewMateri copyWith({
    String? title,
    String? content,
    List<_ReviewSubMateri>? subMateri,
  }) {
    return _ReviewMateri(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      color: color,
      subMateri: subMateri ?? this.subMateri,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'subMateri': subMateri.map((item) => item.toMap()).toList(),
    };
  }

  factory _ReviewMateri.fromMap(Map<String, dynamic> map) {
    return _ReviewMateri(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      color: map['color'] as int,
      subMateri: ((map['subMateri'] as List<dynamic>?) ?? [])
          .map(
            (item) => _ReviewSubMateri.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class _ReviewSubMateri {
  final String id;
  final String title;
  final bool isDone;

  const _ReviewSubMateri({
    required this.id,
    required this.title,
    required this.isDone,
  });

  _ReviewSubMateri copyWith({bool? isDone}) {
    return _ReviewSubMateri(
      id: id,
      title: title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'isDone': isDone};
  }

  factory _ReviewSubMateri.fromMap(Map<String, dynamic> map) {
    return _ReviewSubMateri(
      id: map['id'] as String,
      title: map['title'] as String,
      isDone: map['isDone'] as bool? ?? false,
    );
  }
}
