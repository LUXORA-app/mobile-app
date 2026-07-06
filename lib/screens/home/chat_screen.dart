import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/app_localizations.dart';
import '../../widgets/app_background.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';

// ✅ FIX 2 & 3: Extract typing indicator into its own StatefulWidget
// so its animation rebuilds never affect the parent screen.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // One controller drives all three dots with staggered intervals
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(double begin) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Stagger each dot by offsetting its opacity curve
        final double t = (_controller.value - begin).clamp(0.0, 0.4) / 0.4;
        final double opacity = Curves.easeInOut.transform(t);
        return Opacity(
          opacity: 0.3 + 0.7 * opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0.0),
            const SizedBox(width: 4),
            _dot(0.2),
            const SizedBox(width: 4),
            _dot(0.4),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  bool _isLoadingHistory = false;

  // ✅ FIX 1: Use addPostFrameCallback so scroll runs AFTER the
  // new message is fully laid out — maxScrollExtent is always accurate.
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

  Future<void> _loadMessages() async {
    setState(() => _isLoadingHistory = true);
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoadingHistory = false);
        return;
      }

      final response = await _apiService.getChatHistory();
      if (!mounted) return;

      if (!response.isSuccess) {
        setState(() => _isLoadingHistory = false);
        if ((response.message ?? '').isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message!)),
          );
        }
        return;
      }
final loaded = (response.data ?? [])
    .map<Map<String, dynamic>>(
      (item) => {'text': item.message, 'isMe': !item.isBot},
    )
    .toList(); // now guaranteed List<Map<String, dynamic>>

      setState(() {
        messages = loaded;
        _isLoadingHistory = false;
      });

      _scrollToBottom(); // ✅ will fire after frame is built
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final messageText = _controller.text.trim();

    setState(() {
      messages.add({'text': messageText, 'isMe': true});
      isTyping = true;
    });

    _controller.clear();
    _scrollToBottom(); // ✅ scrolls after user bubble is rendered

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => isTyping = false);
        return;
      }

      final response = await _apiService.sendMessage(messageText);
      if (!mounted) return;

      if (!response.isSuccess || response.data == null) {
        setState(() => isTyping = false);
        if ((response.message ?? '').isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message!)),
          );
        }
        return;
      }

      final botMessage = response.data!['bot_message'];
      setState(() {
        isTyping = false;
        if (botMessage != null) {
          messages.add({'text': botMessage.message, 'isMe': false});
        }
      });

      _scrollToBottom(); // ✅ scrolls after bot bubble is rendered
    } catch (e) {
      if (!mounted) return;
      setState(() => isTyping = false);
    }
  }

  Widget buildMessage(Map msg) {
    bool isMe = msg["isMe"];
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? (theme.brightness == Brightness.light
                  ? AppColors.primary
                  : theme.colorScheme.primary)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          msg["text"],
          style: TextStyle(
            color: isMe
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontFamilyFallback: const ['Arial', 'sans-serif'],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            /// 🔝 TOP BAR
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    loc.translate('chatAssistant'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/images/bot.png'),
                    ),
                  ),
                ],
              ),
            ),

            /// 💬 MESSAGES
            Expanded(
              child: _isLoadingHistory
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < messages.length) {
                          return buildMessage(messages[index]);
                        }
                        // ✅ FIX 2 & 3: Use the isolated widget — zero parent rebuilds
                        return const _TypingIndicator();
                      },
                    ),
            ),

            /// ✏️ INPUT
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => sendMessage(),
                      style: TextStyle(
                        color: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        fontFamilyFallback: const ['Arial', 'sans-serif'],
                      ),
                      decoration: InputDecoration(
                        hintText: loc.translate('typeMessage'),
                        hintStyle: const TextStyle(
                            fontFamilyFallback: ['Arial', 'sans-serif']),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: sendMessage,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}