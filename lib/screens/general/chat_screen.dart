import 'package:flutter/material.dart';
import 'package:campusmate/widgets/general/chatscr_top_bar.dart';
import 'package:campusmate/widgets/general/chatscr_textbar.dart';
import 'package:campusmate/widgets/general/chatscr_usrtextbbl.dart';
import 'package:campusmate/db_helpers/db_chat.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ChatscrTopBar(),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: DbChat.listenMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = (data['text'] as String?) ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(child: TextBubble(displayedText: text)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ChatscrTextbar(
            onSend: (msg) async {
              final text = msg.trim();
              if (text.isEmpty) return;
              try {
                await DbChat.sendMessageText(widget.chatId, text);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
              }
            },
          ),
        ],
      ),
    );
  }
}
