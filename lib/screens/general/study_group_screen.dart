import 'package:flutter/material.dart';
import 'package:campusmate/widgets/general/personality_trait.dart';
import 'package:campusmate/db_helpers/db_groups.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusmate/models/groups.dart';

class StudyGroupScreen extends StatefulWidget {
  const StudyGroupScreen({super.key});

  @override
  State<StudyGroupScreen> createState() => _StudyGroupScreenState();
}

class _StudyGroupScreenState extends State<StudyGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  List<String> _selectedPersonalityTraits = [];
  List<String> _selectedMajors = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _onCreatePressed() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required to create a group.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }
    final uid = user.uid;

    final name = _groupNameController.text.trim();
    final description = _groupDescriptionController.text.trim();
    final majors = (_selectedMajors.isNotEmpty)
        ? _selectedMajors.map((s) => s.trim()).toList()
        : [_majorController.text.trim()].where((s) => s.isNotEmpty).toList();
    final traits = _selectedPersonalityTraits;

    final group = Groups(
      '', // empty groupId -> DbGroups will create a new doc
      uid, // ownerId
      name,
      description,
      [uid], // initial members (creator included)
      traits,
      majors,
      PermissionLevel.PRODUCTION,
      0, // createdAt, server sets timestamp
    );

    try {
      final success = await DbGroups.writeGroup(group);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group created')));
        Navigator.of(
          context,
        ).pop(); // close the create screen; provider listener will update list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group. Try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Study Group')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a group name'
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _groupDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Group description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
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
            PersonalityTrain(
              onSelectionChanged: (list) =>
                  setState(() => _selectedPersonalityTraits = list),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _onCreatePressed,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
