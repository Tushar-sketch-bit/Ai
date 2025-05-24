import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PhilosophyBotApp());
}

class PhilosophyBotApp extends StatelessWidget {
  const PhilosophyBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Philosophy Bot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A2E39),
          primary: const Color(0xFF3A2E39),
          secondary: const Color(0xFF5E4955),
          background: const Color(0xFFF5F5F5),
        ),
        fontFamily: 'Georgia',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A2E39),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF333333)),
        ),
      ),
      home: const ChatPage(title: 'Philosophy Bot'),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? sources;

  ChatMessage({required this.text, required this.isUser, this.sources});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});

  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _useKnowledgeBase = true;

  // API endpoint - change this to your actual backend URL when deployed
  final String apiUrl = 'http://localhost:8000/chat';

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    _textController.clear();

    // Add user message to chat
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Call API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'use_knowledge_base': _useKnowledgeBase,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Add bot response to chat
        setState(() {
          _messages.add(
            ChatMessage(
              text: data['response'],
              isUser: false,
              sources:
                  data['sources'] != null
                      ? List<String>.from(data['sources'])
                      : null,
            ),
          );
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Sorry, I encountered an error. Please try again later.',
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Network error. Please check your connection and try again.',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }

    // Scroll to bottom again after adding response
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Knowledge base toggle
          Row(
            children: [
              const Text(
                'Use Knowledge Base',
                style: TextStyle(color: Colors.white),
              ),
              Switch(
                value: _useKnowledgeBase,
                onChanged: (value) {
                  setState(() {
                    _useKnowledgeBase = value;
                  });
                },
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message
          if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.psychology,
                      size: 80,
                      color: Color(0xFF3A2E39),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to Philosophy Bot',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Ask me anything about philosophy, psychology, or spirituality.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessage(message);
                },
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Ask a philosophical question...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onSubmitted: _isLoading ? null : _handleSubmitted,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed:
                        _isLoading
                            ? null
                            : () => _handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.psychology, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        message.isUser
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (message.sources != null && message.sources!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                    child: Text(
                      'Sources: ${message.sources!.join(", ")}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
