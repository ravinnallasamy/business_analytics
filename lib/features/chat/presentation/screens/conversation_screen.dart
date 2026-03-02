import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/message_view.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/sidebar.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:math';

class ConversationScreen extends ConsumerStatefulWidget {
  final String? conversationId;

  const ConversationScreen({super.key, this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    debugPrint('📱 ConversationScreen: initState with conversationId: ${widget.conversationId}');
    // Defer state update to allow build to finish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.conversationId == 'last') {
         // Let Notifier handle 'last' pseudo-ID
         ref.read(chatProvider.notifier).selectConversation('last');
      } else if (widget.conversationId != null) {
         ref.read(chatProvider.notifier).selectConversation(widget.conversationId!);
      } else {
        // New conversation state
        debugPrint('📱 ConversationScreen: Starting new conversation');
        Future.delayed(Duration.zero, () {
           if (!mounted) return;
           ref.read(chatProvider.notifier).clearActiveConversation();
        });
      }
    });
  }

  @override
  void didUpdateWidget(ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationId != oldWidget.conversationId) {
       debugPrint('📱 ConversationScreen: didUpdateWidget conversationId changed from ${oldWidget.conversationId} to ${widget.conversationId}');
      // Logic for changing conversation
       WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Reset scroll position
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0); 
        }

        if (widget.conversationId != null) {
          debugPrint('📱 ConversationScreen: Switching to conversation ${widget.conversationId}');
          ref.read(chatProvider.notifier).selectConversation(widget.conversationId!);
        } else {
          debugPrint('📱 ConversationScreen: Switching to new conversation');
          ref.read(chatProvider.notifier).clearActiveConversation();
        }
       });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    debugPrint('🛠️ ConversationScreen: build called. ID: ${widget.conversationId}, Active: ${ref.watch(activeConversationProvider)?.id}');
    final chatState = ref.watch(chatProvider);
    final activeConversation = ref.watch(activeConversationProvider);
    // Removed isDesktop check to show drawer always
    final isNewChat = widget.conversationId == null;



    // Instead of blocking with a full-screen spinner, we show a skeleton UI
    // while the active conversation is being updated or loaded from API.
    final isMismatch = !isNewChat && activeConversation?.id != widget.conversationId;
    final isFetchingHistory = !isNewChat && chatState.isLoading && (activeConversation == null || activeConversation.messages.isEmpty);
    final isLoading = (activeConversation == null && !isNewChat) || isMismatch || isFetchingHistory;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const Drawer(child: Sidebar()),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isLoading
            ? const _MessageSkeletonList()
            : Stack(
                key: ValueKey(activeConversation?.id ?? 'new'),
                children: [
                  // Content Layer
                  Positioned.fill(
                    child: activeConversation != null
                      ? ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          physics: const AlwaysScrollableScrollPhysics(), 
                          padding: const EdgeInsets.only(
                            top: 60, // Space for the floating menu button
                            bottom: 100,
                            left: 0,
                            right: 0,
                          ),
                          itemCount: activeConversation.messages.length,
                          itemBuilder: (context, index) {
                            final reversedIndex = activeConversation.messages.length - 1 - index;
                            final message = activeConversation.messages[reversedIndex];
                            return MessageView(message: message);
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 60, bottom: 100),
                          child: _NewChatWelcome(onSuggestionTap: (question) {
                            ref.read(chatProvider.notifier).sendMessage(question);
                          }),
                        ),
                  ),
                  
                  // Floating Menu Button for Sidebar
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                        ),
                      ),
                    ),
                  ),
                  
                  // Floating Input Layer
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: ChatInputBar(isProminent: false),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _MessageSkeletonList extends StatelessWidget {
  const _MessageSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemCount: 5,
          itemBuilder: (context, index) => const _MessageSkeleton(),
        ),
        Positioned.fill(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Image.asset(
                'assets/loader.gif',
                width: 100, // Reduced from 200 for a cleaner look
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageSkeleton extends StatelessWidget {
  const _MessageSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white12 : Colors.black.withOpacity(0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, backgroundColor: color),
              const SizedBox(width: 12),
              Container(width: 100, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: MediaQuery.of(context).size.width * 0.9, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(width: MediaQuery.of(context).size.width * 0.8, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

// ─── New Chat Welcome Screen ───────────────────────────────────────────────

class _NewChatWelcome extends StatefulWidget {
  final void Function(String question) onSuggestionTap;
  const _NewChatWelcome({required this.onSuggestionTap});

  @override
  State<_NewChatWelcome> createState() => _NewChatWelcomeState();
}

class _NewChatWelcomeState extends State<_NewChatWelcome> {
  String _userName = '';

  static const _suggestions = [
    _SuggestionItem(
      icon: Icons.bar_chart_rounded,
      title: 'Top-Selling Products',
      description: 'Analyze sales performance for FY 2026',
      question: 'Show me the top selling products for the current financial year',
    ),
    _SuggestionItem(
      icon: Icons.show_chart_rounded,
      title: 'Revenue Trends',
      description: 'Compare monthly revenue vs last year',
      question: 'Give me a total revenue summary for the current financial year',
    ),
    _SuggestionItem(
      icon: Icons.pie_chart_rounded,
      title: 'Customer Insights',
      description: 'Identify top 20 customers by value',
      question: 'Who are the top 20 customers by business in the current financial year?',
    ),
    _SuggestionItem(
      icon: Icons.trending_up_rounded,
      title: 'Growth Analysis',
      description: 'Review sales trends over 6 months',
      question: 'Show me revenue and sales trends for the past 6 months',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        final decoded = JwtDecoder.decode(token);
        final name = decoded['user_name'] ?? decoded['name'] ?? '';
        if (mounted) {
          setState(() {
            _userName = name.toString().split(' ').first;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Gemini Greeting Gradient
    final gradient = LinearGradient(
      colors: [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.tertiary,
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userName.isNotEmpty ? 'Hello, $_userName' : 'Hello there',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.0,
                  color: AppColors.accentGreen,
                ),
              ),
              Text(
                'How can I help you today?',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: -1.0,
                  color: AppColors.textPrimary.withOpacity(0.2), // Faded look
                ),
              ),
              const SizedBox(height: 48),
              
              // Suggestions Grid
              GridView.count(
                crossAxisCount: isMobile ? 1 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isMobile ? 3.5 : 2.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _suggestions.map((s) => _SuggestionCard(
                  item: s,
                  onTap: () => widget.onSuggestionTap(s.question),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionItem {
  final IconData icon;
  final String title;
  final String description;
  final String question;

  const _SuggestionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.question,
  });
}

class _SuggestionCard extends StatefulWidget {
  final _SuggestionItem item;
  final VoidCallback onTap;
  const _SuggestionCard({required this.item, required this.onTap});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_hovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: _hovered 
                ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.8) 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
            border: Border.all(
              color: _hovered ? AppColors.accentGreen : AppColors.borderGray,
              width: _hovered ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: _hovered ? FontWeight.w900 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      child: Text(widget.item.title),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _hovered ? AppColors.textPrimary.withOpacity(0.7) : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hovered ? AppColors.accentGreen : AppColors.primaryBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.item.icon, 
                  size: 18, 
                  color: _hovered ? Colors.white : AppColors.accentGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

