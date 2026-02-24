import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/message_view.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:business_analytics_chat/features/chat/presentation/widgets/sidebar.dart';
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
        // Fetch last conversation
        // For now, no-op or select most recent
        debugPrint("📱 ConversationScreen: Opening last conversation requested");
      } else if (widget.conversationId != null) {
        debugPrint('📱 ConversationScreen: Selecting conversation ${widget.conversationId}');
        // Wait for frame to prevent build-phase updates
        Future.delayed(Duration.zero, () {
           if (!mounted) return;
           ref.read(chatProvider.notifier).selectConversation(widget.conversationId!);
        });
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
    final activeConversation = ref.watch(activeConversationProvider);
    // Removed isDesktop check to show drawer always
    final isNewChat = widget.conversationId == null;



    // Show loading only if ID provided but not found, AND not creating new
    // Also show loading if there is a mismatch between requested ID and active ID (transitioning)
    final isMismatch = !isNewChat && activeConversation?.id != widget.conversationId;
    
    if ((activeConversation == null && !isNewChat) || isMismatch) {
       return const Scaffold(
         body: Center(child: CircularProgressIndicator()),
       );
    }

    return Scaffold(
      extendBodyBehindAppBar: false, // Fix header: content scolls UNDER it, not behind it
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Solid background
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          activeConversation?.title ?? 'Orient Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded), 
              onPressed: () async {
                debugPrint('🍔 Menu button clicked');
                // Show Access Token
                const storage = FlutterSecureStorage();
                final token = await storage.read(key: 'auth_token');
                debugPrint('🔑 Access Token: $token');
                // Refresh Sidebar API
                ref.read(chatProvider.notifier).loadConversations();
                Scaffold.of(context).openDrawer();
              },
            );
          }
        ),
      ),
      drawer: const Drawer(child: Sidebar()),
      body: Stack(
        children: [
          // Content Layer
          Positioned.fill(
            child: activeConversation != null
              ? ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(), 
                  // Add padding at bottom for input bar
                  padding: const EdgeInsets.only(
                    top: 16, // Small top padding
                    bottom: 180, // Space for Floating Input
                    left: 0,
                    right: 0,
                  ),
                  itemCount: activeConversation.messages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = activeConversation.messages.length - 1 - index;
                    final message = activeConversation.messages[reversedIndex];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800), // Center content on wide screens
                        child: MessageView(message: message),
                      ),
                    );
                  },
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: _NewChatWelcome(onSuggestionTap: (question) {
                    ref.read(chatProvider.notifier).sendMessage(question);
                  }),
                ),
          ),
          
          // Floating Input Layer
          const Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(isProminent: false), // isProminent ignored now
          ),
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
      iconBg: Color(0xFFE8F0FE), // Light Blue
      iconColor: Color(0xFF1967D2), // Google Blue
      title: 'Top-Selling Products',
      description: 'Analyze sales performance for FY 2026',
      question: 'Show me the top selling products for the current financial year',
    ),
    _SuggestionItem(
      icon: Icons.show_chart_rounded,
      iconBg: Color(0xFFFCE8E6), // Light Red
      iconColor: Color(0xFFC5221F), // Google Red
      title: 'Revenue Trends',
      description: 'Compare monthly revenue vs last year',
      question: 'Give me a total revenue summary for the current financial year',
    ),
    _SuggestionItem(
      icon: Icons.pie_chart_rounded,
      iconBg: Color(0xFFE6F4EA), // Light Green
      iconColor: Color(0xFF137333), // Google Green
      title: 'Customer Insights',
      description: 'Identify top 20 customers by value',
      question: 'Who are the top 20 customers by business in the current financial year?',
    ),
    _SuggestionItem(
      icon: Icons.trending_up_rounded,
      iconBg: Color(0xFFFEF7E0), // Light Yellow
      iconColor: Color(0xFFEA8600), // Google Yellow
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userName.isNotEmpty ? 'Hello, $_userName' : 'Hello there',
                style: TextStyle(
                  fontSize: isMobile ? 44 : 56,
                  fontWeight: FontWeight.w500, // Google Sans medium feel
                  letterSpacing: -1.0,
                  color: const Color(0xFFC4C7C5), // Unselected/Grey start
                ).copyWith(foreground: Paint()..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 200, 70))),
              ),
              Text(
                'How can I help you today?',
                style: TextStyle(
                  fontSize: isMobile ? 44 : 56,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -1.0,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), // Faded look
                ),
              ),
              const SizedBox(height: 48),
              
              // Suggestions Grid
              GridView.count(
                crossAxisCount: isMobile ? 1 : 2, // 2 columns like Gemini desktop
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
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String question;

  const _SuggestionItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
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
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered 
                ? theme.colorScheme.surfaceContainerHighest 
                : theme.colorScheme.surfaceContainer, // Flat grey background
            borderRadius: BorderRadius.circular(16),
            // No border usually, maybe subtle on hover
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.item.icon, 
                  size: 18, 
                  color: widget.item.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
