import 'package:flutter/material.dart';
import 'package:campusmate/constants/group_filters.dart';
import 'package:campusmate/widgets/general/personality_tag.dart';

class PersonalityTrain extends StatefulWidget {
  /// Callback that reports the selected traits to the parent.
  final ValueChanged<List<String>>? onSelectionChanged;

  const PersonalityTrain({Key? key, this.onSelectionChanged}) : super(key: key);

  @override
  _PersonalityTrainState createState() => _PersonalityTrainState();
}

class _PersonalityTrainState extends State<PersonalityTrain> {
  // Predefined list of personality traits
  final List<String> personalityTraits = PersonalityTraits.traits;

  final Set<String> selectedTraits = {};

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...personalityTraits.map(
          (trait) => PersonalityTag(
            label: trait,
            selected: selectedTraits.contains(trait),
            onTap: () {
              setState(() {
                if (selectedTraits.contains(trait)) {
                  selectedTraits.remove(trait);
                } else {
                  selectedTraits.add(trait);
                }
                // notify parent of the updated selection
                widget.onSelectionChanged?.call(selectedTraits.toList());
              });
            },
          ),
        ),
        // "+" add button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add new personality trait tapped!'),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECE7D3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, size: 20, color: Color(0xFF2D2D1F)),
          ),
        ),
      ],
    );
  }
}
