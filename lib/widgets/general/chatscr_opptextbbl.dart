import "package:flutter/material.dart";

// Text bubble widget that is responsive to text length
class OppTextBubble extends StatefulWidget {
  final String displayedText;

  const OppTextBubble({super.key, required this.displayedText});

  @override
  State<OppTextBubble> createState() => _OppTextBubbleState();
}

class _OppTextBubbleState extends State<OppTextBubble> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD5C7AD),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Text(
          widget.displayedText,
          style: const TextStyle(color: Colors.black, fontSize: 16.0),
        ),
      ),
    );
  }
}
