import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:business_analytics_chat/features/auth/state/auth_notifier.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userName = 'User';
  String _userRole = 'User';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      final decoded = JwtDecoder.decode(token);
      setState(() {
        _userName = decoded['user_name'] ?? decoded['name'] ?? 'User';
        _userRole = decoded['agent_role'] ?? decoded['role'] ?? 'User';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<Conversation>> _groupConversations(List<Conversation> conversations) {
    final Map<String, List<Conversation>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    // Sort by updated_at descending first
    final sorted = List<Conversation>.from(conversations)..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    for (var conv in sorted) {
      if (_searchQuery.isNotEmpty && !conv.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }

      final date = conv.lastUpdated;
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) {
        grouped.putIfAbsent('Today', () => []).add(conv);
      } else if (dateOnly == yesterday) {
        grouped.putIfAbsent('Yesterday', () => []).add(conv);
      } else if (date.isAfter(sevenDaysAgo)) {
        grouped.putIfAbsent('Previous 7 Days', () => []).add(conv);
      } else if (date.isAfter(thirtyDaysAgo)) {
        grouped.putIfAbsent('Previous 30 Days', () => []).add(conv);
      } else {
         grouped.putIfAbsent('Older', () => []).add(conv);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final activeId = chatState.activeConversationId;
    final groupedConversations = _groupConversations(chatState.conversations);
    
    final groups = ['Today', 'Yesterday', 'Previous 7 Days', 'Previous 30 Days', 'Older']
        .where((g) => groupedConversations.containsKey(g) && groupedConversations[g]!.isNotEmpty)
        .toList();

    return Container(
      color: AppColors.sidebarBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Branding ──
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: SizedBox(height: 40),
          ),
          // ── New Chat Button & Refresh ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () {
                        ref.read(chatProvider.notifier).clearActiveConversation();
                        if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                          Navigator.of(context).pop();
                        }
                        context.go('/chat');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentGreen.withOpacity(0.1),
                        foregroundColor: AppColors.accentGreen,
                        elevation: 0,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: const BorderSide(color: AppColors.accentGreen, width: 1),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 20, color: AppColors.accentGreen),
                      label: Text(
                        'New chat', 
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.textOnDark.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textOnDark),
                    tooltip: 'Refresh conversations',
                    onPressed: () {
                      ref.read(chatProvider.notifier).loadConversations();
                    },
                  ),
                ),
              ],
            ),
          ),

           // ── Search Field ──
           if (chatState.conversations.isNotEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
               child: TextField(
                 controller: _searchController,
                 onChanged: (val) => setState(() => _searchQuery = val),
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textOnDark),
                 decoration: InputDecoration(
                   hintText: 'Search chats',
                   hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textOnDark.withOpacity(0.5)),
                   prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textOnDark.withOpacity(0.5)),
                   filled: true,
                   fillColor: AppColors.textOnDark.withOpacity(0.05),
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(24),
                     borderSide: BorderSide.none,
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(24),
                     borderSide: BorderSide.none,
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(24),
                     borderSide: const BorderSide(color: AppColors.accentGreen, width: 1),
                   ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                   isDense: true,
                 ),
               ),
             ),

          // ── Conversation List ──
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: chatState.isLoading && chatState.conversations.isEmpty
                  ? const _SidebarSkeleton()
                  : chatState.conversations.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          key: const ValueKey('conv_list'),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          children: groups.map((group) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                                  child: Text(
                                    group.toUpperCase(),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textOnDark.withOpacity(0.4),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                ...groupedConversations[group]!.map((conv) {
                                  final isActive = conv.id == activeId;
                                  return _buildConversationItem(conv, isActive, context);
                                }),
                              ],
                            );
                          }).toList(),
                        ),
            ),
          ),

          // ── User Profile ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.textOnDark.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accentGreen,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                     style: Theme.of(context).textTheme.titleSmall?.copyWith(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                     ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _userRole,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textOnDark.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout_rounded, size: 18, color: AppColors.textOnDark.withOpacity(0.5)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.sidebarBackground,
                        title: const Text('Logout', style: TextStyle(color: AppColors.textOnDark)),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: AppColors.textOnDark.withOpacity(0.7)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel', style: TextStyle(color: AppColors.textOnDark.withOpacity(0.5))),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) context.go('/login');
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textOnDark.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textOnDark.withOpacity(0.4)),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Conversation conv, bool isActive, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2, left: 8, right: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentGreen.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? Border.all(color: AppColors.accentGreen.withOpacity(0.3), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          hoverColor: AppColors.textOnDark.withOpacity(0.05),
          onTap: () {
            Scaffold.of(context).closeDrawer();
            context.go('/chat/${conv.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: isActive ? AppColors.accentGreen : AppColors.textOnDark.withOpacity(0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    conv.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isActive ? AppColors.textOnDark : AppColors.textOnDark.withOpacity(0.8),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert, 
                        size: 16, 
                        color: AppColors.accentGreen,
                      ),
                      onPressed: () {
                         // Show menu options (Rename, Delete)
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSkeleton extends StatelessWidget {
  const _SidebarSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textOnDark.withOpacity(0.05);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

