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
import '../../main.dart';

import 'package:campusmate/widgets/general/groupscr_box.dart';
import 'package:campusmate/screens/general/study_group_screen.dart';

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenGroups extends ConsumerStatefulWidget {
  static const routeName = '/groups';

  @override
  ConsumerState<ScreenGroups> createState() => _ScreenGroupsState();
}

//////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
class _ScreenGroupsState extends ConsumerState<ScreenGroups> {
  // The "instance variables" managed in this state
  bool _isInit = true;

  // List of selectable traits to filter groups by
   final List<String> personalityTraits = [
    'Calm',
    'Organized',
    'Social',
    'Optimistic',
    'Detail-Oriented',
    'Creative',
    'Analytical',
    'Dependable',
    'Adaptable',
    'Motivated',
    'Patient',
    'Welcoming',
    'Spontaneous',
  ];

  // List of selected personality traits to filter groups by
   final List<String> selectedTraits = [];

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
    final groupsProvider = ref.watch(providerGroups);
    void _openStudyGroupScreen() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudyGroupScreen()),
      );
    }

    // Return the scaffold
    return Scaffold(
      // Floating action button to create a new study group
      floatingActionButton: FloatingActionButton(
        shape: ShapeBorder.lerp(CircleBorder(), StadiumBorder(), 0.5),
        onPressed: () => _openStudyGroupScreen(),
        splashColor: Theme.of(context).primaryColor,
        child: Icon(FontAwesomeIcons.plus),
      ),
      body: groupsProvider.dataLoaded
          ? ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: groupsProvider.groupsList.length,
              itemBuilder: (context, index) {
                final g = groupsProvider.groupsList[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/group_pfpic.png',
                    ),
                  ),
                  title: Text(g.groupName),
                  subtitle: Text(g.groupDescription),
                  onTap: () {
                    // TODO: navigate to group detail
                  },
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
