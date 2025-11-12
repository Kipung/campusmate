import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../util/logging/app_logger.dart';
import 'firestore_keys.dart';

class DbChat {
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
