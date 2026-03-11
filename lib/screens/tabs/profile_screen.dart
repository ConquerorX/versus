import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İsim Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Yeni isminiz',
            labelText: 'İsim',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(authNotifierProvider.notifier).updateProfileName(newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = user?.email ?? 'Bilinmeyen';
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentPalette = ref.watch(accentColorProvider);
    final fontScale = ref.watch(fontScaleProvider);

    // Get comparison count stream
    final comparisonStream = user != null 
        ? FirebaseFirestore.instance.collection('comparisons').where('userId', isEqualTo: user.uid).snapshots() 
        : const Stream.empty();

    String displayName;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      displayName = user.displayName!;
    } else {
      final raw = email.split('@').first;
      displayName = raw[0].toUpperCase() + raw.substring(1);
    }
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    String themeModeText = 'Sistem';
    switch (currentThemeMode) {
      case ThemeMode.system: themeModeText = 'Sistem';
      case ThemeMode.light: themeModeText = 'Açık';
      case ThemeMode.dark: themeModeText = 'Koyu';
    }

    String fontSizeText;
    if (fontScale <= 0.85) {
      fontSizeText = 'Küçük';
    } else if (fontScale <= 1.05) {
      fontSizeText = 'Standart';
    } else if (fontScale <= 1.25) {
      fontSizeText = 'Büyük';
    } else if (fontScale <= 1.45) {
      fontSizeText = 'Çok Büyük';
    } else {
      fontSizeText = 'En Büyük';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Kullanıcı bilgisi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D34) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showEditNameDialog(context, ref, displayName),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [currentPalette.primary, currentPalette.light],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: currentPalette.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: isDark ? const Color(0xFF2D2D34) : Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3A3A42) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF2D2D34) : Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.edit, size: 14, color: currentPalette.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      email,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats row
                  StreamBuilder(
                    stream: comparisonStream,
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? (snapshot.data as QuerySnapshot).docs.length : 0;
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatColumn('İnceleme', count.toString(), isDark),
                            Container(width: 1, height: 30, color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 24)),
                            _buildStatColumn('Seviye', count > 10 ? 'Uzman' : 'Çaylak', isDark),
                            Container(width: 1, height: 30, color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 24)),
                            _buildStatColumn('Beğeni', '${count * 2}', isDark),
                          ],
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sadece Admin Hesabında Görünen Panel
            if (email == 'e.duralemre+admin@gmail.com')
              _buildSettingsSection(
                context,
                ref,
                title: 'Sistem Yönetimi',
                items: [
                  _SettingsItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Paneli (God Mode)',
                    subtitle: 'Tüm kullanıcıların verilerini kontrol et',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                    },
                  ),
                ],
              ),

            // Özelleştirme
            _buildSettingsSection(
              context,
              ref,
              title: 'Özelleştirme',
              items: [
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Görünüm Teması',
                  subtitle: themeModeText,
                  onTap: () {
                    _showThemePicker(context, ref, currentThemeMode);
                  },
                ),
                _SettingsItem(
                  icon: Icons.color_lens_outlined,
                  title: 'Tema Rengi',
                  subtitle: currentPalette.label,
                  trailing: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: currentPalette.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 2),
                    ),
                  ),
                  onTap: () {
                    _showColorPicker(context, ref, currentPalette);
                  },
                ),
              ],
            ),

            // Erişilebilirlik
            _buildSettingsSection(
              context,
              ref,
              title: 'Erişilebilirlik',
              items: [
                _SettingsItem(
                  icon: Icons.format_size,
                  title: 'Yazı Tipi Boyutu',
                  subtitle: fontSizeText,
                  onTap: () {
                    _showFontSizePicker(context, ref);
                  },
                ),
                _SettingsItem(
                  icon: Icons.contrast,
                  title: 'Yüksek Kontrast',
                  subtitle: ref.watch(highContrastProvider) ? 'Açık' : 'Kapalı',
                  trailing: Switch.adaptive(
                    value: ref.watch(highContrastProvider),
                    activeTrackColor: currentPalette.primary,
                    onChanged: (_) => ref.read(highContrastProvider.notifier).toggle(),
                  ),
                  onTap: () {
                    ref.read(highContrastProvider.notifier).toggle();
                  },
                ),
                _SettingsItem(
                  icon: Icons.format_bold,
                  title: 'Kalın Yazı',
                  subtitle: ref.watch(boldTextProvider) ? 'Açık' : 'Kapalı',
                  trailing: Switch.adaptive(
                    value: ref.watch(boldTextProvider),
                    activeTrackColor: currentPalette.primary,
                    onChanged: (_) => ref.read(boldTextProvider.notifier).toggle(),
                  ),
                  onTap: () {
                    ref.read(boldTextProvider.notifier).toggle();
                  },
                ),
              ],
            ),

            // Bildirimler
            _buildSettingsSection(
              context,
              ref,
              title: 'Bildirimler',
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Bildirimler',
                  subtitle: 'Açık',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirim ayarları çok yakında!')));
                  },
                ),
              ],
            ),

            // Destek
            _buildSettingsSection(
              context,
              ref,
              title: 'Destek ve Bilgi',
              items: [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Yardım Merkezi',
                  subtitle: 'Sık sorulan sorular',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yardım merkezi yükleniyor...')));
                  },
                ),
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'Uygulama Hakkında',
                  subtitle: 'Sürüm 1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'AI Ürün Karşılaştır',
                      applicationVersion: '1.0.0',
                      children: [
                        const Text('Yapay zeka destekli ürün karşılaştırma uygulaması.'),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSettingsSection(
              context,
              ref,
              title: 'Hesap',
              items: [
                _SettingsItem(
                  icon: Icons.logout,
                  title: 'Çıkış Yap',
                  subtitle: 'Hesabınızdan çıkış yapın',
                  isDestructive: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text('Hesabınızdan çıkış yapmak istiyor musunuz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref.read(authNotifierProvider.notifier).signOut();
                            },
                            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'AI Ürün Karşılaştır v1.0.0\nCrafted with ❤️',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Tema Modu Seçimi (Sistem / Açık / Koyu)
  // ═══════════════════════════════════════════════
  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tema Seçimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              _themeOption(ctx, ref, Icons.brightness_auto, 'Sistem', 'Cihaz ayarlarını takip et', ThemeMode.system, current),
              _themeOption(ctx, ref, Icons.light_mode, 'Açık', 'Aydınlık tema', ThemeMode.light, current),
              _themeOption(ctx, ref, Icons.dark_mode, 'Koyu', 'Karanlık tema', ThemeMode.dark, current),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, WidgetRef ref, IconData icon, String title, String subtitle, ThemeMode mode, ThemeMode current) {
    final isSelected = mode == current;
    final accent = ref.watch(accentColorProvider).primary;
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (isSelected ? accent : Colors.grey).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? accent : Colors.grey, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: isSelected ? Icon(Icons.check_circle, color: accent) : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  // ═══════════════════════════════════════════════
  // Tema Renk Paleti Seçimi
  // ═══════════════════════════════════════════════
  void _showColorPicker(BuildContext context, WidgetRef ref, AccentPalette current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tema Rengi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Uygulamanın ana rengini seçin',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: AccentPalette.values.map((palette) {
                  final isSelected = palette == current;
                  return GestureDetector(
                    onTap: () {
                      ref.read(accentColorProvider.notifier).setPalette(palette);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.primary.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF2D2D34) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? palette.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [palette.primary, palette.light],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            palette.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? palette.primary : (isDark ? Colors.grey[400] : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Yazı Boyutu Ayarı
  // ═══════════════════════════════════════════════
  void _showFontSizePicker(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.read(accentColorProvider).primary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            final currentScale = ref.watch(fontScaleProvider);
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Yazı Boyutu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Uygulamadaki yazıların boyutunu ayarlayın',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Önizleme
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2D34) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Önizleme Metni',
                            style: TextStyle(
                              fontSize: 18 * currentScale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bu yazı seçtiğiniz boyutta görünecektir.',
                            style: TextStyle(
                              fontSize: 14 * currentScale,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Slider
                    Row(
                      children: [
                        Text('A', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: accent,
                              thumbColor: accent,
                              inactiveTrackColor: accent.withValues(alpha: 0.15),
                              overlayColor: accent.withValues(alpha: 0.1),
                            ),
                            child: Slider(
                              value: currentScale,
                              min: 0.8,
                              max: 1.6,
                              divisions: 4,
                              label: _fontScaleLabel(currentScale),
                              onChanged: (val) {
                                ref.read(fontScaleProvider.notifier).setScale(val);
                              },
                            ),
                          ),
                        ),
                        Text('A', style: TextStyle(fontSize: 22, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fontScaleLabel(currentScale),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _fontScaleLabel(double scale) {
    if (scale <= 0.85) return 'Küçük';
    if (scale <= 1.05) return 'Standart';
    if (scale <= 1.25) return 'Büyük';
    if (scale <= 1.45) return 'Çok Büyük';
    return 'En Büyük';
  }

  // ═══════════════════════════════════════════════
  // Ayar Bölümü Builder
  // ═══════════════════════════════════════════════
  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500]),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D34) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final accent = ref.watch(accentColorProvider).primary;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (item.isDestructive ? Colors.red : accent).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: item.isDestructive ? Colors.red : accent,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: item.isDestructive ? Colors.red : null,
                      ),
                    ),
                    subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: item.trailing ?? Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                    onTap: item.onTap,
                  ),
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 70, color: isDark ? const Color(0xFF3A3A42) : Colors.grey[100]),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });
}
