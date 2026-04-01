import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Hardcoded credentials
  static const _validUsername = 'Admin';
  static const _validPassword = '123456';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Brief loading animation for feel
    await Future.delayed(const Duration(milliseconds: 800));

    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1A0533),
                            Color(0xFF7B2FBE),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B2FBE).withOpacity(0.45),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('T',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFD946EF), Color(0xFF7B2FBE)],
                      ).createShader(b),
                      child: const Text('Trade99',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5)),
                    ),
                    const SizedBox(height: 4),
                    const Text('powered by GenAIlakes',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 8),
                    Text('Sign in to continue',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 14,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 48),

                    // Username field
                    _buildField(
                      controller: _usernameController,
                      hint: 'Username',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _buildField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white.withOpacity(0.35),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.rose.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.rose.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.rose, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: AppTheme.rose, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.emerald.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Secured with end-to-end encryption',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 12,
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon:
              Icon(icon, color: Colors.white.withOpacity(0.35), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => _handleLogin(),
      ),
    );
  }
}
