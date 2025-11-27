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

// Flutter external package imports
import 'package:campusmate/db_helpers/db_chat.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// App relative file imports
import '../../../util/message_display/snackbar.dart';
import '../../../main.dart';

import 'package:campusmate/screens/general/screen_group/study_group_screen.dart';
import 'package:campusmate/db_helpers/db_groups.dart';
import 'package:campusmate/models/groups.dart';
import 'package:campusmate/constants/group_filters.dart';
import 'package:campusmate/screens/general/screen_group/group_detail.dart';

import 'package:go_router/go_router.dart';

// Go

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenGroups extends ConsumerStatefulWidget {
  const ScreenGroups({super.key});

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
  final List<String> selectableTraits = PersonalityTraits.traits;

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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    void openStudyGroupScreen() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudyGroupScreen()),
      );
    }

    Future<void> confirmDeleteGroup(Groups group) async {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete group?'),
              content: Text('Remove "${group.groupName}" for all members?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      final success = await DbGroups.deleteGroup(group.groupId);
      if (!context.mounted) return;
      if (success) {
        Snackbar.show(SnackbarDisplayType.SB_SUCCESS, 'Group deleted', context);
      } else {
        Snackbar.show(
          SnackbarDisplayType.SB_ERROR,
          'Failed to delete group. Try again.',
          context,
        );
      }
    }

    Widget buildEmptyState() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups_outlined, size: 64, color: Colors.grey[500]),
              const SizedBox(height: 16),
              const Text(
                'No study groups yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the + button to start a group.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    Widget buildGroupsList() {
      final groups = groupsProvider.groupsList;
      return ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final group = groups[index];
          final isOwner = group.ownerId == currentUserId;
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.group)),
              title: Text(group.groupName),
              subtitle: Text(
                group.groupDescription.isEmpty
                    ? 'No description provided'
                    : group.groupDescription,
              ),
              trailing: isOwner
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.redAccent,
                      tooltip: 'Delete group',
                      onPressed: () => confirmDeleteGroup(group),
                    )
                  : null,
              onTap: () =>
                  context.push(ScreenGroupsDetail.routeName, extra: group),
            ),
          );
        },
      );
    }

    Widget buildBody() {
      if (!groupsProvider.dataLoaded) {
        return const Center(child: CircularProgressIndicator());
      }
      if (groupsProvider.groupsList.isEmpty) {
        return buildEmptyState();
      }
      return buildGroupsList();
    }

    // Return the scaffold
    return Scaffold(
      // Floating action button to create a new study group
      floatingActionButton: FloatingActionButton(
        shape: ShapeBorder.lerp(CircleBorder(), StadiumBorder(), 0.5),
        onPressed: () => openStudyGroupScreen(),
        splashColor: Theme.of(context).primaryColor,
        child: Icon(FontAwesomeIcons.plus),
      ),
      body: buildBody(),
    );
  }
}
