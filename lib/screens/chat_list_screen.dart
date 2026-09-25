import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../utils/colors.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  final _service = ChatService();
  final _user = FirebaseAuth.instance.currentUser;

  // ---- User preference state ----
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';

  bool _showArchived = false;
  bool _compact = false;
  Color _accent = AppColors.accentGold;

  final Set<String> _pinned = {};
  final Set<String> _muted = {};
  final Set<String> _archived = {};
  final Set<String> _hidden = {};
  final Set<String> _localRead = {};

  bool _prefsLoaded = false;

  // Accent presets (ONLY used for accents — never background/text)
  final Map<String, Color> _accentPresets = {
    'Gold': AppColors.accentGold,
    'Emerald': const Color(0xFF10B981),
    'Ocean': const Color(0xFF38BDF8),
    'Sunset': const Color(0xFFFB7185),
    'Royal': const Color(0xFFA78BFA),
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- PREFS ----------
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pinned.addAll(prefs.getStringList('chat_pinned') ?? []);
      _muted.addAll(prefs.getStringList('chat_muted') ?? []);
      _archived.addAll(prefs.getStringList('chat_archived') ?? []);
      _hidden.addAll(prefs.getStringList('chat_hidden') ?? []);
      _localRead.addAll(prefs.getStringList('chat_read') ?? []);
      _compact = prefs.getBool('chat_compact') ?? false;
      _showArchived = prefs.getBool('chat_show_archived') ?? false;
      final accentHex = prefs.getString('chat_accent');
      if (accentHex != null) {
        final found = _accentPresets.entries
            .firstWhere((e) => e.value.value.toString() == accentHex,
            orElse: () => _accentPresets.entries.first);
        _accent = found.value;
      }
      _prefsLoaded = true;
    });
  }

  Future<void> _saveList(String key, Set<String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, data.toList());
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveAccent(Color c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_accent', c.value.toString());
  }

  // ---------- ACTIONS ----------
  void _togglePin(String id) {
    setState(() {
      if (_pinned.contains(id)) {
        _pinned.remove(id);
      } else {
        _pinned.add(id);
      }
    });
    _saveList('chat_pinned', _pinned);
    _toast(_pinned.contains(id) ? '📌 Pinned' : 'Unpinned');
  }

  void _toggleMute(String id) {
    setState(() {
      if (_muted.contains(id)) {
        _muted.remove(id);
      } else {
        _muted.add(id);
      }
    });
    _saveList('chat_muted', _muted);
    _toast(_muted.contains(id) ? '🔕 Muted' : '🔔 Unmuted');
  }

  void _toggleArchive(String id) {
    setState(() {
      if (_archived.contains(id)) {
        _archived.remove(id);
      } else {
        _archived.add(id);
      }
    });
    _saveList('chat_archived', _archived);
    _toast(_archived.contains(id) ? '🗂️ Archived' : 'Restored');
  }

  void _toggleHide(String id) {
    setState(() {
      _hidden.add(id);
    });
    _saveList('chat_hidden', _hidden);
    _toast('🧹 Hidden from this view');
  }

  void _markRead(String id) {
    setState(() => _localRead.add(id));
    _saveList('chat_read', _localRead);
  }

  void _markAllRead(List<ChatModel> chats) {
    setState(() {
      for (final c in chats) {
        _localRead.add(c.id);
      }
    });
    _saveList('chat_read', _localRead);
    _toast('✅ All marked as read');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _accent,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image (UNCHANGED)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay (UNCHANGED)
          Container(color: Colors.black.withOpacity(0.55)),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(width, height),

                // Search bar (appears only when searching)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _searching
                      ? Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04, vertical: height * 0.008),
                    child: _buildSearchField(width),
                  )
                      : const SizedBox.shrink(),
                ),

                // Small status strip (pinned / muted / archived counts)
                if (_pinned.isNotEmpty ||
                    _muted.isNotEmpty ||
                    _archived.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04, vertical: height * 0.005),
                    child: Row(
                      children: [
                        if (_pinned.isNotEmpty)
                          _chip('📌 ${_pinned.length}', width),
                        if (_muted.isNotEmpty)
                          _chip('🔕 ${_muted.length}', width),
                        if (_archived.isNotEmpty)
                          _chip('🗂️ ${_archived.length}', width),
                        const Spacer(),
                        if (_showArchived)
                          _chip('Viewing Archive', width),
                      ],
                    ),
                  ),

                // Chat list
                Expanded(
                  child: !_prefsLoaded
                      ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                      : _user == null
                      ? const Center(
                      child: Text('Please login',
                          style: TextStyle(color: Colors.white)))
                      : StreamBuilder<List<ChatModel>>(
                    stream: _service.getUserChats(_user!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white));
                      }

                      final all = snapshot.data ?? [];
                      final list = _applyFilters(all);

                      if (list.isEmpty) {
                        return _buildEmptyState(width, height);
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(width * 0.04),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _buildChatCard(
                          list[i],
                          width,
                          height,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // FAB (still gold, but uses current accent)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _startNewChat,
              backgroundColor: _accent,
              icon: const Icon(Icons.add_comment, color: Colors.black),
              label: const Text(
                'New Chat',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- FILTER PIPELINE ----------
  List<ChatModel> _applyFilters(List<ChatModel> all) {
    Iterable<ChatModel> list = all;

    // archived view
    list = list.where((c) =>
    _showArchived ? _archived.contains(c.id) : !_archived.contains(c.id));

    // hidden
    list = list.where((c) => !_hidden.contains(c.id));

    // search
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((c) =>
      c.lastMessage.toLowerCase().contains(q) ||
          'turiva support'.contains(q));
    }

    final result = list.toList();

    // sort: pinned first, then by timeAgo (string fallback)
    result.sort((a, b) {
      final ap = _pinned.contains(a.id) ? 0 : 1;
      final bp = _pinned.contains(b.id) ? 0 : 1;
      return ap.compareTo(bp);
    });

    return result;
  }

  // ---------- HEADER ----------
  Widget _buildHeader(double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.01,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            _showArchived ? '🗂️ Archived' : '💬 Messages',
            style: TextStyle(
              fontSize: width * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),

          // Search toggle
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchController.clear();
                  _query = '';
                }
              });
            },
          ),

          // Power menu
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _openPowerMenu(width, height),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.search, color: _accent),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, double width) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.03, vertical: width * 0.012),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: width * 0.03,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------- POWER MENU (Bottom Sheet) ----------
  void _openPowerMenu(double width, double height) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withOpacity(0.25), width: 1)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.02),

                      Text('Chat Controls',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: height * 0.005),
                      Text('Personalize without changing the look',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.032)),
                      SizedBox(height: height * 0.02),

                      // ---- Accent color ----
                      Text('Accent Color',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.038,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: height * 0.012),
                      Wrap(
                        spacing: 12,
                        children: _accentPresets.entries.map((e) {
                          final selected = _accent.value == e.value.value;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _accent = e.value);
                              setSheet(() {});
                              _saveAccent(e.value);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: e.value,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  width: selected ? 3 : 1,
                                ),
                                boxShadow: selected
                                    ? [
                                  BoxShadow(
                                      color: e.value.withOpacity(0.6),
                                      blurRadius: 12)
                                ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check,
                                  color: Colors.black, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: height * 0.02),
                      Divider(color: Colors.white.withOpacity(0.15)),
                      SizedBox(height: height * 0.01),

                      // ---- Toggles ----
                      _menuTile(
                        icon: _compact
                            ? Icons.view_agenda
                            : Icons.view_agenda_outlined,
                        title: _compact
                            ? 'Compact density: ON'
                            : 'Compact density: OFF',
                        subtitle: 'Fit more chats on screen',
                        width: width,
                        onTap: () {
                          setState(() => _compact = !_compact);
                          setSheet(() {});
                          _saveBool('chat_compact', _compact);
                        },
                      ),
                      _menuTile(
                        icon: _showArchived
                            ? Icons.unarchive
                            : Icons.archive_outlined,
                        title: _showArchived
                            ? 'Viewing Archive'
                            : 'View Archive',
                        subtitle: '${_archived.length} archived chat(s)',
                        width: width,
                        onTap: () {
                          setState(() => _showArchived = !_showArchived);
                          setSheet(() {});
                          _saveBool('chat_show_archived', _showArchived);
                          Navigator.pop(ctx);
                        },
                      ),
                      _menuTile(
                        icon: Icons.mark_chat_read_outlined,
                        title: 'Mark all as read',
                        subtitle: 'Clear unread badges',
                        width: width,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final snap = await _service
                              .getUserChats(_user!.uid)
                              .first;
                          _markAllRead(snap);
                        },
                      ),
                      _menuTile(
                        icon: Icons.restore,
                        title: 'Unhide all chats',
                        subtitle: 'Bring back hidden conversations',
                        width: width,
                        onTap: () {
                          setState(() => _hidden.clear());
                          _saveList('chat_hidden', _hidden);
                          setSheet(() {});
                          _toast('🧹 Hidden chats restored');
                        },
                      ),
                      _menuTile(
                        icon: Icons.push_pin_outlined,
                        title: 'Unpin all',
                        subtitle: '${_pinned.length} pinned chat(s)',
                        width: width,
                        onTap: () {
                          setState(() => _pinned.clear());
                          _saveList('chat_pinned', _pinned);
                          setSheet(() {});
                          _toast('📌 All unpinned');
                        },
                      ),
                      _menuTile(
                        icon: Icons.notifications_off_outlined,
                        title: 'Unmute all',
                        subtitle: '${_muted.length} muted chat(s)',
                        width: width,
                        onTap: () {
                          setState(() => _muted.clear());
                          _saveList('chat_muted', _muted);
                          setSheet(() {});
                          _toast('🔔 All unmuted');
                        },
                      ),

                      SizedBox(height: height * 0.01),
                      Divider(color: Colors.white.withOpacity(0.15)),
                      SizedBox(height: height * 0.01),

                      // ---- Info card ----
                      Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: width * 0.06,
                              backgroundColor: _accent,
                              child: const Icon(Icons.admin_panel_settings,
                                  color: Colors.black),
                            ),
                            SizedBox(width: width * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TURIVA Support',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: width * 0.038)),
                                  Text(
                                      'Available 24/7 for your trip',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: width * 0.03)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double width,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: width * 0.03),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Icon(icon, color: Colors.white, size: width * 0.05),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: width * 0.036)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white70, fontSize: width * 0.03)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  // ---------- CHAT CARD ----------
  Widget _buildChatCard(ChatModel chat, double width, double height) {
    final isMuted = _muted.contains(chat.id);
    final isPinned = _pinned.contains(chat.id);
    final hasUnread =
        chat.unreadByUser > 0 && !_localRead.contains(chat.id) && !isMuted;

    final card = Container(
      margin: EdgeInsets.only(bottom: height * (_compact ? 0.006 : 0.012)),
      padding: EdgeInsets.all(width * (_compact ? 0.03 : 0.04)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: hasUnread
            ? Border.all(color: _accent, width: 2)
            : isPinned
            ? Border.all(color: _accent.withOpacity(0.6), width: 1.5)
            : Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar + ring
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isPinned
                      ? LinearGradient(
                      colors: [_accent, _accent.withOpacity(0.3)])
                      : null,
                ),
                child: CircleAvatar(
                  radius: width * 0.07,
                  backgroundColor: _accent,
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.black, size: width * 0.07),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: width * 0.035,
                  height: width * 0.035,
                  decoration: BoxDecoration(
                    color: isMuted ? Colors.grey : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: width * 0.03),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPinned) ...[
                      Icon(Icons.push_pin, color: _accent, size: width * 0.035),
                      SizedBox(width: width * 0.01),
                    ],
                    Expanded(
                      child: Text(
                        'TURIVA Support',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isMuted)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.notifications_off,
                            color: Colors.white54, size: width * 0.035),
                      ),
                    Text(
                      chat.timeAgo,
                      style: TextStyle(
                        color: hasUnread ? _accent : Colors.grey.shade500,
                        fontSize: width * 0.028,
                        fontWeight:
                        hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.005),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.lastMessage,
                        style: TextStyle(
                          color: hasUnread ? Colors.white : Colors.white70,
                          fontSize: width * 0.032,
                          fontWeight:
                          hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${chat.unreadByUser}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Wrap with Dismissible for swipe gestures
    return Dismissible(
      key: ValueKey('chat_${chat.id}'),
      background: _swipeBg(
          alignment: Alignment.centerLeft,
          color: _accent,
          icon: Icons.push_pin,
          label: 'Pin'),
      secondaryBackground: _swipeBg(
          alignment: Alignment.centerRight,
          color: Colors.grey.shade800,
          icon: Icons.notifications_off,
          label: 'Mute'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _togglePin(chat.id);
        } else {
          _toggleMute(chat.id);
        }
        return false; // don't remove — just apply state
      },
      child: GestureDetector(
        onTap: () async {
          _markRead(chat.id);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chatId: chat.id,
                otherUserName: 'TURIVA Support',
                isAdmin: false,
              ),
            ),
          );
        },
        onLongPress: () => _openChatActions(chat, width, height),
        child: card,
      ),
    );
  }

  Widget _swipeBg({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _openChatActions(ChatModel chat, double width, double height) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(width * 0.05),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.25))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  Text('Chat Options',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: height * 0.015),
                  _menuTile(
                    icon: _pinned.contains(chat.id)
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    title: _pinned.contains(chat.id) ? 'Unpin' : 'Pin to top',
                    subtitle: 'Keep this chat at the top',
                    width: width,
                    onTap: () {
                      Navigator.pop(ctx);
                      _togglePin(chat.id);
                    },
                  ),
                  _menuTile(
                    icon: _muted.contains(chat.id)
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    title: _muted.contains(chat.id) ? 'Unmute' : 'Mute',
                    subtitle: 'Hide unread highlights',
                    width: width,
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleMute(chat.id);
                    },
                  ),
                  _menuTile(
                    icon: Icons.mark_chat_read_outlined,
                    title: 'Mark as read',
                    subtitle: 'Clear this chat unread badge',
                    width: width,
                    onTap: () {
                      Navigator.pop(ctx);
                      _markRead(chat.id);
                    },
                  ),
                  _menuTile(
                    icon: _archived.contains(chat.id)
                        ? Icons.unarchive
                        : Icons.archive_outlined,
                    title: _archived.contains(chat.id)
                        ? 'Restore'
                        : 'Archive',
                    subtitle: 'Move to archive list',
                    width: width,
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleArchive(chat.id);
                    },
                  ),
                  _menuTile(
                    icon: Icons.visibility_off_outlined,
                    title: 'Hide from list',
                    subtitle: 'Remove from this view',
                    width: width,
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleHide(chat.id);
                    },
                  ),
                  SizedBox(height: height * 0.01),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- EMPTY STATE (UNCHANGED) ----------
  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(width * 0.1),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: width * 0.15, color: Colors.white70),
            SizedBox(height: height * 0.03),
            Text(
              _query.isNotEmpty ? 'No results' : 'No messages yet',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Text(
                _query.isNotEmpty
                    ? 'Try a different search'
                    : 'Chat with TURIVA Support for any questions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: width * 0.035,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- START NEW CHAT (UNCHANGED) ----------
  Future<void> _startNewChat() async {
    if (_user == null) return;

    final chatId = await _service.getOrCreateChat(
      userId: _user!.uid,
      userName: _user!.displayName ?? 'User',
      userPhoto: _user!.photoURL ?? '',
    );

    if (chatId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: chatId,
            otherUserName: 'TURIVA Support',
            isAdmin: false,
          ),
        ),
      );
    }
  }
}