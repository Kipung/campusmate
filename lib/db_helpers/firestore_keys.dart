// -----------------------------------------------------------------------
// Filename: firestore_keys.dart
// Original Author: Dan Grissom
// Creation Date: 5/22/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the Firestore keys used throughout the
//              app for consistency and ease of maintenance.

///////////////////////////////////////////////////////////////////////////
// FIRESTORE TOP-LEVEL COLLECTION NAMES
///////////////////////////////////////////////////////////////////////////
const String FS_COL_IC_USER_PROFILES = 'user_profiles';
// Top-level collection for study/groups
const String FS_COL_IC_GROUPS = 'groups';
// Top-level collection for one-on-one chats
const String FS_COL_CHATS = 'chats';
// Sub-collection for chat messages within each chat document
const String FS_COL_CHAT_MESSAGES = 'messages';

///////////////////////////////////////////////////////////////////////////
// FIRESTORE MID-LEVEL COLLECTION/DOCUMENT NAMES/KEYS
///////////////////////////////////////////////////////////////////////////
