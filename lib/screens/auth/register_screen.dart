import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/branded_text_field.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _register() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır.')),
      );
      return;
    }
    ref.read(authNotifierProvider.notifier).register(email, pass, displayName: name);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8956C).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2D2D34),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Ücretsiz kaydol ve karşılaştırmaya başla',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 36),
              BrandedTextField(
                controller: _nameCtrl,
                label: 'Ad Soyad',
                hint: 'Emre Dural',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              BrandedTextField(
                controller: _emailCtrl,
                label: 'E-posta',
                hint: 'ornek@mail.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
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
              if (authState.hasError)
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
              const SizedBox(height: 28),
              GradientButton(
                text: 'Kayıt Ol',
                icon: Icons.how_to_reg,
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ? null : _register,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Zaten hesabın var mı? ',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Giriş yap',
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
