import 'package:flutter/material.dart';

class ChatscrTopBar extends StatelessWidget {
  const ChatscrTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(int.parse('0xFFBEC5A4')),
      title: SizedBox(
        height: MediaQuery.of(context).size.height * 0.05,
        width: MediaQuery.of(context).size.width * 0.7,
        child: Row(
          // profile picture
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/chatbox_pfpic.png'),
            ),
            SizedBox(width: 8),
            Text('User Name', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
