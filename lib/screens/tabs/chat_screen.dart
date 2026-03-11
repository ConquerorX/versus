import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_service.dart';
import '../../services/haptic_feedback_service.dart';

/// Premium tam ekran sohbet penceresi
class ChatScreen extends StatefulWidget {
  final String item1Name;
  final String item2Name;
  final String? initialContext;
  final List<String> suggestedQuestions;

  const ChatScreen({
    super.key,
    required this.item1Name,
    required this.item2Name,
    this.initialContext,
    this.suggestedQuestions = const [],
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;
  bool _isFocused = false;

  // Animasyon için
  late AnimationController _dotsController;

  // ═══════════════════════════════════════════════
  // Dinamik Öneri Soruları
  // ═══════════════════════════════════════════════
  final List<String> _activeSuggestions = [];
  final List<String> _usedQuestions = [];
  final _random = Random();

  static const List<String> _questionPool = [
    'Hangisi daha iyi?',
    'Detaylı karşılaştır',
    'Avantajları neler?',
    'Fiyat farkı ne?',
    'Hangisini önerirsin?',
    'Dezavantajları neler?',
    'Performans farkı ne?',
    'Tasarım farkları neler?',
    'Hangisi daha dayanıklı?',
    'Kullanıcı yorumları nasıl?',
    'Yeni başlayanlar için hangisi?',
    'Profesyoneller için hangisi?',
    'Uzun vadede hangisi daha iyi?',
    'Garanti süreleri nasıl?',
    'Teknik özellikleri kıyasla',
    'En büyük artıları neler?',
    'Para-performans oranı?',
    'Güncel fiyatları nedir?',
    'Popülerlik farkı var mı?',
    'Müşteri memnuniyeti nasıl?',
  ];

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });

    // İlk öneri sorularını yükle
    _initSuggestions();
  }

  void _initSuggestions() {
    final source = widget.suggestedQuestions.isNotEmpty
        ? List<String>.from(widget.suggestedQuestions)
        : List<String>.from(_questionPool);
    source.shuffle(_random);
    _activeSuggestions.addAll(source.take(5));
    // Kullanılmamış soruları sakla
    _usedQuestions.addAll(_activeSuggestions);
  }

  String? _getNewQuestion() {
    final available = _questionPool.where((q) => !_usedQuestions.contains(q)).toList();
    if (available.isEmpty) return null;
    available.shuffle(_random);
    final q = available.first;
    _usedQuestions.add(q);
    return q;
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _chatController.text.trim();
    if (text.isEmpty || _isSending) return;

    HapticService.lightTap();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _isSending = true;
    });
    if (overrideText == null) _chatController.clear();
    _scrollToBottom();

    final history = <Map<String, String>>[];
    history.add({'role': 'user', 'text': '${widget.item1Name} ve ${widget.item2Name} karşılaştırması yap.'});
    if (widget.initialContext != null) {
      history.add({'role': 'model', 'text': widget.initialContext!});
    }

    for (final msg in _messages) {
      history.add({'role': msg.role, 'text': msg.text});
    }

    final response = await AiService.sendFollowUp(
      conversationHistory: history,
      item1: widget.item1Name,
      item2: widget.item2Name,
    );

    if (mounted) {
      HapticService.selectionClick();
      setState(() {
        _messages.add(_ChatMessage(role: 'model', text: response));
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFFAF8F5),
      appBar: _buildAppBar(isDark, primaryColor, secondaryColor),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark, primaryColor, secondaryColor)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isSending) {
                        return _buildTypingIndicator(isDark, primaryColor, secondaryColor);
                      }
                      return _buildChatBubble(_messages[index], isDark, index, primaryColor, secondaryColor);
                    },
                  ),
          ),
          if (_activeSuggestions.isNotEmpty && (_messages.isEmpty || _messages.length < 6))
            _buildSuggestionStrip(isDark, primaryColor, secondaryColor),
          _buildInputArea(isDark, primaryColor, secondaryColor),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color primaryColor, Color secondaryColor) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFFAF8F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D34) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Gradient AI ikon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YZ Asistan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.item1Name} vs ${widget.item2Name}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            ),
            onPressed: () => setState(() => _messages.clear()),
            tooltip: 'Sohbeti Temizle',
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor, Color secondaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Büyük gradient AI ikonu
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Karşılaştırma Asistanı',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.item1Name} ve ${widget.item2Name} hakkında\nher şeyi sorabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            // Özellik çipleri
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _featureChip(Icons.speed, 'Hızlı Yanıt', primaryColor),
                _featureChip(Icons.psychology, 'Bağlam Duyarlı', primaryColor),
                _featureChip(Icons.translate, 'Türkçe', primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Dinamik Öneri Soruları
  // ═══════════════════════════════════════════════
  Widget _buildSuggestionStrip(bool isDark, Color primaryColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _activeSuggestions.length,
          separatorBuilder: (context2, index2) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                HapticService.lightTap();
                final question = _activeSuggestions[index];
                setState(() {
                  // Tıklanan soruyu kaldır
                  _activeSuggestions.removeAt(index);
                  // Havuzdan yeni soru ekle
                  final newQ = _getNewQuestion();
                  if (newQ != null) {
                    _activeSuggestions.add(newQ);
                  }
                });
                _sendMessage(question);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2D2D34)
                      : primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    _activeSuggestions[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : primaryColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Input Alanı — Düzeltilmiş (tek katman border-radius)
  // ═══════════════════════════════════════════════
  Widget _buildInputArea(bool isDark, Color primaryColor, Color secondaryColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121214) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF2D2D34) : Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1B1B1F) : const Color(0xFFF5F5F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: GestureDetector(
                onTap: _isSending ? null : () => _sendMessage(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage msg, bool isDark, int index, Color primaryColor, Color secondaryColor) {
    final isUser = msg.role == 'user';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 32, height: 32,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser
                      ? primaryColor
                      : (isDark ? const Color(0xFF2D2D34) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  border: isUser ? null : Border.all(
                    color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(msg.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5))
                    : MarkdownBody(
                        data: msg.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(fontSize: 14, height: 1.6,
                            color: isDark ? Colors.grey[300] : Colors.grey[800]),
                          strong: TextStyle(fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF2D2D34)),
                          listBullet: TextStyle(fontSize: 14,
                            color: isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              Container(
                width: 32, height: 32,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person, color: primaryColor, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D34) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.2;
                    final progress = (_dotsController.value - delay) % 1.0;
                    final scale = 0.5 + 0.5 * (1 - (2 * progress - 1).abs());
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: scale),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  _ChatMessage({required this.role, required this.text});
}
