import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Paneli (God Mode)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Trendler', icon: Icon(Icons.trending_up)),
              Tab(text: 'Karşılaştırmalar', icon: Icon(Icons.compare_arrows)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TrendsAdminList(),
            _ComparisonsAdminList(),
          ],
        ),
      ),
    );
  }
}

class _TrendsAdminList extends StatelessWidget {
  const _TrendsAdminList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trends').orderBy('count', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Veritabanı okunurken hata oluştu. Kuralları (Rules) kontrol edin.', textAlign: TextAlign.center));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('Henüz veritabanında Trend kaydı bulunmamaktadır.'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final item1 = data['item1'] as String? ?? 'Bilinmeyen 1';
            final item2 = data['item2'] as String? ?? 'Bilinmeyen 2';
            final count = data['count'] ?? 0;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: Text('${index + 1}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              ),
              title: Text('$item1  VS  $item2', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${doc.id}\nAranma Sayısı: $count', style: const TextStyle(fontSize: 12)),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                onPressed: () {
                  _deleteDocument(context, 'trends', doc.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _deleteDocument(BuildContext context, String collection, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bu trend kaydını kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt başarıyla silindi!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Silme başarısız: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Kalıcı Olarak Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ComparisonsAdminList extends StatelessWidget {
  const _ComparisonsAdminList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      // Firestore index atamadıysa sortsuz fallback yapabilmek için basit sorgu
      stream: FirebaseFirestore.instance.collection('comparisons').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Veritabanı okunurken hata oluştu.', textAlign: TextAlign.center));
        }

        var docs = snapshot.data?.docs ?? [];
        
        // createdAt bazlı descending manuel sıralama (Cloud Firestore index hatasının önüne geçmek için bellekte sıralanıyor)
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final tA = dataA['createdAt'] as Timestamp?;
          final tB = dataB['createdAt'] as Timestamp?;
          if (tA == null || tB == null) return 0;
          return tB.compareTo(tA);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Henüz veritabanında geçmiş bulunmamaktadır.'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final item1 = data['item1'] as String? ?? 'Bilinmeyen 1';
            final item2 = data['item2'] as String? ?? 'Bilinmeyen 2';
            final userId = data['userId'] as String? ?? 'Anonim';
            
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.history, color: Colors.grey),
              ),
              title: Text('$item1  VS  $item2', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Sahibi (User UID): $userId\nID: ${doc.id}', style: const TextStyle(fontSize: 12)),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                onPressed: () {
                  _deleteDocument(context, 'comparisons', doc.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _deleteDocument(BuildContext context, String collection, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Seçilen karşılaştırma verisini kalıcı olarak kaldırmak istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt başarıyla kaldırıldı!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Silme başarısız: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Kalıcı Olarak Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
