import 'package:flutter/material.dart';

class CompareInputScreen extends StatefulWidget {
  const CompareInputScreen({super.key});

  @override
  State<CompareInputScreen> createState() => _CompareInputScreenState();
}

class _CompareInputScreenState extends State<CompareInputScreen> {
  final _product1Ctrl = TextEditingController();
  final _product2Ctrl = TextEditingController();

  @override
  void dispose() {
    _product1Ctrl.dispose();
    _product2Ctrl.dispose();
    super.dispose();
  }

  void _analyzeProducts() {
    // Burada ileride Cloudflare uzerinden Gemini'ye baglanacagiz
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yapay Zeka analizi baslatiliyor...')),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotograf Cek'),
              onTap: () {
                Navigator.pop(context);
                // Kamera islevi
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Sec'),
              onTap: () {
                Navigator.pop(context);
                // Galeri islevi
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yeni Karsilastirma',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hangi urunleri karsilastirmak istiyorsunuz?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ister isimlerini yazin, ister magazada gordugunuz urunlerin fotograflarini ekleyin.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 1. Urun Karti
            _buildProductInputCard(
              title: '1. Urun',
              controller: _product1Ctrl,
              hint: 'Orn: iPhone 15 Pro Max',
            ),

            const SizedBox(height: 16),

            // VS Ikonic
            const Center(
              child: CircleAvatar(
                backgroundColor: Colors.deepPurpleAccent,
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Urun Karti
            _buildProductInputCard(
              title: '2. Urun',
              controller: _product2Ctrl,
              hint: 'Orn: Samsung Galaxy S24 Ultra',
            ),

            const SizedBox(height: 32),

            // Aksiyon Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _analyzeProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'YZ ile Analiz Et ve Karsilastir',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInputCard({
    required String title,
    required TextEditingController controller,
    required String hint,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showImageOptions,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Gorselden Tani'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
