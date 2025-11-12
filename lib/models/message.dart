// -----------------------------------------------------------------------
// Filename: message.dart
// Description: Model for a chat message with Firestore (de)serialization.

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String _id = '';
  String _chatId = '';
  String _senderId = '';
  String _type = 'text';
  String _text = '';
  String _status = 'sent';
  int _createdAt = 0; // milliseconds since epoch

  Message(
    this._id,
    this._chatId,
    this._senderId,
    this._type,
    this._text,
    this._status,
    this._createdAt,
  );

  Message.empty();

  Message.defFromJsonDbObject(
    Map<String, dynamic> jsonObject,
    String id,
    String chatId,
  ) {
    _id = id;
    _chatId = chatId;
    _senderId = jsonObject['sender_id'] ?? '';
    _type = jsonObject['type'] ?? 'text';
    _text = jsonObject['text'] ?? '';
    _status = jsonObject['status'] ?? 'sent';
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
  }

  // Getters
  String get id => _id;
  String get chatId => _chatId;
  String get senderId => _senderId;
  String get type => _type;
  String get text => _text;
  String get status => _status;
  int get createdAt => _createdAt;

  // Setters (if needed)
  set status(String value) => _status = value;

  Map<String, dynamic> toJsonForDb() {
    final json = <String, dynamic>{};
    json['sender_id'] = _senderId;
    json['type'] = _type;
    json['text'] = _text;
    json['status'] = _status;
    json['created_at'] = _createdAt; // caller can set serverTimestamp instead
    return json;
  }
}

