import 'dart:io';
import 'package:flutter/material.dart';
import '../services/tempest_store.dart';
import '../widgets/milim_cosmetics.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const MenuScreen({super.key, this.onProfileUpdated});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _avatarPath = '';
  String _activeBorder = 'Slime Cyan';
  bool _hasSpecialCode = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameController.text = prefs.getString('username') ?? 'Warga Tempest';
      _avatarPath = prefs.getString('avatar_path') ?? '';
      _activeBorder = prefs.getString('active_border') ?? 'Slime Cyan';
      _hasSpecialCode = prefs.getBool('has_special_code') ?? false;
    });
  }

  Future<void> _pickAvatarFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _avatarPath = picked.path);
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pengguna tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    if (_avatarPath.isNotEmpty) {
      await prefs.setString('avatar_path', _avatarPath);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onProfileUpdated?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan profil berhasil disimpan.')),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await TempestStore.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showReportInfo(String channel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saluran laporan $channel siap dihubungkan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091B29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2436),
        foregroundColor: const Color(0xFFE6F7FF),
        title: const Text(
          'Menu Tempest',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Bagian Ganti Profil (Foto/GIF dari Galeri + Nama + Simpan + Logout)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D283D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pengaturan Profil',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE6F7FF),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_hasSpecialCode) ...[
                  const MilimTitleBadge(title: 'MilimNava', fontSize: 13),
                  const SizedBox(height: 10),
                ],
                InkWell(
                  onTap: _pickAvatarFromGallery,
                  borderRadius: BorderRadius.circular(50),
                  child: MilimAvatarFrame(
                    size: 82,
                    enabled: _activeBorder == 'Milim Starlight Wing',
                    child: Container(
                    width: 82,
                    height: 82,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF38BDF8),
                        width: 2.2,
                      ),
                      color: const Color(0xFF081C2B),
                    ),
                    child: ClipOval(
                      child: _avatarPath.isNotEmpty &&
                              File(_avatarPath).existsSync()
                          ? Image.file(
                              File(_avatarPath),
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/login_logo.png',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ketuk avatar untuk pilih Foto / GIF dari Galeri',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF8FD3F4)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFFE6F7FF)),
                  decoration: InputDecoration(
                    labelText: 'Nama Pengguna',
                    labelStyle: const TextStyle(color: Color(0xFF8FD3F4)),
                    filled: true,
                    fillColor: const Color(0xFF081C2B),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1F4E6B)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF38BDF8),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18B6E8),
                      foregroundColor: const Color(0xFF061624),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Keluar Akun (Logout)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFCA5A5),
                      side: const BorderSide(color: Color(0xFF991B1B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Penjelasan Aplikasi Demo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D283D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E4661)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Versi Demo RyaaNime • Federasi Tempest',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6F7FF),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aplikasi uji coba bertema Tensei Shitara Slime Datta Ken dengan '
                  'sistem level & EXP, kustomisasi border profil serta latar belakang '
                  'komentar di halaman Quest, dan pemutar video multi-server.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFFB6DEEF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Pusat Lapor & Bantuan (WhatsApp & Gmail/Email)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D283D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E4661)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pusat Lapor & Bantuan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6F7FF),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReportInfo('WhatsApp'),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: const Color(0xFFF0FDF4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReportInfo('Gmail / Email'),
                        icon: const Icon(Icons.mail_outline, size: 18),
                        label: const Text('Gmail / Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: const Color(0xFFF0F9FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
