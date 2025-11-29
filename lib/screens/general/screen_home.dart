// -----------------------------------------------------------------------
// Filename: screen_home.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the screen for a dummy home screen
//               history screen.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////

// Flutter imports
import 'dart:async';
import 'dart:convert';
import 'dart:math';

// Flutter external package imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// App relative file imports
import '../../db_helpers/firestore_keys.dart';
import '../../services/friend_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/general/recommended_user.dart';

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenHome extends ConsumerStatefulWidget {
  static const routeName = '/home';

  @override
  ConsumerState<ScreenHome> createState() => _ScreenHomeState();
}

//////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
class _ScreenHomeState extends ConsumerState<ScreenHome> {
  // The "instance variables" managed in this state
  bool _isInit = true;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      _recommendedUsersStream;
  final FriendService _friendService = FriendService();
  UserProfile? _currentUserProfile;
  bool _statsLoading = true;
  int _groupsJoined = 0;
  int _friendCount = 0;
  int _pendingRequests = 0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _groupsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingSub;

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
    _recommendedUsersStream = FirebaseFirestore.instance
        .collection(FS_COL_IC_USER_PROFILES)
        .limit(12)
        .snapshots();
    super.initState();
  }

  ////////////////////////////////////////////////////////////////
  // Initializes state variables and resources
  ////////////////////////////////////////////////////////////////
  Future<void> _init() async {
    _setupDashboardListeners();
  }

  void _setupDashboardListeners() {
    _profileSub?.cancel();
    _friendsSub?.cancel();
    _groupsSub?.cancel();
    _pendingSub?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
      });
      return;
    }

    final profileDocRef = FirebaseFirestore.instance
        .collection(FS_COL_IC_USER_PROFILES)
        .doc(user.uid);
    _profileSub = profileDocRef.snapshots().listen((snapshot) {
      if (!mounted) return;
      if (snapshot.data() != null) {
        final profile = UserProfile.defFromJsonDbObject(
          snapshot.data()!,
          snapshot.id,
        );
        setState(() {
          _currentUserProfile = profile;
          _statsLoading = false;
        });
      }
    });

    final friendsCol = profileDocRef.collection('friends');
    _friendsSub = friendsCol.snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _friendCount = snapshot.size;
        _statsLoading = false;
      });
    });

    _groupsSub = FirebaseFirestore.instance
        .collection(FS_COL_IC_GROUPS)
        .where('members', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _groupsJoined = snapshot.size;
        _statsLoading = false;
      });
    });

    _pendingSub = FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _pendingRequests = snapshot.size;
        _statsLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _friendsSub?.cancel();
    _groupsSub?.cancel();
    _pendingSub?.cancel();
    super.dispose();
  }

  //////////////////////////////////////////////////////////////////////////
  // Primary Flutter method overridden which describes the layout and bindings for this widget.
  //////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    // Return the scaffold
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(context),
            const SizedBox(height: 18.0),
            _buildQuoteCard(context),
            const SizedBox(height: 22.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'People You May Know',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            // Horizontal scrollable list of RecommendedUser widgets
            _buildRecommendedUsersCarousel(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD5C7AD),
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
            color: const Color(0xFFF1EAD8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<String>(
                future: DefaultAssetBundle.of(
                  context,
                ).loadString('assets/motivational_quotes.json'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return const Text(
                      'Could not load quote',
                      style: TextStyle(fontSize: 20.0),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  final List<dynamic> quotes = jsonDecode(snapshot.data!);
                  final quoteText = quotes.isNotEmpty
                      ? quotes[Random().nextInt(quotes.length)].toString()
                      : 'No quotes available';

                  return Text(
                    quoteText,
                    style: const TextStyle(fontSize: 20.0),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              const SizedBox(height: 8.0),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '- Somebody Famous',
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = _currentUserProfile?.firstName.trim();
    final greetingName = (firstName != null && firstName.isNotEmpty)
        ? firstName
        : (FirebaseAuth.instance.currentUser?.email ?? 'there');
    final avatarLetter =
        greetingName.isNotEmpty ? greetingName[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  avatarLetter,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      greetingName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_statsLoading)
            const SizedBox(
              height: 52,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    label: 'Groups',
                    value: _groupsJoined.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickStatCard(
                    label: 'Friends',
                    value: _friendCount.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickStatCard(
                    label: 'Requests',
                    value: _pendingRequests.toString(),
                    highlight: _pendingRequests > 0,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedUsersCarousel() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _recommendedUsersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Unable to load suggested students.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final users = docs.where((doc) => doc.id != currentUid).take(10).toList();
        if (users.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'No new students to suggest yet.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        return SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data();
              final firstName = (data['first_name'] ?? '').toString();
              final lastName = (data['last_name'] ?? '').toString();
              final major = (data['major'] ?? 'Undeclared').toString();
              final displayName = '$firstName $lastName'.trim().isEmpty
                  ? 'CampusMate User'
                  : '$firstName $lastName'.trim();
              final tagsRaw = data['personality_traits'];
              final tags = tagsRaw is List ? List<String>.from(tagsRaw) : <String>[];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showUserProfileSheet(doc.id, data),
                  child: RecommendedUser(
                    displayName: displayName,
                    subtitle: major.isEmpty ? 'Undeclared' : major,
                    tags: tags,
                    actionArea: _buildRecommendationActions(
                      currentUid: currentUid,
                      userId: doc.id,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecommendationActions({
    required String? currentUid,
    required String userId,
  }) {
    if (currentUid == null || currentUid == userId) {
      return const SizedBox.shrink();
    }

    final friendDocStream = FirebaseFirestore.instance
        .collection(FS_COL_IC_USER_PROFILES)
        .doc(currentUid)
        .collection('friends')
        .doc(userId)
        .snapshots();

    final outgoingStream = _getPendingRequestStream(currentUid, userId);
    final incomingStream = _getPendingRequestStream(userId, currentUid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: friendDocStream,
      builder: (context, friendSnapshot) {
        if (friendSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final isFriend = friendSnapshot.data?.exists ?? false;
        if (isFriend) {
          return ElevatedButton.icon(
            onPressed: () => _friendService.removeFriend(
              context: context,
              myUid: currentUid,
              otherUid: userId,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            icon: const Icon(Icons.person_remove_alt_1),
            label: const Text('Remove Friend'),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: outgoingStream,
          builder: (context, outgoingSnapshot) {
            if (outgoingSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final outgoingDocs = outgoingSnapshot.data?.docs ?? [];
            if (outgoingDocs.isNotEmpty) {
              return OutlinedButton(
                onPressed: () => _friendService.cancelFriendRequest(
                  context: context,
                  requestId: outgoingDocs.first.id,
                ),
                child: const Text('Cancel Request'),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: incomingStream,
              builder: (context, incomingSnapshot) {
                if (incomingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 40,
                    child:
                        Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final incomingDocs = incomingSnapshot.data?.docs ?? [];
                if (incomingDocs.isNotEmpty) {
                  final requestId = incomingDocs.first.id;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => _friendService.acceptFriendRequest(
                          context: context,
                          requestId: requestId,
                          myUid: currentUid,
                          otherUid: userId,
                        ),
                        child: const Text('Accept Request'),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _friendService.rejectFriendRequest(
                          context: context,
                          requestId: requestId,
                        ),
                        child: const Text('Ignore'),
                      ),
                    ],
                  );
                }

                return ElevatedButton(
                  onPressed: () => _friendService.sendFriendRequest(
                    context: context,
                    myUid: currentUid,
                    targetUid: userId,
                  ),
                  child: const Text('Add Friend'),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showUserProfileSheet(
    String userId,
    Map<String, dynamic> userData,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid == userId) return;

    final firstName = (userData['first_name'] ?? '').toString();
    final lastName = (userData['last_name'] ?? '').toString();
    final displayName =
        '$firstName $lastName'.trim().isEmpty ? 'CampusMate User' : '$firstName $lastName'.trim();
    final major = (userData['major'] ?? 'Undeclared').toString();
    final bio = (userData['bio'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final friendDocStream = FirebaseFirestore.instance
            .collection(FS_COL_IC_USER_PROFILES)
            .doc(currentUid)
            .collection('friends')
            .doc(userId)
            .snapshots();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 32,
                    child: Text(
                      displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    displayName,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                Center(
                  child: Text(
                    major.isEmpty ? 'Undeclared' : major,
                    style: Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bio',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  bio.isEmpty ? 'This student has not added a bio yet.' : bio,
                  style: Theme.of(sheetContext).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: friendDocStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final isFriend = snapshot.data?.exists ?? false;
                    if (isFriend) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _friendService.removeFriend(
                            context: sheetContext,
                            myUid: currentUid,
                            otherUid: userId,
                          ),
                          child: const Text('Remove Friend'),
                        ),
                      );
                    }
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _getPendingRequestStream(currentUid, userId),
                      builder: (context, requestSnapshot) {
                        if (requestSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final pendingDocs = requestSnapshot.data?.docs ?? [];
                        final hasPending = pendingDocs.isNotEmpty;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (hasPending) {
                                _friendService.cancelFriendRequest(
                                  context: sheetContext,
                                  requestId: pendingDocs.first.id,
                                );
                              } else {
                                _friendService.sendFriendRequest(
                                  context: sheetContext,
                                  myUid: currentUid,
                                  targetUid: userId,
                                );
                              }
                            },
                            child: Text(hasPending ? 'Cancel Request' : 'Add Friend'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getPendingRequestStream(
    String fromUid,
    String toUid,
  ) {
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('from', isEqualTo: fromUid)
        .where('to', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots();
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? Colors.white
              : Colors.white.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
