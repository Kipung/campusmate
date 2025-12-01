import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../util/logging/app_logger.dart';
import 'firestore_keys.dart';

class DbChat {
  // Current user's UID getter
  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  // 1) Create or reuse a direct chat between the current user and otherUserId
  static Future<String> createDirectChat(String otherUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;

    // Deterministic key to dedupe 1:1 chats
    final pair = [uid, otherUserId]..sort();
    final pairKey = pair.join('_');
    final db = FirebaseFirestore.instance;

    // Try to find existing chat
    final existing = await db
        .collection(FS_COL_CHATS)
        .where('participants', arrayContains: uid)
        .where('pair_key', isEqualTo: pairKey)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create new chat
    final ref = await db.collection(FS_COL_CHATS).add({
      'participants': pair,
      'pair_key': pairKey,
      'created_at': FieldValue.serverTimestamp(),
      'last_updated': FieldValue.serverTimestamp(),
      'last_message': null,
      'unread': {uid: 0, otherUserId: 0},
    });

    AppLogger.print('Chat created: ${ref.id}');
    return ref.id;
  }

  // Create a group chat with participants
  static Future<String> createGroupChat(List<String> participantIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;

    final participantsSet = <String>{...participantIds, uid};
    final participants = List<String>.from(participantsSet);
    final sortedParticipants = List<String>.from(participants)..sort();
    final groupKey = sortedParticipants.join('_');
    final db = FirebaseFirestore.instance;

    // Try to reuse an existing group chat with the same participant set
    final existing = await db
        .collection(FS_COL_CHATS)
        .where('participants', arrayContains: uid)
        .where('is_group', isEqualTo: true)
        .where('group_key', isEqualTo: groupKey)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create new group chat
    final ref = await db.collection(FS_COL_CHATS).add({
      'participants': participants,
      'group_key': groupKey,
      'is_group': true,
      'created_at': FieldValue.serverTimestamp(),
      'created_by': uid,
      'last_updated': FieldValue.serverTimestamp(),
      'last_message': null,
      'unread': {for (var p in participants) p: 0},
    });

    if (!participants.contains(uid)) throw Exception('Not a chat member');

    AppLogger.print('Group chat created: ${ref.id}');
    return ref.id;
  }

  // 2) Send a text message; atomically update last_message/last_updated and unread counts
  static Future<void> sendMessageText(String chatId, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;
    final db = FirebaseFirestore.instance;
    final chatDoc = db.collection(FS_COL_CHATS).doc(chatId);
    final msgCol = chatDoc.collection(FS_COL_CHAT_MESSAGES);

    await db.runTransaction((txn) async {
      final chatSnap = await txn.get(chatDoc);
      if (!chatSnap.exists) {
        throw Exception('Chat not found: $chatId');
      }
      final chatData =
          (chatSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
      final participants = List<String>.from(
        chatData['participants'] ?? <String>[],
      );

      // Prepare message
      final msgRef = msgCol.doc();
      txn.set(msgRef, {
        'sender_id': uid,
        'text': text,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      // Update chat aggregate fields
      final unread = Map<String, dynamic>.from(chatData['unread'] ?? {});
      for (final p in participants) {
        if (p == uid) {
          unread[p] = 0;
        } else {
          final curr = unread[p] is int ? unread[p] as int : 0;
          unread[p] = curr + 1;
        }
      }
      txn.update(chatDoc, {
        'last_message': text,
        'last_updated': FieldValue.serverTimestamp(),
        'unread': unread,
      });
    });
  }

  // 2b) Send an image message; upload to Storage then write message with image_url
  static Future<void> sendMessageImage(String chatId, XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;
    final db = FirebaseFirestore.instance;
    final chatDoc = db.collection(FS_COL_CHATS).doc(chatId);
    final msgCol = chatDoc.collection(FS_COL_CHAT_MESSAGES);

    // Upload to Storage first
    final msgRef = msgCol.doc();
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chats/$chatId/messages/${msgRef.id}.jpg');
    final bytes = await file.readAsBytes();
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await storageRef.getDownloadURL();

    await db.runTransaction((txn) async {
      final chatSnap = await txn.get(chatDoc);
      if (!chatSnap.exists) {
        throw Exception('Chat not found: $chatId');
      }
      final chatData =
          (chatSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
      final participants = List<String>.from(
        chatData['participants'] ?? <String>[],
      );

      txn.set(msgRef, {
        'sender_id': uid,
        'text': '',
        'image_url': downloadUrl,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      final unread = Map<String, dynamic>.from(chatData['unread'] ?? {});
      for (final p in participants) {
        if (p == uid) {
          unread[p] = 0;
        } else {
          final curr = unread[p] is int ? unread[p] as int : 0;
          unread[p] = curr + 1;
        }
      }
      txn.update(chatDoc, {
        'last_message': '[Image]',
        'last_updated': FieldValue.serverTimestamp(),
        'unread': unread,
      });
    });
  }

  // 2c) Send a file message; upload to Storage then write message with file_url and metadata
  static Future<void> sendMessageFile(String chatId, PlatformFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;
    final db = FirebaseFirestore.instance;
    final chatDoc = db.collection(FS_COL_CHATS).doc(chatId);
    final msgCol = chatDoc.collection(FS_COL_CHAT_MESSAGES);

    // Load file bytes (file_picker may provide bytes directly; otherwise read from path)
    final bytes =
        file.bytes ?? await File(file.path!).readAsBytes(); // path should exist on mobile/desktop

    final msgRef = msgCol.doc();
    final filename = file.name;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chats/$chatId/messages/${msgRef.id}/$filename');
    await storageRef.putData(
      bytes,
      SettableMetadata(
        // file_picker 10.3.x PlatformFile lacks mimeType; default to octet-stream.
        contentType: 'application/octet-stream',
      ),
    );
    final downloadUrl = await storageRef.getDownloadURL();

    await db.runTransaction((txn) async {
      final chatSnap = await txn.get(chatDoc);
      if (!chatSnap.exists) {
        throw Exception('Chat not found: $chatId');
      }
      final chatData =
          (chatSnap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
      final participants = List<String>.from(
        chatData['participants'] ?? <String>[],
      );

      txn.set(msgRef, {
        'sender_id': uid,
        'text': '',
        'file_url': downloadUrl,
        'file_name': filename,
        'file_size': file.size,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      final unread = Map<String, dynamic>.from(chatData['unread'] ?? {});
      for (final p in participants) {
        if (p == uid) {
          unread[p] = 0;
        } else {
          final curr = unread[p] is int ? unread[p] as int : 0;
          unread[p] = curr + 1;
        }
      }
      txn.update(chatDoc, {
        'last_message': '[File] $filename',
        'last_updated': FieldValue.serverTimestamp(),
        'unread': unread,
      });
    });
  }

  // 3) Stream the current user's chats (listens for updates)
  static Stream<QuerySnapshot<Map<String, dynamic>>> listenUserChats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    final uid = user.uid;
    final db = FirebaseFirestore.instance;
    return db
        .collection(FS_COL_CHATS)
        .where('participants', arrayContains: uid)
        .orderBy('last_updated', descending: true)
        .snapshots();
  }

  // 4) Stream messages for a chat (ascending by created_at)
  static Stream<QuerySnapshot<Map<String, dynamic>>> listenMessages(
    String chatId, {
    int limit = 50,
  }) {
    final db = FirebaseFirestore.instance;
    return db
        .collection(FS_COL_CHATS)
        .doc(chatId)
        .collection(FS_COL_CHAT_MESSAGES)
        .orderBy('created_at', descending: false)
        .limit(limit)
        .snapshots();
  }

  // 5) Mark a chat as read for the current user (zero unread count)
  static Future<void> markRead(String chatId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final db = FirebaseFirestore.instance;
    await db.collection(FS_COL_CHATS).doc(chatId).set({
      'unread': {uid: 0},
    }, SetOptions(merge: true));
  }
}
