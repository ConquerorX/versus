import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:flutter/material.dart';

class UpdateService {
  // GitHub Reposu Bilgileri
  static const String githubUsername = 'ConquerorX';
  static const String repoName = 'versus';

  /// GitHub API üzerinden en son sürümü kontrol eder.
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.replaceAll('v', '');

      final url = Uri.parse('https://api.github.com/repos/$githubUsername/$repoName/releases/latest');
      final response = await http.get(url);

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final latestTagName = data['tag_name'] as String;
      final latestVersion = latestTagName.replaceAll('v', '');
      final updateNotes = data['body'] as String? ?? 'Yeni özellikler ve hata düzeltmeleri.';
      
      final assets = data['assets'] as List;
      if (assets.isEmpty) return;
      
      final apkAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );

      if (apkAsset == null) return;
      final apkDownloadUrl = apkAsset['browser_download_url'] as String;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersion,
            updateNotes,
            apkDownloadUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('GitHub Güncelleme Kontrolü Hatası: $e');
    }
  }

  bool _isNewerVersion(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      List<int> latestParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      for (int i = 0; i < latestParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestParts[i] > currentPart) return true;
        if (latestParts[i] < currentPart) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void _showUpdateDialog(
    BuildContext context,
    String version,
    String notes,
    String apkUrl,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _UpdateDialog(
          version: version,
          notes: notes,
          apkUrl: apkUrl,
        );
      },
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String notes;
  final String apkUrl;

  const _UpdateDialog({
    required this.version,
    required this.notes,
    required this.apkUrl,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  OtaEvent? currentEvent;
  bool isDownloading = false;

  void _startDownload() {
    setState(() {
      isDownloading = true;
    });

    try {
      // OTA Update indirme işlemini başlatır
      // destinationFilename zorunludur
      OtaUpdate().execute(
        widget.apkUrl,
        destinationFilename: 'versus_update.apk',
      ).listen(
        (OtaEvent event) {
          setState(() => currentEvent = event);
          
          if (event.status == OtaStatus.INSTALLING || 
              event.status == OtaStatus.ALREADY_RUNNING_ERROR) {
            Navigator.pop(context); // Kurulum başlayınca pencereyi kapa
          }
        },
      ).onError((error) {
        debugPrint('OTA Güncelleme Hatası: $error');
        setState(() => isDownloading = false);
      });
    } catch (e) {
      debugPrint('Sistem Hatası: $e');
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1B1B1F) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome, color: theme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Text('Güncelleme Yayında!', style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Versiyon v${widget.version}',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Neler Değişti?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              widget.notes,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            if (isDownloading) ...[
              const SizedBox(height: 30),
              LinearProgressIndicator(
                value: currentEvent?.value != null ? double.tryParse(currentEvent!.value!)! / 100 : null,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _getStatusText(currentEvent?.status),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: isDownloading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Daha Sonra'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _startDownload,
                child: const Text('İndir ve Kur'),
              ),
            ],
    );
  }

  String _getStatusText(OtaStatus? status) {
    if (status == null) return 'Hazırlanıyor...';
    switch (status) {
      case OtaStatus.DOWNLOADING:
        return 'İndiriliyor: %${currentEvent?.value}';
      case OtaStatus.INSTALLING:
        return 'Kuruluyor...';
      case OtaStatus.INTERNAL_ERROR:
        return 'HATA: Dosya indirilemedi.';
      case OtaStatus.DOWNLOAD_ERROR:
        return 'HATA: İnternet bağlantısını kontrol edin.';
      case OtaStatus.CHECKSUM_ERROR:
        return 'HATA: Dosya bozuk.';
      default:
        return 'İşleniyor...';
    }
  }
}
