import "package:flutter/material.dart";

class TextBubble extends StatelessWidget {
  const TextBubble({super.key});

  // Displays the text in the chat screen
  final String displayedText = "Testing purposes...";

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.06,
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFFD5C7AD),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Text(
          displayedText,
          style: const TextStyle(color: Colors.black12, fontSize: 16.0),
        ),
      ),
    );
  }
}
