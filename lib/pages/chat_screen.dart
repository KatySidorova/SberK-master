import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ⚙️ Настройки API
const String API_ENDPOINT =
    'https://api.intelligence.io.solutions/api/v1/chat/completions';
const String API_KEY =
    'io-v2-eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvd25lciI6IjEzYTk1NjZlLWE5OWQtNDlmYy04YzJjLTE3MDFiYWY4YjYwMCIsImV4cCI6NDkxNDQyNzEzMH0.kgDeNQVg_p26eJBtdRb73gB1VFENY1y_oAH4mb0bfj3yQc_RCgpmQNi2mhWG7RHADkIfxewLUoU8Vv62Zx72YQ';
const String MODEL_ID = 'openai/gpt-oss-120b';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _loading = false;

  final String _systemPrompt = '''
Ты — Некси 🤖, добрый помощник для детей.
Отвечай просто, понятно, дружелюбно.
Избегай сложных тем и всегда поддерживай позитив.
''';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(role: 'user', text: text, time: _now()));
      _controller.clear();
      _loading = true;
    });

    final payload = {
      "model": MODEL_ID,
      "messages": [
        {"role": "system", "content": _systemPrompt},
        ..._messages.map((m) => {"role": m.role, "content": m.text}),
      ],
      "max_tokens": 512,
      "temperature": 0.7,
    };

    try {
      final response = await http.post(
        Uri.parse(API_ENDPOINT),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $API_KEY',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content']?.toString() ??
            'Хмм... не знаю, дружок 🤔';
        setState(() {
          _messages.add(_Message(role: 'assistant', text: reply, time: _now()));
        });
      } else {
        setState(() {
          _messages.add(_Message(
              role: 'assistant',
              text: 'Ошибка ${response.statusCode}: ${response.reasonPhrase}',
              time: _now()));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          _Message(
              role: 'assistant',
              text: 'Ой, связь с сервером потерялась 😢',
              time: _now()),
        );
      });
    } finally {
      setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // ✅ теперь экран поднимается при клавиатуре
      appBar: _buildHeader(),
      body: SafeArea(
        child: Column(
          children: [
            // 📜 Сообщения
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _buildBubble(_messages[i]),
                ),
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(color: Colors.green),
              ),

            // 🔹 Поле ввода поднято над навбаром
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 80, // 🔥 отступ над волной
              ),
              child: _buildInput(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF4CAF50),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Некси',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              Text('Онлайн',
                  style: TextStyle(color: Colors.green, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Message msg) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF4CAF50),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.time,
                    style: TextStyle(
                      color:
                      (isUser ? Colors.white70 : Colors.black54),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Напишите сообщение...',
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String role;
  final String text;
  final String time;
  _Message({required this.role, required this.text, required this.time});
}
