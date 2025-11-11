import 'package:flutter/material.dart';
import 'package:campusmate/widgets/general/chatscr_top_bar.dart';
import 'package:campusmate/widgets/general/chatscr_textbar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ChatscrTopBar(),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Container(
              color: const Color(0xFFF1EAD8),
              // This is where chat messages would be displayed
            ),
          ),
          ChatscrTextbar(),
        ],
      ),
    );
  }
}
