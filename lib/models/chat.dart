// -----------------------------------------------------------------------
// Filename: chat.dart
// Description: Model for a chat (conversation) with Firestore (de)serialization.

import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  String _id = '';
  List<String> _participants = [];
  String _pairKey = '';
  String _lastMessage = '';
  int _createdAt = 0; // ms since epoch
  int _lastUpdated = 0; // ms since epoch
  Map<String, int> _unread = {};

  Chat(
    this._id,
    this._participants,
    this._pairKey,
    this._lastMessage,
    this._createdAt,
    this._lastUpdated,
    this._unread,
  );

  Chat.empty();

  Chat.defFromJsonDbObject(Map<String, dynamic> jsonObject, String id) {
    _id = id;
    _participants = List<String>.from(jsonObject['participants'] ?? const []);
    _pairKey = jsonObject['pair_key'] ?? '';
    _lastMessage = jsonObject['last_message'] ?? '';

    final ca = jsonObject['created_at'];
    if (ca is int) {
      _createdAt = ca;
    } else if (ca is Timestamp) {
      _createdAt = ca.millisecondsSinceEpoch;
    } else if (ca is DateTime) {
      _createdAt = ca.millisecondsSinceEpoch;
    } else {
      _createdAt = 0;
    }

    final lu = jsonObject['last_updated'];
    if (lu is int) {
      _lastUpdated = lu;
    } else if (lu is Timestamp) {
      _lastUpdated = lu.millisecondsSinceEpoch;
    } else if (lu is DateTime) {
      _lastUpdated = lu.millisecondsSinceEpoch;
    } else {
      _lastUpdated = 0;
    }

    final rawUnread = Map<String, dynamic>.from(jsonObject['unread'] ?? {});
    _unread = rawUnread.map((k, v) => MapEntry(k, (v is int) ? v : 0));
  }

  // Getters
  String get id => _id;
  List<String> get participants => _participants;
  String get pairKey => _pairKey;
  String get lastMessage => _lastMessage;
  int get createdAt => _createdAt;
  int get lastUpdated => _lastUpdated;
  Map<String, int> get unread => _unread;

  Map<String, dynamic> toJsonForDb() {
    final json = <String, dynamic>{};
    json['participants'] = _participants;
    json['pair_key'] = _pairKey;
    json['last_message'] = _lastMessage;
    json['created_at'] = _createdAt;
    json['last_updated'] = _lastUpdated;
    json['unread'] = _unread;
    return json;
  }
}

