import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/comparison_model.dart';
import '../../services/ai_service.dart';
import '../../services/haptic_feedback_service.dart';
import '../../services/sound_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/update_service.dart';
import 'result_screen.dart';
import 'trends_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Uygulama açıldığında güncelleme kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    String displayName;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      displayName = user.displayName!;
    } else {
      final raw = user?.email?.split('@').first ?? 'Kullanıcı';
      displayName = raw[0].toUpperCase() + raw.substring(1);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════ SELAMLama ═══════
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba, $displayName',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24, fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bugün ne karşılaştırmak istersin?',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Optionally navigate to profile
                    },
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, secondaryColor],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: isDark ? const Color(0xFF2D2D34) : Colors.white, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ═══════ ANA BANNER ═══════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF2D2D34) 
                      : primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AKILLI',
                            style: GoogleFonts.dmSans(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.auto_awesome, color: primaryColor, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Her şeyi\nkarşılaştır.',
                        style: GoogleFonts.playfairDisplay(
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ürünler, şehirler, platformlar, sporcular — aklına ne gelirse.',
                      style: TextStyle(
                        color: isDark ? Colors.white.withValues(alpha: 0.55) : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ═══════ TREND KARŞILAŞTIRMALAR (MOVED UP) ═══════
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC75B5B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_fire_department, color: Color(0xFFC75B5B), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trendler',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18, fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Canlı',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TrendsScreen()));
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Tümünü Gör', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trends')
                    .orderBy('count', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _buildEmptyState(isDark,
                      icon: Icons.trending_up,
                      title: 'Henüz trend yok',
                      subtitle: 'İlk karşılaştırmayı sen yap!',
                    );
                  }

                  return SizedBox(
                    height: 120 * MediaQuery.textScalerOf(context).scale(1),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final item1 = data['item1'] as String? ?? '';
                        final item2 = data['item2'] as String? ?? '';
                        final count = (data['count'] ?? 0) as int;

                        return _buildTrendCard(
                          context: context, item1: item1, item2: item2,
                          count: count, rank: index + 1, isDark: isDark,
                          primaryColor: primaryColor, secondaryColor: secondaryColor,
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ═══════ SÜRPRİZ İKİLEM ═══════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.1),
                      secondaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: const Center(child: Text('🎲', style: TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kararsız mısın?',
                                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Yapay zeka sana rastgele uçuk bir eşleşme önersin.',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 0,
                        shadowColor: primaryColor.withValues(alpha: 0.3),
                      ),
                      onPressed: () async {
                        HapticService.heavyImpact();
                        SoundService.playDiceRoll();
                        BuildContext? dialogContext;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) {
                            dialogContext = ctx;
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2D2D34) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: primaryColor),
                                    const SizedBox(height: 16),
                                    Text('Harika bir ikilem\ndüşünülüyor...', 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13)),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                        
                        // YZ'den ikilem üret (Hata olursa fallback statik listeye düşer)
                        final pair = await AiService.generateRandomPair();
                        
                        // Önce loading'i kapat
                        if (dialogContext != null && dialogContext!.mounted) {
                          Navigator.pop(dialogContext!);
                        } else if (context.mounted) {
                          // Fallback
                          Navigator.pop(context);
                        }
                        
                        // Sonra yeni ResultScreen'i başlat
                        if (context.mounted) {
                          final future = AiService.analyzeComparison(item1Text: pair[0], item2Text: pair[1]);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ResultScreen(
                              analysisFuture: future, item1Name: pair[0], item2Name: pair[1],
                            ),
                          ));
                        }
                      },
                      child: const Text('Şansımı Dene', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ═══════ SON KARŞILAŞTIRMALAR ═══════
              Text(
                'Son Karşılaştırmalar',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('comparisons')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                      ));
                    }

                    if (snapshot.hasError) {
                      return _buildEmptyState(isDark,
                        icon: Icons.cloud_off,
                        title: 'Veriler yüklenemedi',
                        subtitle: 'Index oluşturulduysa biraz bekleyin.',
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return _buildEmptyState(isDark,
                        icon: Icons.search_off,
                        title: 'Henüz karşılaştırma yok',
                        subtitle: 'Yukarıdaki hızlı başlat ile deneyin!',
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final comp = ComparisonModel.fromMap(doc.id, data);
                        final day = comp.createdAt.day.toString().padLeft(2, '0');
                        final month = comp.createdAt.month.toString().padLeft(2, '0');
                        final dateStr = '$day.$month.${comp.createdAt.year}';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(
                                  markdownResult: comp.result,
                                  item1Name: comp.item1,
                                  item2Name: comp.item2,
                                  autoSave: false,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2D2D34) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFE8E4DF),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.compare_arrows, color: primaryColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${comp.item1} vs ${comp.item2}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                )
              else
                _buildEmptyState(isDark,
                  icon: Icons.login,
                  title: 'Giriş yapın',
                  subtitle: 'Karşılaştırmalarınızı görmek için giriş yapın.',
                ),

              const SizedBox(height: 28),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════ WIDGETS ═══════

  Widget _buildTrendCard({
    required BuildContext context,
    required String item1,
    required String item2,
    required int count,
    required int rank,
    required bool isDark,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return GestureDetector(
      onTap: () async {
        BuildContext? dialogContext;
        // Loading göster
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return Center(child: CircularProgressIndicator(color: primaryColor));
          },
        );

        // Veritabanından mevcut karşılaştırmayı bulmaya çalış
        final query1 = await FirebaseFirestore.instance.collection('comparisons')
            .where('item1', isEqualTo: item1)
            .where('item2', isEqualTo: item2)
            .limit(1)
            .get();
            
        QueryDocumentSnapshot? existingDoc;
        if (query1.docs.isNotEmpty) {
          existingDoc = query1.docs.first;
        } else {
          final query2 = await FirebaseFirestore.instance.collection('comparisons')
              .where('item1', isEqualTo: item2)
              .where('item2', isEqualTo: item1)
              .limit(1)
              .get();
          if (query2.docs.isNotEmpty) {
            existingDoc = query2.docs.first;
          }
        }

        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.pop(dialogContext!); // loading kapat
        } else if (context.mounted) {
          Navigator.pop(context);
        }
          
        if (context.mounted) {
          if (existingDoc != null) {
            final data = existingDoc.data() as Map<String, dynamic>;
            final comp = ComparisonModel.fromMap(existingDoc.id, data);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ResultScreen(
                markdownResult: comp.result,
                item1Name: comp.item1,
                item2Name: comp.item2,
                autoSave: false, // Zaten kayıtlı
              ),
            ));
          } else {
            // Bulunamazsa yeni üret
            final future = AiService.analyzeComparison(item1Text: item1, item2Text: item2);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ResultScreen(
                analysisFuture: future, item1Name: item1, item2Name: item2,
              ),
            ));
          }
        }
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D34) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFE8E4DF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? primaryColor.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: rank <= 3 ? primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 3),
                Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            Text(
              '$item1 vs $item2',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('$count karşılaştırma', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFE8E4DF),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[500]), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
