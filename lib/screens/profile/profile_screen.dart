import 'package:flutter/material.dart';
import '../../services/sharedpref_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  
  String _selectedSemester = 'Semester 4';
  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  // List of pre-defined avatar images paths (mocking profile images)
  String _selectedAvatar = '';
  final List<String> _avatars = [
    'assets/images/avatar_1.png',
    'assets/images/avatar_2.png',
    'assets/images/avatar_3.png',
    'assets/images/avatar_4.png',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController.text = SharedPrefService.username;
    _selectedSemester = SharedPrefService.semester;
    _selectedAvatar = SharedPrefService.profileImage;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await SharedPrefService.setUsername(_usernameController.text.trim());
      await SharedPrefService.setSemester(_selectedSemester);
      await SharedPrefService.setProfileImage(_selectedAvatar);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Avatar Picker Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: _selectedAvatar.isEmpty
                        ? const Icon(Icons.person_rounded, size: 64, color: AppColors.primary)
                        : const Icon(Icons.account_circle_rounded, size: 100, color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form inputs
            CustomTextField(
              controller: _usernameController,
              labelText: 'Nama Pengguna',
              hintText: 'Arif...',
              prefixIcon: Icons.badge_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Semester Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSemester,
              decoration: InputDecoration(
                labelText: 'Semester Aktif',
                prefixIcon: const Icon(Icons.school_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              items: _semesters.map((String sem) {
                return DropdownMenuItem<String>(
                  value: sem,
                  child: Text(sem),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedSemester = newValue);
                }
              },
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Simpan Profil',
              onTap: _saveProfile,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
