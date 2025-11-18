// -----------------------------------------------------------------------
// Filename: screen_home.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the primary app bar.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////
// Flutter imports

// Flutter external package imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// App relative file imports
import '../../theme/colors.dart';
import '../../services/friend_service.dart';

class WidgetPrimaryAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  // Constant parameters passedin
  final Widget title;
  final List<Widget>? actionButtons;
  bool inCurrentMeeting;

  WidgetPrimaryAppBar({
    Key? key,
    required this.title,
    this.actionButtons,
    this.inCurrentMeeting = false,
  }) : super(key: key);
  // UserData().updateProfileImage();

  @override
  ConsumerState<WidgetPrimaryAppBar> createState() => _PrimaryAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

//////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////
class _PrimaryAppBar extends ConsumerState<WidgetPrimaryAppBar> {
  // The "instance variables" managed in this state
  var _isInit = true;
  final FriendService _friendService = FriendService();

  ////////////////////////////////////////////////////////////////
  // Gets the current state of the providers for consumption on
  // this page
  ////////////////////////////////////////////////////////////////
  _init() async {
    // Get providers
  }

  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void didChangeDependencies() {
    // If first time running this code, update provider settings
    if (_isInit) {
      _init();
    }

    // Now initialized; run super method
    _isInit = false;
    super.didChangeDependencies();
  }

  ////////////////////////////////////////////////////////////////
  // Primary Flutter method overriden which describes the layout
  // and bindings for this widget.
  ////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    // Get the number of notifications

    return AppBar(
      title: widget.title,
      elevation: 0,
      actions: [
        if (FirebaseAuth.instance.currentUser != null)
          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _friendService.streamIncomingRequests(
              FirebaseAuth.instance.currentUser!.uid,
            ),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              // If there's an error from Firestore (missing index/permission), surface it so
              // the developer / user can see what's wrong instead of silently showing 0.
              if (snapshot.hasError) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      color: CustomColors.statusError,
                      tooltip: 'Friend Requests (error)',
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Notifications Error'),
                            content: SingleChildScrollView(
                              child: Text(snapshot.error.toString()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 4,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    color: CustomColors.statusError,
                    tooltip: 'Friend Requests',
                    onPressed: () =>
                        _showFriendRequestSheet(snapshot.data ?? []),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (widget.actionButtons != null)
          ...widget.actionButtons!.map((e) {
            return e;
          }).toList(),
      ],
    );
  }

  void _showFriendRequestSheet(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> requests,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        if (FirebaseAuth.instance.currentUser == null) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Please sign in to view requests.'),
          );
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            if (requests.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No pending friend requests right now.'),
              );
            }
            return ListView.separated(
              controller: controller,
              padding: const EdgeInsets.all(16.0),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final req = requests[index];
                final data = req.data();
                final fromUid = data['from'] as String? ?? 'unknown';
                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('user_profiles')
                      .doc(fromUid)
                      .get(),
                  builder: (context, profileSnapshot) {
                    final profileData = profileSnapshot.data?.data();
                    final firstName =
                        (profileData?['first_name'] ?? '').toString();
                    final lastName = (profileData?['last_name'] ?? '').toString();
                    final displayName = ('$firstName $lastName').trim().isEmpty
                        ? fromUid
                        : '$firstName $lastName'.trim();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(displayName),
                      subtitle: Text(
                        'Sent: ${(data['timestamp'] as Timestamp?)?.toDate().toLocal().toString() ?? 'Unknown'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await _friendService.rejectFriendRequest(
                                context: sheetContext,
                                requestId: req.id,
                              );
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Reject'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final myUid = FirebaseAuth.instance.currentUser!.uid;
                              await _friendService.acceptFriendRequest(
                                context: sheetContext,
                                requestId: req.id,
                                myUid: myUid,
                                otherUid: fromUid,
                              );
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
