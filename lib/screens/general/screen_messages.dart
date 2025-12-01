// -----------------------------------------------------------------------
// Filename: screen_alternative.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the screen for a dummy alternative screen
//               history screen.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////

// Flutter imports
import 'dart:async';

// Flutter external package imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// App relative file imports
import '../../util/message_display/snackbar.dart';

import '../../widgets/general/dm_box.dart';
import 'package:campusmate/db_helpers/db_chat.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenMessages extends ConsumerStatefulWidget {
  static const routeName = '/messages';
  final String? initialChatId;
  const ScreenMessages({super.key, this.initialChatId});

  @override
  ConsumerState<ScreenMessages> createState() => _ScreenMessagesState();
}

//////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
class _ScreenMessagesState extends ConsumerState<ScreenMessages> {
  // The "instance variables" managed in this state
  bool _isInit = true;
  String? _initialChatId;
  final TextEditingController _dmUidController = TextEditingController();
  bool _isStartingDm = false;

  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void didChangeDependencies() {
    // If first time running this code, update provider settings
    if (_isInit) {
      _init();
      _isInit = false;
      super.didChangeDependencies();
    }
  }

  @override
  void initState() {
    _initialChatId = widget.initialChatId;
    super.initState();
  }

  @override
  void dispose() {
    _dmUidController.dispose();
    super.dispose();
  }

  ////////////////////////////////////////////////////////////////
  // Initializes state variables and resources
  ////////////////////////////////////////////////////////////////
  Future<void> _init() async {}

  //////////////////////////////////////////////////////////////////////////
  // Primary Flutter method overridden which describes the layout and bindings for this widget.
  //////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(int.parse('0xFFBEC5A4')),
        title: SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
          width: MediaQuery.of(context).size.width * 0.7,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search DMs',
              filled: true,
              fillColor: Color(int.parse('0xFF99A07F')),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(color: Colors.white),
              contentPadding: EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: DbChat.listenUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!.docs
              .where((d) => !(d.data()['is_group'] == true))
              .map((d) => d.data())
              .where((data) {
            final participants =
                List<String>.from(data['participants'] ?? const []);
            return participants.any((id) => id != currentUid);
          }).toList();
          if (chats.isEmpty) {
            return const Center(child: Text('No DMs yet. Start one!'));
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants =
                  List<String>.from(chat['participants'] ?? const []);
              final otherUid = participants
                  .firstWhere((id) => id != currentUid, orElse: () => '');
              if (otherUid.isEmpty) {
                return const SizedBox.shrink();
              }
              return DM_Box(otherUid: otherUid);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isStartingDm
            ? null
            : () async {
                await _showStartDmDialog(context);
              },
        icon: const Icon(Icons.chat),
        label: _isStartingDm
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Start a DM'),
      ),
    );
  }

  Future<void> _showStartDmDialog(BuildContext context) async {
    _dmUidController.clear();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a DM'),
        content: TextField(
          controller: _dmUidController,
          decoration: const InputDecoration(
            labelText: 'Recipient UID',
            hintText: 'Enter user UID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final otherUid = _dmUidController.text.trim();
    if (otherUid.isEmpty) return;

    setState(() => _isStartingDm = true);
    try {
      final chatId = await DbChat.createDirectChat(otherUid);
      if (!mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start DM: $e')),
      );
    } finally {
      if (mounted) setState(() => _isStartingDm = false);
    }
  }
}
