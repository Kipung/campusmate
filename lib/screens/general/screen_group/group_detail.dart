// this is going to be a file that defines the screen for group details
import 'package:flutter/material.dart';
import 'package:campusmate/models/groups.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
<<<<<<< HEAD
=======
import 'package:campusmate/screens/general/screen_group/grid_view/members_screen.dart';
import 'package:campusmate/screens/general/screen_group/calendar_screen.dart';
>>>>>>> 8386386 (worked on schedule calendar)

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
  late Groups group;

  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    group = widget.group;
  }

  @override
  Widget build(BuildContext context) {
    // final groupsProvider = ref.watch(providerGroups);
    final int memberCount = group.members.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.groupName),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1st row: group name logo and some basic info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    group.groupName.isNotEmpty
                        ? group.groupName[0].toUpperCase()
                        : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Group Description and Member Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Name
                      Text(
                        group.groupName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      // Group Description
                      Text(
                        group.groupDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      // count the group and save it into a local variable
                      Text(
                        'Members: ${memberCount.toString()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // From here, grid square tiles of buttons with clickable animations for different features such as members, anouncements, events, settings, etc.
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Members Tile
                  GestureDetector(
                    onTap: () {
                      // Navigate to members screen
                      context.push('/group/${group.groupId}/members');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        // Icon and text for members
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group,
                              size: 40,
                              color: Colors.blue.shade700,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Members',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Announcements Tile
                  GestureDetector(
                    onTap: () {
                      // Navigate to announcements screen
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        // Icon and text for announcements
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.announcement,
                              size: 40,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Announcements',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Events Tile
                  GestureDetector(
                    onTap: () {
                      // Navigate to events screen
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        // Icon and text for events
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              size: 40,
                              color: Colors.orange.shade700,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Schedules',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Files Tile
                  GestureDetector(
                    onTap: () {
                      // Navigate to files screen
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        // Icon and text for files
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder,
                              size: 40,
                              color: Colors.purple.shade700,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Files',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Calendar Tile
                  GestureDetector(
                    onTap: () {
                      // Navigate to calendar screen
                      context.push(CalendarScreen.routeName, extra: group);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        // Icon and text for calendar
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 40,
                              color: Colors.teal.shade700,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Calendar',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Settings Tile
                  GestureDetector(
                    onTap: () {
                      // Navigate to settings screen
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        // Icon and text for settings
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings,
                              size: 40,
                              color: Colors.red.shade700,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Settings',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
