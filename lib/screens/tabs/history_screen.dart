import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comparison_model.dart';
import 'result_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<QueryDocumentSnapshot> docs) {
    setState(() {
      if (_selectedIds.length == docs.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.clear();
        for (final doc in docs) {
          _selectedIds.add(doc.id);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${_selectedIds.length} karşılaştırmayı sil?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.delete(FirebaseFirestore.instance.collection('comparisons').doc(id));
      }
      await batch.commit();
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    }
  }

  Future<void> _deleteAll(List<QueryDocumentSnapshot> docs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm geçmişi sil?'),
        content: Text('${docs.length} karşılaştırma kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hepsini Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Geçmiş')),
        body: const Center(child: Text('Lütfen giriş yapın.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode
            ? '${_selectedIds.length} seçili'
            : 'Geçmiş Karşılaştırmalar'),
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
                  tooltip: 'Seçilenleri Sil',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedIds.clear();
                      _selectionMode = false;
                    });
                  },
                ),
              ]
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('comparisons')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('Bir hata oluştu', style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history, size: 40, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Henüz karşılaştırma yok',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Yaptığınız karşılaştırmalar burada\ngörünecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Üst bar — Seçim ve Topluca silme
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${docs.length} karşılaştırma',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (!_selectionMode) ...[
                      GestureDetector(
                        onTap: () => setState(() => _selectionMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Seç', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _deleteAll(docs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Hepsini Sil', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () => _selectAll(docs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedIds.length == docs.length ? 'Seçimi Kaldır' : 'Tümünü Seç',
                            style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final comp = ComparisonModel.fromMap(docs[index].id, data);
                    final docId = docs[index].id;

                    final day = comp.createdAt.day.toString().padLeft(2, '0');
                    final month = comp.createdAt.month.toString().padLeft(2, '0');
                    final dateStr = '$day.$month.${comp.createdAt.year}';

                    final isSelected = _selectedIds.contains(docId);

                    return Dismissible(
                      key: Key(docId),
                      direction: _selectionMode ? DismissDirection.none : DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Silmek istediğine emin misin?'),
                            content: const Text('Bu işlem geri alınamaz.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sil', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) {
                        FirebaseFirestore.instance.collection('comparisons').doc(docId).delete();
                      },
                      child: GestureDetector(
                        onTap: _selectionMode
                            ? () => _toggleSelection(docId)
                            : () {
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
                        onLongPress: () {
                          if (!_selectionMode) {
                            setState(() {
                              _selectionMode = true;
                              _selectedIds.add(docId);
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.08)
                                : (isDark ? const Color(0xFF2D2D34) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.4)
                                  : (isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_selectionMode) ...[
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? primaryColor : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? primaryColor : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${comp.item1} vs ${comp.item2}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                              if (!_selectionMode)
                                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
