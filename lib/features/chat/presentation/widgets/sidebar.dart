import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/features/chat/state/chat_state.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:business_analytics_chat/features/auth/state/auth_notifier.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:business_analytics_chat/core/constants/ui_constants.dart';

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
      // Filter by search query
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
        // Optional: Older
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
    
    // Define group order
    final groups = ['Today', 'Yesterday', 'Previous 7 Days', 'Previous 30 Days', 'Older']
        .where((g) => groupedConversations.containsKey(g) && groupedConversations[g]!.isNotEmpty)
        .toList();

    return Container(
      color: const Color(0xFF1E1F20), // Dark background like Gemini
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Branding ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Image.asset(
              'assets/orient-logo.jpg',
              height: 40,
              alignment: Alignment.centerLeft,
            ),
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
                        backgroundColor: const Color(0xFF28292A), // Dark grey button
                        foregroundColor: const Color(0xFFE3E3E3), // Text color
                        elevation: 0,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(Icons.add, size: 20, color: Color(0xFFE3E3E3)),
                      label: const Text('New chat', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF28292A),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFFE3E3E3)),
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
           // Only show if there are conversations
           if (chatState.conversations.isNotEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
               child: TextField(
                 controller: _searchController,
                 onChanged: (val) => setState(() => _searchQuery = val),
                 style: const TextStyle(color: Colors.white, fontSize: 13),
                 decoration: InputDecoration(
                   hintText: 'Search chats',
                   hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                   prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
                   filled: true,
                   fillColor: const Color(0xFF28292A),
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(24),
                     borderSide: BorderSide.none,
                   ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                   isDense: true,
                 ),
               ),
             ),

          // ── Conversation List ──
          Expanded(
            child: chatState.conversations.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    children: groups.map((group) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                            child: Text(
                              group,
                              style: const TextStyle(
                                color: Color(0xFF8E9196), // Muted text
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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

          // ── User Profile ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF2D2E30))), // Divider
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF444746),
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                     style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Color(0xFFE3E3E3),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _userRole,
                        style: const TextStyle(
                          color: Color(0xFF8E9196),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF8E9196)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF28292A),
                        title: const Text('Logout', style: TextStyle(color: Color(0xFFE3E3E3))),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: Color(0xFFC4C7C5)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA8C7FA))),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // Close dialog first to avoid context issues
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) context.go('/login');
                            },
                            child: const Text('Logout', style: TextStyle(color: Color(0xFFFFB4AB))),
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
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Conversation conv, bool isActive, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF004A77) : Colors.transparent, // Active blue
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          hoverColor: isActive ? null : const Color(0xFF28292A),
          onTap: () {
            Scaffold.of(context).closeDrawer();
            context.go('/chat/${conv.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // No icon for items, just text per screenshot style (or maybe small icon?)
                // Screenshot shows just text.
                Expanded(
                  child: Text(
                    conv.title,
                    style: TextStyle(
                      color: isActive ? const Color(0xFFD3E3FD) : const Color(0xFFE3E3E3),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Show options menu only on hover ideally, but for mobile/touch always show ?
                // For now, let's just put the dots menu
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert, 
                      size: 16, 
                      color: isActive ? const Color(0xFFD3E3FD) : const Color(0xFF8E9196)
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
