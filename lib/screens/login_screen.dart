import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final secretCode = _secretCodeController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi Nama Warga / Username dan Kata Sandi terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    if (secretCode.isNotEmpty) {
      await prefs.setString('secret_code', secretCode);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2133),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradasi biru-cyan lembut bertema Slime
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0E3552),
                  Color(0xFF0A2338),
                  Color(0xFF081B2C),
                ],
              ),
            ),
          ),

          // Overlay karakter di latar belakang
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.34,
                child: Image.asset(
                  'assets/images/login_overlay.png',
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Lapisan gradasi halus agar teks form tetap terbaca jelas
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A2338).withValues(alpha: 0.25),
                  const Color(0xFF091E30).withValues(alpha: 0.72),
                  const Color(0xFF071726).withValues(alpha: 0.90),
                ],
              ),
            ),
          ),

          // Form digeser lebih ke bawah
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 128, 20, 28),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D283D).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF05111C).withValues(alpha: 0.55),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo pengganti ikon gelembung
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF133B59),
                        border: Border.all(
                          color: const Color(0xFF38BDF8),
                          width: 1.8,
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/login_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'RYAANIME',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFFE6F7FF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Gerbang Federasi Jura Tempest',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF8FD3F4),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tombol Masuk / Daftar Baru
                    Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            label: 'Masuk',
                            active: !_isRegisterMode,
                            onTap: () => setState(() => _isRegisterMode = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModeButton(
                            label: 'Daftar Baru',
                            active: _isRegisterMode,
                            onTap: () => setState(() => _isRegisterMode = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nama Warga / Username
                    _InputField(
                      controller: _usernameController,
                      hintText: 'Nama Warga / Username',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),

                    // Kata Sandi
                    _InputField(
                      controller: _passwordController,
                      hintText: 'Kata Sandi',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF8FD3F4),
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kode Khusus (Opsional) di halaman Login
                    _InputField(
                      controller: _secretCodeController,
                      hintText: 'Kode Khusus (Opsional)',
                      icon: Icons.vpn_key_outlined,
                    ),
                    const SizedBox(height: 18),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18B6E8),
                          foregroundColor: const Color(0xFF061624),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF061624),
                                ),
                              )
                            : Text(
                                _isRegisterMode
                                    ? 'DAFTAR KE TEMPEST'
                                    : 'MASUK KE TEMPEST',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF18B6E8) : const Color(0xFF0A1F30),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active ? const Color(0xFF38BDF8) : const Color(0xFF214A66),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF061624) : const Color(0xFFB6DEEF),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Color(0xFFE6F7FF), fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF7FAEC4), fontSize: 13.5),
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF081C2B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E4661)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
      ),
    );
  }
}
