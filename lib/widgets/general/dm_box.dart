import 'package:flutter/material.dart';
import 'package:campusmate/screens/general/chat_screen.dart';

class DM_Box extends StatelessWidget {
  const DM_Box({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Open chat screen logic here
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudyGroupScreen()),
        );
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.1,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        color: Color(int.parse('0xFFF1EAD8')),
        child: Container(
          margin: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/images/chatbox_pfpic.png'),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Username',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Last message preview...',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '2:30 PM',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  height: MediaQuery.of(context).size.height * 0.0001,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
