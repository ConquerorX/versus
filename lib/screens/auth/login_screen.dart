import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/branded_text_field.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }
    ref.read(authNotifierProvider.notifier).signIn(email, pass);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo ve başlık alanı
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8956C).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'AI Ürün Karşılaştır',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2D2D34),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Hesabınıza giriş yapın',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),

              const SizedBox(height: 48),

              // E-posta alanı
              BrandedTextField(
                controller: _emailCtrl,
                label: 'E-posta',
                hint: 'ornek@mail.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // Şifre alanı
              BrandedTextField(
                controller: _passCtrl,
                label: 'Şifre',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),

              const SizedBox(height: 12),

              // Hata mesajı
              if (authState.hasError)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${authState.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Giriş butonu
              GradientButton(
                text: 'Giriş Yap',
                icon: Icons.login,
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ? null : _login,
              ),

              const SizedBox(height: 24),

              // Kayıt ol linki
              Center(
                child: TextButton(
                  onPressed: () => context.push('/register'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Hesabın yok mu? ',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Kayıt ol',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
