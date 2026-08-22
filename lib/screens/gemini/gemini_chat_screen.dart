import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/offline_ai_service.dart';
import '../../services/online_ai_services.dart';
import '../../services/chat_storage_service.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  State<GeminiChatScreen> createState() =>
      _GeminiChatScreenState();
}

class _GeminiChatScreenState
    extends State<GeminiChatScreen> {
  final TextEditingController _controller =
  TextEditingController();
  final OfflineAIService _offlineAI =
  OfflineAIService();
  final ScrollController _scrollController =
  ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>();

  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isOnline = false;
  String _currentSessionId = '';
  List<ChatSession> _sessions = [];

  String get _userName =>
      FirebaseAuth.instance.currentUser?.displayName
          ?.split(' ')
          .first ??
          'there';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadSessions();
    _newChat();
  }

  void _newChat() {
    setState(() {
      _messages = [];
      _currentSessionId = DateTime.now()
          .millisecondsSinceEpoch
          .toString();
    });
  }

  Future<void> _loadSessions() async {
    final sessions =
    await ChatStorageService.loadSessions();
    if (mounted) setState(() => _sessions = sessions);
  }

  Future<void> _saveCurrentSession() async {
    if (_messages.isEmpty) return;
    final session = ChatSession(
      id: _currentSessionId,
      title: ChatStorageService.generateTitle(
          _messages),
      createdAt: DateTime.now(),
      messages: _messages,
    );
    await ChatStorageService.saveSession(session);
    await _loadSessions();
  }

  Future<void> _loadSession(
      ChatSession session) async {
    await _saveCurrentSession();
    setState(() {
      _messages =
      List<Map<String, String>>.from(
          session.messages);
      _currentSessionId = session.id;
    });
    Navigator.pop(context); // close drawer
    _scrollToBottom();
  }

  Future<void> _deleteSession(String id) async {
    await ChatStorageService.deleteSession(id);
    await _loadSessions();
    if (_currentSessionId == id) _newChat();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
          'google.com')
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _isOnline = result.isNotEmpty &&
              result[0].rawAddress.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOnline = false);
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text.trim(),
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    await _checkConnectivity();
    if (_isOnline) {
      await _sendToGemini(text.trim());
    } else {
      await _sendToOffline(text.trim());
    }
    // Auto-save after each message
    await _saveCurrentSession();
  }

  Future<void> _sendToGemini(String text) async {
    try {
      final reply =
      await OnlineAIService.generateChatResponse(
        text,
        _messages,
      );
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'source': 'gemini',
        });
        _isLoading = false;
      });
    } catch (e) {
      await _sendToOffline(text);
    }
    _scrollToBottom();
  }

  Future<void> _sendToOffline(String text) async {
    try {
      final response =
      await _offlineAI.generateChatResponse(
          text);
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
          'source': 'offline',
        });
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Could not respond. Please try again.',
          'source': 'error',
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(
        const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Drawer (sidebar) ──────────────────────────────
  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness ==
        Brightness.dark;
    return Drawer(
      backgroundColor: isDark
          ? const Color(0xFF2D0F1C)
          : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: const Color(0xFFAD1457),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  const Text('AI Chats',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                          FontWeight.bold)),
                  Text(
                      '${_sessions.length} conversation${_sessions.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12)),
                ],
              ),
            ),

            // New chat button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _saveCurrentSession();
                    _newChat();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add,
                      size: 18),
                  label:
                  const Text('New Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFAD1457),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 12),
                  ),
                ),
              ),
            ),

            const Divider(),

            // Sessions list
            Expanded(
              child: _sessions.isEmpty
                  ? Center(
                child: Text(
                  'No chats yet',
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _sessions.length,
                itemBuilder: (ctx, i) {
                  final s = _sessions[i];
                  final isActive =
                      s.id ==
                          _currentSessionId;
                  return ListTile(
                    selected: isActive,
                    selectedTileColor:
                    const Color(0xFFAD1457)
                        .withOpacity(0.1),
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: isActive
                          ? const Color(
                          0xFFAD1457)
                          : Colors.grey,
                    ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive
                            ? const Color(
                            0xFFAD1457)
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${s.messages.length ~/ 2} messages',
                      style: const TextStyle(
                          fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red),
                      onPressed: () =>
                          _deleteSession(s.id),
                    ),
                    onTap: () =>
                        _loadSession(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness ==
        Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark
          ? const Color(0xFF1A0A12)
          : const Color(0xFFFCE4EC),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFAD1457),
        foregroundColor: Colors.white,
        // ✅ Hamburger menu opens sidebar
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () =>
              _scaffoldKey.currentState
                  ?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ✅ Hi + user name
            Text(
              'NoteMate AI',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isOnline
                  ? '🟢 Online'
                  : '🔴 Offline Mode',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        // ✅ No refresh icon — new chat via sidebar
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: () {
              _saveCurrentSession();
              _newChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessage(
                  msg['content']!,
                  msg['role'] == 'user',
                  msg['source'] ?? '',
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAD1457),
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D0F1C)
                        : Colors.white,
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  child: Text(
                    _isOnline
                        ? 'NoteMate is thinking...'
                        : 'NoteMate thinking offline...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ),
              ]),
            ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2D0F1C)
                  : Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 8, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization:
                      TextCapitalization.sentences,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: _isOnline
                            ? 'Ask NoteMate anything...'
                            : 'Ask NoteMate (offline)...',
                        hintStyle: TextStyle(
                            color: Colors.grey[400]),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1A0A12)
                            : const Color(0xFFF5F5F5),
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _isLoading
                          ? null
                          : _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => _sendMessage(
                        _controller.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? Colors.grey
                            : const Color(0xFFAD1457),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness ==
        Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFAD1457)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: const Color(0xFFAD1457), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Hi $_userName! 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOnline
                  ? 'How Can I Assist You Today?'
                  : 'How Can I Assist You Today',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13),
            ),
            const SizedBox(height: 32),
            _buildSuggestion(
                '📝 Summarize my notes'),
            _buildSuggestion(
                '❓ Explain a concept'),
            _buildSuggestion('📚 Help me study'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    final isDark = Theme.of(context).brightness ==
        Brightness.dark;
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color:
          isDark ? const Color(0xFF2D0F1C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFAD1457)
                .withOpacity(0.3),
          ),
        ),
        child: Text(text,
            style: const TextStyle(
                color: const Color(0xFFAD1457),
                fontSize: 14)),
      ),
    );
  }

  Widget _buildMessage(
      String content, bool isUser, String source) {
    final isDark = Theme.of(context).brightness ==
        Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAD1457),
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFAD1457)
                        : isDark
                        ? const Color(0xFF2D0F1C)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:
                      const Radius.circular(18),
                      topRight:
                      const Radius.circular(18),
                      bottomLeft: Radius.circular(
                          isUser ? 18 : 4),
                      bottomRight: Radius.circular(
                          isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.05),
                        blurRadius: 5,
                      )
                    ],
                  ),
                  child: isUser
                      ? Text(content,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5))
                      : MarkdownBody(
                    data: content,
                    styleSheet:
                    MarkdownStyleSheet(
                      p: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      h1: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87),
                      h2: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          const Color(0xFFAD1457)),
                      h3: TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87),
                      strong: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87),
                      listBullet:
                      const TextStyle(
                          fontSize: 14,
                          color: Color(
                              0xFFAD1457)),
                      code: TextStyle(
                        fontSize: 13,
                        backgroundColor: isDark
                            ? Colors.black26
                            : Colors.grey[100],
                        color: const Color(
                            0xFFAD1457),
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAD1457)
                        .withOpacity(0.2),
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.person,
                      color: const Color(0xFFAD1457),
                      size: 18),
                ),
              ],
            ],
          ),
          if (!isUser && source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                  left: 52, top: 4),
              child: Text(
                source == 'gemini'
                    ? '⚡ Gemini'
                    : source == 'offline'
                    ? '📱 Qwen Offline'
                    : '',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }
}