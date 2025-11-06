import 'package:flutter/material.dart';
import 'package:campusmate/widgets/general/personality_trait.dart';
import 'package:campusmate/widgets/general/personality_tag.dart';

class StudyGroupScreen extends StatefulWidget {
  const StudyGroupScreen({super.key});

  @override
  State<StudyGroupScreen> createState() => _StudyGroupScreenState();
}

class _StudyGroupScreenState extends State<StudyGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  var _selectedTraits = <String>{};
  var _isSending = false;
  // Save group
  void _saveGroup() {
    // Logic to save the group would go here
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        // Update state or perform actions with the entered data
        _isSending = true;
      });

      final Map<String, dynamic> groupData = {
        'groupName': _nameController.text.trim(),
        'groupDescription': _descriptionController.text.trim(),
        'major': _majorController.text.trim(),
        'personalityTraits': _selectedTraits.toList(),
      };
      Navigator.pop(context, groupData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Study Group')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Group description',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _majorController,
              decoration: const InputDecoration(
                labelText: 'Major',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Personality',
              style: TextStyle(
                color: Color(0xFF2D2D1F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          PersonalityTrain(),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final String name = _nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }

              // Return the entered data to the previous screen
              Navigator.pop<Map<String, dynamic>>(context, {
                'groupName': name,
                'description': _descriptionController.text.trim(),
                'major': _majorController.text.trim(),
              });
            },
            child: _isSending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create Group'),
          ),
        ],
      ),
    );
  }
}
