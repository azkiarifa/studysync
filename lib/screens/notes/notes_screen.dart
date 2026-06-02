import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../database/db_helper.dart';
import '../../models/note_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_text.dart';
import '../../widgets/note_card.dart';
import 'add_note_screen.dart';
import 'edit_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await DbHelper.getAllNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
      _onSearchChanged();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes.where((note) {
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteNote(int id) async {
    await DbHelper.deleteNote(id);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.get('noteDeleted'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppText.get('notes'))),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppText.get('searchNotes'),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
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

          // Notes Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 72,
                          color: isDark
                              ? AppColors.darkTextSecondary.withValues(
                                  alpha: 0.5,
                                )
                              : AppColors.lightTextSecondary.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppText.get('noNotes'),
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
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return Slidable(
                        key: ValueKey(note.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.8,
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditNoteScreen(note: note),
                                  ),
                                ).then((_) => _loadNotes());
                              },
                              backgroundColor: AppColors.info,
                              foregroundColor: Colors.white,
                              icon: Icons.edit_rounded,
                              label: AppText.get('edit'),
                            ),
                            SlidableAction(
                              onPressed: (context) => _deleteNote(note.id!),
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: AppText.get('delete'),
                            ),
                          ],
                        ),
                        child: NoteCard(
                          note: note,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditNoteScreen(note: note),
                              ),
                            ).then((_) => _loadNotes());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNoteScreen()),
          ).then((_) => _loadNotes());
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
