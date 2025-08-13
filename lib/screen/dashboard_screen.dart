import 'package:chat_bot/screen/chat_screen.dart';
import 'package:chat_bot/utils/app_constant.dart';
import 'package:chat_bot/utils/app_colors.dart';
import 'package:chat_bot/widgets/custom_card.dart';
import 'package:chat_bot/widgets/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  var searchController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Voice recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeech();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _animationController.forward();
    _staggerController.forward();
  }

  void _initializeSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
    }
  }

  void _startListening() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission is required for voice input'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    if (!_speechEnabled) {
      debugPrint('Speech recognition not enabled');
      return;
    }

    if (_isListening) {
      debugPrint('Already listening');
      return;
    }

    try {
      setState(() {
        _isListening = true;
      });

      await _speechToText.listen(
        onResult: (result) {
          debugPrint('Speech result: ${result.recognizedWords}');
          if (mounted) {
            setState(() {
              searchController.text = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        onSoundLevelChange: (level) {
          debugPrint('Sound level: $level');
        },
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      debugPrint('Speech recognition stopped');
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
    
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggerController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: const GradientText(
              'ChatBot AI',
              gradient: AppColors.primaryGradient,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'fontMain',
              ),
            ),
          ),
        ),
        actions: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello! 👋',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'fontMain',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How can I help you today?',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontFamily: 'fontMain',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Search Section
                AnimatedBuilder(
                  animation: _staggerController,
                  builder: (context, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _staggerController,
                              curve: const Interval(
                                0.4,
                                0.8,
                                curve: Curves.elasticOut,
                              ),
                            ),
                          ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _staggerController,
                            curve: const Interval(0.4, 0.8),
                          ),
                        ),
                        child: _buildSearchSection(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Categories Section
                AnimatedBuilder(
                  animation: _staggerController,
                  builder: (context, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(-0.3, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _staggerController,
                              curve: const Interval(
                                0.6,
                                1.0,
                                curve: Curves.elasticOut,
                              ),
                            ),
                          ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _staggerController,
                            curve: const Interval(0.6, 1.0),
                          ),
                        ),
                        child: _buildCategoriesSection(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Questions Grid
                AnimatedBuilder(
                  animation: _staggerController,
                  builder: (context, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _staggerController,
                              curve: const Interval(
                                0.8,
                                1.0,
                                curve: Curves.elasticOut,
                              ),
                            ),
                          ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _staggerController,
                            curve: const Interval(0.8, 1.0),
                          ),
                        ),
                        child: _buildQuestionsGrid(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontFamily: 'fontMain',
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _navigateToChat(value.trim());
                }
              },
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: _isListening
                    ? "Listening... Speak now!"
                    : "Ask me anything...",
                hintStyle: TextStyle(
                  color: _isListening
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontFamily: 'fontMain',
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Voice Input Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: _isListening
                        ? AppColors.accentGradient
                        : AppColors.surfaceGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isListening
                                    ? AppColors.accent
                                    : AppColors.surface)
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
                      onTap: _speechEnabled 
                          ? (_isListening ? _stopListening : _startListening)
                          : null,
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
                                  _speechEnabled ? Icons.mic_none_rounded : Icons.mic_off,
                                  color: _speechEnabled ? AppColors.textSecondary : AppColors.textTertiary,
                                  size: 24,
                                  key: const ValueKey('not_listening'),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Send Button
                Container(
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
                        if (searchController.text.trim().isNotEmpty) {
                          _navigateToChat(searchController.text.trim());
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Send',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'fontMain',
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'fontMain',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: AppConstant.defaultQues.length,
            itemBuilder: (context, index) {
              final isSelected = index == selectedIndex;
              final title = AppConstant.defaultQues[index]["title"] ?? '';
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.primaryGradient
                            : null,
                        color: isSelected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: isSelected
                            ? null
                            : Border.all(color: AppColors.border),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontFamily: 'fontMain',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsGrid() {
    final questions = AppConstant.defaultQues[selectedIndex]['question'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Questions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'fontMain',
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final data = questions[index];
            return AnimatedBuilder(
              animation: _staggerController,
              builder: (context, child) {
                final delay = index * 0.1;
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _staggerController,
                          curve: Interval(
                            0.8 + delay,
                            1.0 + delay,
                            curve: Curves.elasticOut,
                          ),
                        ),
                      ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _staggerController,
                        curve: Interval(0.8 + delay, 1.0 + delay),
                      ),
                    ),
                    child: _buildQuestionCard(data),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> data) {
    return CustomCard(
      onTap: () {
        final question = data['ques']?.toString() ?? '';
        if (question.isNotEmpty) {
          _navigateToChat(question);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (data['color'] as Color? ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data['icon'] as IconData? ?? Icons.question_answer,
                color: data['color'] as Color? ?? AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                data['ques']?.toString() ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'fontMain',
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ask now',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
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

  void _navigateToChat(String query) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(query: query),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.elasticOut)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}