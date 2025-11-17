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

  ////////////////////////////////////////////////////////////////
  // Initializes state variables and resources
  ////////////////////////////////////////////////////////////////
  Future<void> _init() async {}

  //////////////////////////////////////////////////////////////////////////
  // Primary Flutter method overridden which describes the layout and bindings for this widget.
  //////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(int.parse('0xFFD5C7AD')),
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
      body: ListView.builder(
        itemCount: 1, // Example item count
        itemBuilder: (context, index) {
          return const DM_Box(otherUid: 'other_user_uid');
        },
      ),
    );
  }
}
