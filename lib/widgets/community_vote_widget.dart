import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Topluluk oylaması widget'ı — "Senin tercihin hangisi?"
/// Vote document ID, öğe isimlerinden normalize edilerek oluşturulur 
/// böylece aynı karşılaştırma her açıldığında aynı oy verisi gelir.
class CommunityVoteWidget extends StatefulWidget {
  final String item1;
  final String item2;

  const CommunityVoteWidget({
    super.key,
    required this.item1,
    required this.item2,
  });

  @override
  State<CommunityVoteWidget> createState() => _CommunityVoteWidgetState();
}

class _CommunityVoteWidgetState extends State<CommunityVoteWidget> with SingleTickerProviderStateMixin {
  String? _userVote; // 'item1' veya 'item2'
  int _item1Votes = 0;
  int _item2Votes = 0;
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _animation;
  StreamSubscription<DocumentSnapshot>? _voteSubscription;

  /// Normalize key — "iPhone 16 Pro" vs "Samsung S25" → "iphone_16_pro_vs_samsung_s25"
  String get _voteDocId {
    final sorted = [
      widget.item1.trim().toLowerCase(),
      widget.item2.trim().toLowerCase(),
    ]..sort();
    return '${sorted[0]}_vs_${sorted[1]}'.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _listenVotes();
  }

  @override
  void dispose() {
    _voteSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _listenVotes() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final voteDoc = FirebaseFirestore.instance
        .collection('votes')
        .doc(_voteDocId);

    _voteSubscription = voteDoc.snapshots().listen((doc) {
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        final newItem1Votes = (data['item1_count'] ?? 0) as int;
        final newItem2Votes = (data['item2_count'] ?? 0) as int;
        
        // Kullanıcının oyunu kontrol et
        final userVotes = data['user_votes'] as Map<String, dynamic>?;
        final newUserVote = (userVotes != null && userVotes.containsKey(uid)) 
            ? userVotes[uid] as String 
            : null;

        bool shouldAnimate = false;
        
        setState(() {
          _item1Votes = newItem1Votes;
          _item2Votes = newItem2Votes;
          
          if (_userVote != newUserVote && newUserVote != null) {
            _userVote = newUserVote;
            shouldAnimate = true;
          } else if (_userVote == null && newUserVote != null) {
            _userVote = newUserVote;
            shouldAnimate = true;
          }
        });

        if (shouldAnimate || (_userVote != null && _animController.value == 0)) {
          _animController.forward(from: 0.0);
        } else if (_userVote != null && _animController.value < 1.0 && !_animController.isAnimating) {
           _animController.value = 1.0;
        }
      }

      setState(() => _loading = false);
    }, onError: (_) {
       if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _vote(String choice) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final voteDoc = FirebaseFirestore.instance
        .collection('votes')
        .doc(_voteDocId);

    // Optimistic UI update (Hemen göster, stream sonra doğrular)
    setState(() {
      if (_userVote == 'item1') _item1Votes--;
      if (_userVote == 'item2') _item2Votes--;

      _userVote = choice;
      if (choice == 'item1') _item1Votes++;
      if (choice == 'item2') _item2Votes++;
    });

    _animController.forward(from: 0.0);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(voteDoc);
        
        if (!snapshot.exists) {
          transaction.set(voteDoc, {
            'item1_count': choice == 'item1' ? 1 : 0,
            'item2_count': choice == 'item2' ? 1 : 0,
            'user_votes': {uid: choice},
            'item1': widget.item1,
            'item2': widget.item2,
          });
        } else {
          final data = snapshot.data()!;
          final userVotes = Map<String, dynamic>.from(data['user_votes'] ?? {});
          final oldVote = userVotes[uid] as String?;
          
          int item1Count = (data['item1_count'] ?? 0) as int;
          int item2Count = (data['item2_count'] ?? 0) as int;

          if (oldVote == 'item1') item1Count--;
          if (oldVote == 'item2') item2Count--;

          if (choice == 'item1') item1Count++;
          if (choice == 'item2') item2Count++;

          userVotes[uid] = choice;

          transaction.update(voteDoc, {
            'item1_count': item1Count,
            'item2_count': item2Count,
            'user_votes': userVotes,
          });
        }
      });
    } catch (_) {}
  }

  String _getSuffix(String name) {
    const softVowels = ['e', 'i', 'ö', 'ü'];
    const hardVowels = ['a', 'ı', 'o', 'u'];
    for (int i = name.length - 1; i >= 0; i--) {
      final c = name[i].toLowerCase();
      if (softVowels.contains(c)) return 'yi';
      if (hardVowels.contains(c)) return 'yı';
    }
    return 'yi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = _item1Votes + _item2Votes;
    final item1Percent = total > 0 ? (_item1Votes / total * 100).round() : 50;
    final item2Percent = total > 0 ? (_item2Votes / total * 100).round() : 50;

    // Yeni renk planı: Theme tabanlı
    final color1 = theme.colorScheme.primary; 
    final color2 = theme.colorScheme.tertiary.value != 0 
        ? theme.colorScheme.tertiary 
        : const Color(0xFF5B8A72); 

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFE8E4DF),
        ),
      ),
      child: Column(
        children: [
          // Başlık
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color1.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.how_to_vote_outlined, color: color1, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Senin tercihin hangisi?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (total > 0)
                      Text(
                        '$total kişi oy verdi',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            Center(child: CircularProgressIndicator(strokeWidth: 2, color: color1))
          else ...[
            Row(
              children: [
                Expanded(child: _buildVoteButton('item1', widget.item1, color1)),
                const SizedBox(width: 12),
                Expanded(child: _buildVoteButton('item2', widget.item2, color2)),
              ],
            ),
            if (_userVote != null) ...[
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return _buildResultBar(item1Percent, item2Percent, isDark, _animation.value, color1, color2);
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  item1Percent >= item2Percent
                      ? 'Kullanıcıların %$item1Percent\'i ${widget.item1}\'${_getSuffix(widget.item1)} seçti'
                      : 'Kullanıcıların %$item2Percent\'i ${widget.item2}\'${_getSuffix(widget.item2)} seçti',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildVoteButton(String choice, String label, Color color) {
    final isSelected = _userVote == choice;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _vote(choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? const Color(0xFF1B1B1F) : const Color(0xFFFAF8F5)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF3A3A42) : const Color(0xFFE8E4DF)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildResultBar(int p1, int p2, bool isDark, double animValue, Color c1, Color c2) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Flexible(
                  flex: (p1 * animValue).round().clamp(1, 100),
                  child: Container(color: c1),
                ),
                Flexible(
                  flex: (p2 * animValue).round().clamp(1, 100),
                  child: Container(color: c2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('%$p1', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c1)),
            Text('%$p2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c2)),
          ],
        ),
      ],
    );
  }
}
