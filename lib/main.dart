import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/accessibility_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gRouter = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(accentColorProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final boldText = ref.watch(boldTextProvider);
    final isHighContrast = ref.watch(highContrastProvider);

    return MaterialApp.router(
      title: 'AI Ürün Karşılaştır',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(
        palette.primary, 
        palette.tertiary, 
        isHighContrast: isHighContrast,
      ),
      darkTheme: AppTheme.darkTheme(
        palette.primary, 
        palette.tertiary, 
        isHighContrast: isHighContrast,
      ),
      themeMode: themeMode,
      routerConfig: gRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale),
            boldText: boldText,
            highContrast: isHighContrast,
          ),
          child: child!,
        );
      },
    );
  }
}

