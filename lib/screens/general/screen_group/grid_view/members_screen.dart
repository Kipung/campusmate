import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:campusmate/models/user_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:campusmate/models/groups.dart';
import "package:firebase_auth/firebase_auth.dart";

// After clicking on a group member from the MembersScreen,
class MembersScreen extends StatefulWidget {
  final List<UserProfile> members;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Get the avatar URL for a member
  Future<String> memberAvatarUrl(String memberId) async {
    final ref = storage.ref('members/$memberId/avatar.jpg');
    return ref.getDownloadURL(); // feed into Image.network
  }

  // Upload or update a member's avatar
  Future<String> uploadMemberAvatar(String memberId, File file) async {
    final ref = storage.ref('members/$memberId/avatar.jpg');
    await ref.putFile(file); // or putData(Uint8List)
    return ref.getDownloadURL(); // store URL in Firestore
  }

  MembersScreen({Key? key, required this.members}) : super(key: key);

  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Members')),
      body: ListView.builder(
        itemCount: widget.members.length,
        itemBuilder: (context, index) {
          final member = widget.members[index];
          // Return a ListTile for each member
          return ListTile(
            leading: FutureBuilder<String>(
              future: widget.memberAvatarUrl(member.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CircleAvatar(
                    backgroundImage: NetworkImage(snapshot.data!),
                  );
                }
                if (snapshot.hasError) {
                  return CircleAvatar(child: const Icon(Icons.person_off));
                }
                return CircleAvatar(
                  child: Text('${member.firstName[0]}${member.lastName[0]}'),
                );
              },
            ),
            title: Text(member.firstName + ' ' + member.lastName),
            subtitle: Text(member.email),
          );
        },
      ),
    );
  }
}
