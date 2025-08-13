import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chat_bot/model/message_model.dart';
import 'package:chat_bot/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chat_bot/provider/msg_provider.dart';

class AnimatedMessageBubble extends StatefulWidget {
  final MessageModel message;
  final int index;
  final bool isUser;
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;

  const AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.index,
    required this.isUser,
    required this.onCopy,
    this.onRegenerate,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  DateFormat dateFormat = DateFormat().add_jm();

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(widget.isUser ? 1.0 : -1.0, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Stagger the animations
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _slideController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _formatTime() {
    // guard against null/invalid sendAt
    final sendAtStr = widget.message.sendAt;
    if (sendAtStr == null) {
      return dateFormat.format(DateTime.now());
    }
    try {
      final millis = int.parse(sendAtStr);
      return dateFormat.format(DateTime.fromMillisecondsSinceEpoch(millis));
    } catch (e) {
      return dateFormat.format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _formatTime();
    final msgText = widget.message.msg ?? '';

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: widget.isUser
              ? _buildUserMessage(time, msgText)
              : _buildBotMessage(time, msgText),
        ),
      ),
    );
  }

  Widget _buildUserMessage(String time, String msgText) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msgText,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'fontMain',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'fontMain',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotMessage(String time, String msgText) {
    final isRead = widget.message.isRead ?? false;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bot Message Content
            isRead
                ? SelectableText(
                    msgText,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontFamily: 'fontMain',
                      height: 1.4,
                    ),
                  )
                : DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontFamily: 'fontMain',
                      height: 1.4,
                    ),
                    child: AnimatedTextKit(
                      repeatForever: false,
                      displayFullTextOnTap: true,
                      isRepeatingAnimation: false,
                      onFinished: () {
                        // mark message as read in provider
                        if (mounted) {
                          context.read<MessageProvider>().updateMessageRead(
                            widget.index,
                          );
                        }
                      },
                      animatedTexts: [
                        TypewriterAnimatedText(
                          msgText,
                          speed: const Duration(milliseconds: 50),
                        ),
                      ],
                    ),
                  ),

            const SizedBox(height: 12),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        "assets/icon/typing.png",
                        height: 16,
                        width: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Copy Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: widget.onCopy,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.copy_rounded,
                            // keep icon color subtle
                            color: null,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    // Regenerate Button (only for bot messages)
                    if (widget.onRegenerate != null) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: widget.onRegenerate,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.refresh_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'fontMain',
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
