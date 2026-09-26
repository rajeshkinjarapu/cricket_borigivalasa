import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/animated_cricket_logo.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _f = GlobalKey<FormState>();
  final _n = TextEditingController(); // Full Name
  final _e = TextEditingController(); // Mobile Number (mapped to identifier)
  final _p = TextEditingController(); // Password
  bool _o = true;
  bool _agreed = false;

  @override
  void dispose() {
    _n.dispose();
    _e.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms and Conditions')));
      return;
    }
    FocusScope.of(context).unfocus();
    
    final success = await ref.read(authControllerProvider.notifier)
      .signUp(email: _e.text, password: _p.text, displayName: _n.text);
      
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signup successful! Please log in with your details.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    } else if (mounted) {
      final errorState = ref.read(authControllerProvider).error;
      final errorMsg = errorState?.toString() ?? 'Registration failed. Please try again.';
      // Clean up Firebase exception messages to be user-friendly
      String displayError = errorMsg;
      if (errorMsg.contains('email-already-in-use')) displayError = 'This email/phone is already registered. Please login.';
      else if (errorMsg.contains('invalid-email')) displayError = 'Please enter a valid email or phone number.';
      else if (errorMsg.contains('weak-password')) displayError = 'Password is too weak. Please use a stronger password.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    const midBlue = Color(0xFF2563EB);
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        suffixIcon: suffix,
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
      validator: validator,
    );
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
                  physics: constraints.maxHeight >= 680
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ─── Continuous Animated Logo ───
                            const AnimatedCricketLogo(size: 110),
                            const SizedBox(height: 14),

                            // App Title
                            const Text(
                              'CRICKET BV',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'BORIGIVALASA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                    child: Form(
                      key: _f,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: midBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_add,
                                    color: midBlue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create Account',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: darkBlue)),
                                  Text('Register to continue',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Full Name
                          _buildField(
                            controller: _n,
                            hint: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'Enter your full name'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Email or Phone Number
                          _buildField(
                            controller: _e,
                            hint: 'Email or Phone Number',
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.contains('@')) return null;
                              if (v.length < 10) return 'Enter valid 10-digit number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildField(
                            controller: _p,
                            hint: 'New Password',
                            icon: Icons.lock_outline,
                            obscure: _o,
                            suffix: IconButton(
                              icon: Icon(
                                _o ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () => setState(() => _o = !_o),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Min 6 chars required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Terms Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreed,
                                  onChanged: (v) => setState(() => _agreed = v ?? false),
                                  activeColor: midBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'I agree with the ',
                                    style: TextStyle(color: Colors.black54, fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: 'Terms and Conditions',
                                        style: TextStyle(
                                            color: midBlue,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                            color: midBlue,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Register Button
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
                                        Icon(Icons.person_add_alt_1, size: 20),
                                        SizedBox(width: 8),
                                        Text('Register',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Back to login
                          Center(
                            child: InkWell(
                              onTap: () => context.go('/login'),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Have an account? ',
                                  style: TextStyle(color: Colors.black54, fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: 'Sign in',
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
                ],
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
}
