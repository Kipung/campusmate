// -----------------------------------------------------------------------
// Filename: provider_chats.dart
// Description: Provider managing chat state, subscriptions, and actions.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../db_helpers/db_chat.dart';
import '../util/logging/app_logger.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ProviderChats extends ChangeNotifier {
  // Chats list for the current user
  final List<Chat> _chats = [];
  bool _chatsLoaded = false;

  // Messages per chatId
  final Map<String, List<Message>> _messagesByChat = {};

  // Subscriptions
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?>
      _messageSubs = {};

  bool get chatsLoaded => _chatsLoaded;
  List<Chat> get chats => List.unmodifiable(_chats);
  List<Message> messagesFor(String chatId) =>
      List.unmodifiable(_messagesByChat[chatId] ?? const []);

  @override
  void dispose() {
    _chatsSub?.cancel();
    for (final sub in _messageSubs.values) {
      sub?.cancel();
    }
    super.dispose();
  }

  Future<void> startChatsStream() async {
    await _chatsSub?.cancel();
    _chatsSub = DbChat.listenUserChats().listen(
      (snap) {
        _chats
          ..clear()
          ..addAll(snap.docs.map((d) => Chat.defFromJsonDbObject(d.data(), d.id)));
        _chatsLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        AppLogger.error('Chats stream error: $e');
      },
    );
  }

  Future<void> stopChatsStream() async {
    await _chatsSub?.cancel();
    _chatsSub = null;
    _chatsLoaded = false;
    _chats.clear();
    notifyListeners();
  }

  Future<void> openMessagesStream(String chatId, {int limit = 50}) async {
    await _messageSubs[chatId]?.cancel();
    _messageSubs[chatId] = DbChat.listenMessages(chatId, limit: limit).listen(
      (snap) {
        _messagesByChat[chatId] = snap.docs
            .map((d) => Message.defFromJsonDbObject(d.data(), d.id, chatId))
            .toList();
        notifyListeners();
      },
      onError: (e) => AppLogger.error('Messages stream error ($chatId): $e'),
    );
  }

  Future<void> closeMessagesStream(String chatId) async {
    await _messageSubs[chatId]?.cancel();
    _messageSubs.remove(chatId);
    _messagesByChat.remove(chatId);
    notifyListeners();
  }

  Future<void> sendMessageText(String chatId, String text) async {
    if (text.trim().isEmpty) return;
    await DbChat.sendMessageText(chatId, text.trim());
  }
}
