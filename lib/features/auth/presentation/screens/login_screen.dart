import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/animated_cricket_logo.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _f = GlobalKey<FormState>();
  final _e = TextEditingController();
  final _p = TextEditingController();
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _e.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authControllerProvider.notifier)
        .signIn(email: _e.text, password: _p.text);
    if (!mounted || ok) return;
    
    final errorState = ref.read(authControllerProvider).error;
    final errorMsg = errorState?.toString() ?? 'Invalid credentials';
    
    String displayError = errorMsg;
    if (errorMsg.contains('email_not_confirmed') || errorMsg.contains('Email not confirmed')) {
      displayError = 'Please check your Gmail and click the confirmation link before logging in, or turn off Confirm email in Supabase.';
    } else if (errorMsg.contains('invalid_credentials') || errorMsg.contains('Invalid login credentials')) {
      displayError = 'Incorrect email or password. If you haven\'t registered in Supabase yet, please click Register below.';
    } else if (errorMsg.contains('user-not-found')) {
      displayError = 'No account found with this email/phone.';
    } else if (errorMsg.contains('wrong-password') || errorMsg.contains('invalid-credential')) {
      displayError = 'Incorrect password.';
    } else if (errorMsg.contains('invalid-email')) {
      displayError = 'Invalid email format.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayError), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    const darkBlue = Color(0xFF1E3A8A);
    const midBlue = Color(0xFF2563EB);
    const accentGold = Color(0xFFFFB300);
    const cream = Color(0xFFF8FAFC);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  physics: constraints.maxHeight >= 600
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: 440,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ─── Continuous Animated Logo ───
                                const AnimatedCricketLogo(size: 115),
                                const SizedBox(height: 16),

                              // ─── App Title ───
                              const Text(
                                'BORIGIVALASA',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentGold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'CRICKET',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ─── Card ───
                              Container(
                                decoration: BoxDecoration(
                                  color: cream,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 32,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(26),
                        child: Form(
                          key: _f,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: midBlue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.sports_cricket,
                                        color: midBlue, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Welcome Back!',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: darkBlue)),
                                      Text('Sign in to continue',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Phone/Email field
                              _buildField(
                                controller: _e,
                                hint: 'Email or Phone Number',
                                icon: Icons.person_outline,
                                keyboard: TextInputType.emailAddress,
                                accent: midBlue,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.contains('@')) return null;
                                  if (v.length < 10) return 'Enter valid 10-digit number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _p,
                                obscureText: _obscure,
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: midBlue, width: 2),
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                        color: midBlue, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Login Button
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: midBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    elevation: 4,
                                    shadowColor: midBlue.withOpacity(0.5),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login, size: 20),
                                            SizedBox(width: 8),
                                            Text('Login',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1)),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Sign up
                              Center(
                                child: InkWell(
                                  onTap: () => context.go('/signup'),
                                  child: RichText(
                                    text: const TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(color: Colors.black54, fontSize: 13),
                                      children: [
                                        TextSpan(
                                          text: 'Register',
                                          style: TextStyle(
                                              color: midBlue,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Bottom pitch lines decoration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == 2 ? 40 : 20,
                            height: 3,
                            decoration: BoxDecoration(
                              color: i == 2
                                  ? accentGold
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // App developer credit
                      const Text(
                        'App developed by Rajesh Kinjarapu',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  },
),
          ),
        ),
      );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color accent,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
