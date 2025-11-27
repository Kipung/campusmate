import "package:flutter/material.dart";


// Text bubble widget that is responsive to text length
class UsrTextBubble extends StatefulWidget {
  final String displayedText;

  const UsrTextBubble({super.key, required this.displayedText});

  @override
  State<UsrTextBubble> createState() => _UsrTextBubbleState();
}

class _UsrTextBubbleState extends State<UsrTextBubble> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Let the bubble size to its child but cap max width to a percentage of screen
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F22),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Text(
          widget.displayedText,
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
    );
  }
}
