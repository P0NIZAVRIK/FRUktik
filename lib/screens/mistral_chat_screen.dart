import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/n8n_service.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../providers/diary_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class MistralChatScreen extends StatefulWidget {
  const MistralChatScreen({super.key});

  @override
  State<MistralChatScreen> createState() => _MistralChatScreenState();
}

class _MistralChatScreenState extends State<MistralChatScreen> {
  final N8nService _n8nService = N8nService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add a welcome message
    _messages.add(ChatMessage(
      text:
          'Привет! Я AI-ассистент FRUktik. Спроси меня о питании, калориях или здоровье! 🥗',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, {required bool isUser}) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: isUser, time: DateTime.now()),
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    _addMessage(text, isUser: true);
    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Collect diary context
      Map<String, dynamic>? contextData;
      if (mounted) {
        final diary = context.read<DiaryProvider>();
        contextData = {
          'goals': {
            'calories': diary.goals.calories,
            'proteins': diary.goals.proteins,
            'fats': diary.goals.fats,
            'carbs': diary.goals.carbohydrates,
          },
          'consumed_today': {
            'calories': diary.totalCalories,
            'proteins': diary.totalProteins,
            'fats': diary.totalFats,
            'carbs': diary.totalCarbohydrates,
          },
          'today_meals': diary.todayEntries.map((e) => {
            'name': e.foodItem.name,
            'calories': e.calories,
            'weight': e.weight
          }).toList(),
        };
      }

      // Sending through n8n webhook instead of direct mistral
      final response = await _n8nService.sendTextQuery(text, action: 'chat', contextData: contextData);

      if (response != null && response['error'] != null) {
        _addMessage(
          response['error'] ??
              'Произошла ошибка при обращении к серверу (n8n).',
          isUser: false,
        );
      } else if (response != null && response['reply'] != null) {
        _addMessage(
          response['reply'] ?? 'Пустой ответ',
          isUser: false,
        );
      } else {
        _addMessage(
          'Ответ не распознан. Сервер n8n вернул неожиданный формат: $response',
          isUser: false,
        );
      }
    } catch (e) {
      _addMessage(
        'Ошибка сети или таймаут: $e',
        isUser: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Консультант',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'На базе Mistral AI',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.glassBorder,
            height: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.glassBorder, width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPrimary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Спросить AI…',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isLoading ? null : AppColors.primaryGradient,
                      color: _isLoading ? AppColors.glassBorder : null,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color:
                          _isLoading ? AppColors.textSecondary : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: msg.isUser ? AppColors.primaryGradient : null,
                color: msg.isUser ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: msg.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                  bottomLeft: msg.isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                ),
                border: msg.isUser
                    ? null
                    : Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                msg.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: msg.isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Row(
              children: [
                _DotIndicator(delay: 0),
                SizedBox(width: 4),
                _DotIndicator(delay: 200),
                SizedBox(width: 4),
                _DotIndicator(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatefulWidget {
  final int delay;
  const _DotIndicator({required this.delay});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
