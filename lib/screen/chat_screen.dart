import 'package:chat_bot/model/message_model.dart';
import 'package:chat_bot/provider/msg_provider.dart';
import 'package:chat_bot/utils/app_colors.dart';
import 'package:chat_bot/widgets/animated_message_bubble.dart';
import 'package:chat_bot/widgets/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  final String query;
  const ChatScreen({super.key, required this.query});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  var chatBoxController = TextEditingController();
  List<MessageModel> listMsg = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Voice recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  /// Time format
  DateFormat dateFormat = DateFormat().add_jm();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeSpeech();
    _animationController.forward();

    /// Send initial query when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<MessageProvider>(
        context,
        listen: false,
      ).sendMessage(message: widget.query);
    });
  }

  void _initializeSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
    setState(() {});
  }

  void _startListening() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Microphone permission is required for voice input',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_speechEnabled && !_isListening) {
      setState(() {
        _isListening = true;
      });

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            chatBoxController.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: "en_US",
        cancelOnError: true,
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    chatBoxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Consumer<MessageProvider>(
                builder: (_, provider, child) {
                  listMsg = provider.listMessage;

                  if (listMsg.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: listMsg.length,
                    itemBuilder: (context, index) {
                      final message = listMsg[index];
                      return AnimatedMessageBubble(
                        message: message,
                        index: index,
                        isUser: message.sendId == 0,
                        onCopy: () => _copyMessage(message.msg!),
                        onRegenerate: message.sendId == 1
                            ? () => _regenerateMessage(index)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _buildInputSection(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                "assets/icon/robot.png",
                height: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const GradientText(
                  'ChatBot AI',
                  gradient: AppColors.primaryGradient,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'fontMain',
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontFamily: 'fontMain',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              "assets/icon/robot.png",
              height: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Starting conversation...',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontFamily: 'fontMain',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildVoiceButton(),
          const SizedBox(width: 12),
          _buildTextField(),
          const SizedBox(width: 12),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: _isListening
            ? AppColors.accentGradient
            : AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isListening ? AppColors.accent : AppColors.surface)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isListening ? _stopListening : _startListening,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isListening
                  ? const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 24,
                      key: ValueKey('listening'),
                    )
                  : Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                      key: const ValueKey('not_listening'),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Expanded(
      child: TextField(
        controller: chatBoxController,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontFamily: 'fontMain',
        ),
        maxLines: 4,
        minLines: 1,
        decoration: InputDecoration(
          hintText: _isListening
              ? "Listening... Speak now!"
              : "Type your message...",
          hintStyle: TextStyle(
            color: _isListening ? AppColors.primary : AppColors.textSecondary,
            fontFamily: 'fontMain',
          ),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (chatBoxController.text.trim().isNotEmpty) {
              Provider.of<MessageProvider>(
                context,
                listen: false,
              ).sendMessage(message: chatBoxController.text.trim());
              setState(() {
                chatBoxController.clear();
              });
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  void _copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Message copied to clipboard!",
          style: TextStyle(color: Colors.white, fontFamily: 'fontMain'),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _regenerateMessage(int index) {
    if (index + 1 < listMsg.length) {
      final userMessage = listMsg[index + 1];
      if (userMessage.sendId == 0) {
        Provider.of<MessageProvider>(
          context,
          listen: false,
        ).sendMessage(message: userMessage.msg!);
      }
    }
  }
}

/// ====== Missing text styles ======
TextStyle mTextStyle18({
  required Color fontColor,
  FontWeight fontWeight = FontWeight.normal,
}) {
  return TextStyle(
    fontSize: 18,
    color: fontColor,
    fontWeight: fontWeight,
    fontFamily: 'fontMain',
  );
}

TextStyle mTextStyle15({
  required Color fontColor,
  FontWeight fontWeight = FontWeight.normal,
}) {
  return TextStyle(
    fontSize: 15,
    color: fontColor,
    fontWeight: fontWeight,
    fontFamily: 'fontMain',
  );
}

TextStyle mTextStyle11({
  required Color fontColor,
  FontWeight fontWeight = FontWeight.normal,
}) {
  return TextStyle(
    fontSize: 11,
    color: fontColor,
    fontWeight: fontWeight,
    fontFamily: 'fontMain',
  );
}
