import "package:flutter/material.dart";


class TextBubble extends StatelessWidget {
  final String displayedText;

  const TextBubble({super.key, required this.displayedText});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F22),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Text(
          displayedText,
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
    );
  }
}
