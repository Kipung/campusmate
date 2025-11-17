// this is going to be a file that defines the screen for group details
import 'package:flutter/material.dart';
import 'package:campusmate/models/groups.dart';
import 'package:campusmate/db_helpers/db_groups.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../util/message_display/snackbar.dart';
import '../../../main.dart';
import 'package:campusmate/screens/general/screen_group/study_group_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//////////////////////////////////////////////////////////////////////////
/// StateFUL widget which manages state. Simply initializes the state object.
/// ////////////////////////////////////////////////////////////////////////
class ScreenGroupsDetail extends ConsumerStatefulWidget {
  const ScreenGroupsDetail({super.key, required this.group});

  static const routeName = '/group_detail';

  final Groups group;

  @override
  ConsumerState<ScreenGroupsDetail> createState() => _ScreenGroupsDetailState();
}

//////////////////////////////////////////////////////////////////////////
/// The actual STATE which is managed by the above widget.
/// ////////////////////////////////////////////////////////////////////////
class _ScreenGroupsDetailState extends ConsumerState<ScreenGroupsDetail> {
  // The "instance variables" managed in this state
  bool _isInit = true;
  late Groups group;

  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void didChangeDependencies() {
    // If first time running this code, update provider settings
    if (_isInit) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      group = args['group'] as Groups;
      _isInit = false;
      super.didChangeDependencies();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.groupName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              group.groupDescription,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text('Members:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...group.members.map(
              (member) =>
                  Text(member, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
