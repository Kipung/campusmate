import 'package:flutter/material.dart';

class ChatscrTextbar extends StatelessWidget {
  const ChatscrTextbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Color(int.parse('0xFFBEC5A4')),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.image)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.file_copy)),
          IconButton(icon: const Icon(Icons.send), onPressed: () {}),
        ],
      ),
    );
  }
}
