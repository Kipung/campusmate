import 'package:campusmate/widgets/general/chatscr_usrtextbbl.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

class ChatscrTextbar extends StatefulWidget {
  final ValueChanged<String>? onSend;
  final VoidCallback? onPickImage;
  final VoidCallback? onPickFile;

  const ChatscrTextbar({super.key, this.onSend, this.onPickImage, this.onPickFile});

  @override
  State<ChatscrTextbar> createState() => _ChatscrTextbarState();
}

class _ChatscrTextbarState extends State<ChatscrTextbar> {
  final queue = Queue<Widget>(); // ListQueue() by default
  final userTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.03,
        vertical: MediaQuery.of(context).size.height * 0.01,
      ),
      color: Color(int.parse('0xFFBEC5A4')),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              controller: userTextController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(int.parse('0xFF99A07F')),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.015,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onPickImage,
            icon: const Icon(Icons.image),
          ),
          IconButton(
            onPressed: widget.onPickFile,
            icon: const Icon(Icons.attach_file),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final text = userTextController.text.trim();
              if (text.isEmpty) return;

              // If a parent provided an onSend callback, call it.
              if (widget.onSend != null) {
                widget.onSend!(text);
              }

              // Optionally keep a local queue of bubbles (not displayed here)
              setState(() {
                queue.add(UsrTextBubble(displayedText: text));
              });

              userTextController.clear();
            },
          ),
        ],
      ),
    );
  }
}
