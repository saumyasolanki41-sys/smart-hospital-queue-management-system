
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/storage_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const Color _primary = Color(0xFF174A5B);
  static const Color _muted = Color(0xFF648994);
  static const Color _background = Color(0xFFEAF8FB);
  static const Color _botBubble = Color(0xFFDDF4F8);

  static const String _chatbotUrl =
      'https://smart-hospital-api.508z112c8xp8p.ap-southeast-2.cs.amazonlightsail.com/chat';

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final StorageService _storageService = StorageService();

  final List<_ChatMessage> _messages = [];

  String? _sessionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _messages.add(
      _ChatMessage(
        text: 'Hello! Welcome to Smart Hospital. How can I help you today?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([String? suggestion]) async {
    final message = (suggestion ?? _messageController.text).trim();

    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: message,
          isUser: true,
        ),
      );

      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final accessToken =
          await _storageService.getAccessToken();

      final Map<String, dynamic> requestBody = {
        'message': message,
        'mode': 'auto',
      };

      // Reuse the existing session for subsequent messages.
      if (_sessionId != null && _sessionId!.isNotEmpty) {
        requestBody['session_id'] = _sessionId;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Include the logged-in patient's access token.
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        headers['Authorization'] =
            'Bearer ${accessToken.trim()}';
      }

      final response = await http.post(
        Uri.parse(_chatbotUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid chatbot response');
        }

        final reply = decoded['reply']?.toString().trim() ?? '';

        final returnedSessionId =
            decoded['session_id']?.toString();

        if (returnedSessionId != null &&
            returnedSessionId.isNotEmpty) {
          _sessionId = returnedSessionId;
        }

        final rawSuggestions = decoded['suggestions'];

        final suggestions = rawSuggestions is List
            ? rawSuggestions.map((item) {
                if (item is Map) {
                  return (item['text'] ??
                          item['label'] ??
                          item['title'] ??
                          '')
                      .toString();
                }

                return item.toString();
              }).where((item) => item.trim().isNotEmpty).toList()
            : <String>[];

        setState(() {
          _messages.add(
            _ChatMessage(
              text: reply.isNotEmpty
                  ? reply
                  : 'I could not generate a response. Please try again.',
              isUser: false,
              suggestions: suggestions,
            ),
          );

          _isLoading = false;
        });
      } else {
        throw Exception('Chatbot request failed');
      }
    } catch (error, stackTrace) {
      debugPrint('Chatbot error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'Sorry, I am unable to connect right now. Please try again.',
            isUser: false,
          ),
        );

        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _startNewConversation() {
    if (_isLoading) return;

    setState(() {
      _sessionId = null;
      _messages.clear();

      _messages.add(
        _ChatMessage(
          text:
              'Hello! Welcome to Smart Hospital. How can I help you today?',
          isUser: false,
        ),
      );
    });
  }

  Widget _buildMessage(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF08AFC5),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? _primary
                        : _botBubble,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : _primary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Display suggestions returned by the chatbot API.
          if (!message.isUser &&
              message.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 43,
                top: 10,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestions.map((item) {
                  return ActionChip(
                    label: Text(
                      item,
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFB9E5EC),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(item),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _primary,
        elevation: 0,
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.favorite_rounded,
                color: Color(0xFF08AFC5),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Hospital Assistant',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Here to help you',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New conversation',
            onPressed: _isLoading
                ? null
                : _startNewConversation,
            icon: const Icon(
              Icons.add_comment_outlined,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              itemCount:
                  _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Assistant is typing...',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Message input section.
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                14,
                10,
                14,
                12,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(
                          color: _muted,
                        ),
                        filled: true,
                        fillColor: _background,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  IconButton(
                    onPressed:
                        _isLoading ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      fixedSize: const Size(48, 48),
                      disabledBackgroundColor: _muted,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String> suggestions;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestions = const [],
  });
}
