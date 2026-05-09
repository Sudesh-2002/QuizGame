import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Login with Email ─────────────────────────────────────────
  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        ref.read(userModelProvider.notifier).state = user;
        _goToHome();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        ref.read(userModelProvider.notifier).state = user;
        _goToHome();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Guest Mode ───────────────────────────────────────────────
  Future<void> _loginAsGuest() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInAsGuest();

      if (user != null && mounted) {
        ref.read(userModelProvider.notifier).state = user;
        _goToHome();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Header ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.quiz_rounded,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Login to continue playing',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Email Field ──────────────────────────────────
                Text('Email',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Password Field ───────────────────────────────
                Text('Password',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textHint,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (val.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                // ── Forgot Password ──────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Login Button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Divider ──────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.inputBg)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR',
                          style: GoogleFonts.poppins(
                              color: AppColors.textHint)),
                    ),
                    const Expanded(child: Divider(color: AppColors.inputBg)),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Google Sign-In Button ────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Continue with Google',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.inputBg),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Guest Button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: TextButton(
                    onPressed: _isLoading ? null : _loginAsGuest,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '👤  Play as Guest',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ── Register Link ────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Forgot Password Dialog ─────────────────────────────────────
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Reset Password',
            style: GoogleFonts.poppins(color: AppColors.textPrimary)),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'Enter your email',
            icon: Icons.email_outlined,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(authServiceProvider)
                    .sendPasswordReset(emailController.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  _showError('Reset email sent! Check your inbox.');
                }
              } catch (e) {
                _showError(e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text('Send',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Input Decoration Helper ────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint),
      prefixIcon: Icon(icon, color: AppColors.textHint),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorStyle: const TextStyle(color: AppColors.error),
    );
  }
}