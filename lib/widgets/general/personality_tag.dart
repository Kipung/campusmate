import 'package:flutter/material.dart';

class PersonalityTag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PersonalityTag({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D2D1F) : const Color(0xFFECE7D3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF2D2D1F),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
