import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendService {
  FriendService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('friend_requests');

  DocumentReference<Map<String, dynamic>> _friendDoc(
    String ownerUid,
    String friendUid,
  ) =>
      _firestore
          .collection('user_profiles')
          .doc(ownerUid)
          .collection('friends')
          .doc(friendUid);

  Future<void> sendFriendRequest({
    required BuildContext context,
    required String myUid,
    required String targetUid,
  }) async {
    if (myUid == targetUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot friend yourself.')),
      );
      return;
    }

    try {
      final duplicate = await _requests
          .where('from', isEqualTo: myUid)
          .where('to', isEqualTo: targetUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request already sent.')),
        );
        return;
      }

      await _requests.add({
        'from': myUid,
        'to': targetUid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  Future<void> acceptFriendRequest({
    required BuildContext context,
    required String requestId,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      final requestRef = _requests.doc(requestId);
      await _firestore.runTransaction((txn) async {
        txn.update(requestRef, {'status': 'accepted'});
        txn.set(_friendDoc(myUid, otherUid), {
          'friendId': otherUid,
          'friendName': 'CampusMate User',
          'since': FieldValue.serverTimestamp(),
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request: $e')),
      );
    }
  }

  Future<void> rejectFriendRequest({
    required BuildContext context,
    required String requestId,
  }) async {
    try {
      await _requests.doc(requestId).update({'status': 'rejected'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request rejected.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: $e')),
      );
    }
  }

  Future<void> cancelFriendRequest({
    required BuildContext context,
    required String requestId,
  }) async {
    try {
      await _requests.doc(requestId).update({'status': 'cancelled'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request cancelled.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel request: $e')),
      );
    }
  }

  Future<void> removeFriend({
    required BuildContext context,
    required String myUid,
    required String otherUid,
  }) async {
    try {
      await _friendDoc(myUid, otherUid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove friend: $e')),
      );
    }
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamIncomingRequests(
    String myUid,
  ) {
    return _requests
        .where('to', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamOutgoingRequests(
    String myUid,
  ) {
    return _requests
        .where('from', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamFriendsList(
    String myUid,
  ) {
    return _firestore
        .collection('user_profiles')
        .doc(myUid)
        .collection('friends')
        .orderBy('since', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingRequestBetween(
    String fromUid,
    String toUid,
  ) {
    return _requests
        .where('from', isEqualTo: fromUid)
        .where('to', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots();
  }
}

/// ---------------------------------------------------------------------------
/// Example UI widgets
/// ---------------------------------------------------------------------------

class IncomingRequestsList extends StatelessWidget {
  const IncomingRequestsList({super.key, required this.myUid});

  final String myUid;

  @override
  Widget build(BuildContext context) {
    final service = FriendService();
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: service.streamIncomingRequests(myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('No incoming requests.'));
        }
        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data();
            final fromUid = data['from'] as String;
            return ListTile(
              title: Text('From: $fromUid'),
              subtitle: Text('Status: ${data['status']}'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => service.rejectFriendRequest(
                      context: context,
                      requestId: request.id,
                    ),
                    child: const Text('Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () => service.acceptFriendRequest(
                      context: context,
                      requestId: request.id,
                      myUid: myUid,
                      otherUid: fromUid,
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class OutgoingRequestsList extends StatelessWidget {
  const OutgoingRequestsList({super.key, required this.myUid});
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final service = FriendService();
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: service.streamOutgoingRequests(myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text('No outgoing requests.'));
        }
        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data();
            final toUid = data['to'] as String;
            return ListTile(
              title: Text('To: $toUid'),
              subtitle: Text('Status: ${data['status']}'),
              trailing: TextButton(
                onPressed: () => service.cancelFriendRequest(
                  context: context,
                  requestId: request.id,
                ),
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
    );
  }
}

class FriendsListView extends StatelessWidget {
  const FriendsListView({super.key, required this.myUid});
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final service = FriendService();
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: service.streamFriendsList(myUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return const Center(child: Text('No friends yet.'));
        }
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final doc = friends[index];
            final friendId = doc.id;
            final friendName = doc.data()['friendName'] as String? ?? friendId;
            return ListTile(
              title: Text(friendName),
              subtitle: Text('ID: $friendId'),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove),
                onPressed: () => service.removeFriend(
                  context: context,
                  myUid: myUid,
                  otherUid: friendId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
