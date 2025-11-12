// -----------------------------------------------------------------------
// Filename: db_user_profile.dart
// Original Author: Dan Grissom
// Creation Date: 5/22/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the database helper functions for user
//              profiles.

////////////////////////////////////////////////////////////////////////////////////////////
// Imports
////////////////////////////////////////////////////////////////////////////////////////////
// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter external package imports
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';

// App relative file imports
import '../providers/provider_user_profile.dart';
import '../util/logging/app_logger.dart';

import 'firestore_keys.dart';

import 'package:campusmate/providers/provider_groups.dart';
import 'package:campusmate/models/groups.dart';

////////////////////////////////////////////////////////////////////////////////////////////
// Class definition for DB Helper
////////////////////////////////////////////////////////////////////////////////////////////
class DbGroups {
  // Static variables
  static StreamSubscription? _groupsUpdateStream;

  ////////////////////////////////////////////////////////////////////////////////////////////
  // This method cancels the subscription to the DB that was initiated to update value in
  // realtime. This MUST be called before the user logs off.
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<void> cancelGroupsUpdateStream() async {
    if (_groupsUpdateStream != null) {
      await _groupsUpdateStream!.cancel();
    }
    _groupsUpdateStream = null;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  // Pulls the Firebase user's groups from Firestore and uses the passed in provider to
  // update displays throughout the app.
  //
  // Returns true if data was fetched and set in provider; false otherwise
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> fetchGroupsAndSyncProvider(
    ProviderGroups providerGroups, {
    String? uidOverride,
  }) async {
    // Initialize success variable
    bool success = false;

    // Get Firebase instance
    var db = FirebaseFirestore.instance;
    final String? uid = uidOverride ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    // Try to get the user's data from firestore and setup for future updates
    try {
      AppLogger.debug(
        "Fetching groups from collection '$FS_COL_IC_GROUPS' for uid=$uid",
      );
      // Listen for any groups where the user is a member
      _groupsUpdateStream = db
          .collection(FS_COL_IC_GROUPS)
          .where('members', arrayContains: uid)
          .snapshots()
          .listen(
            (querySnapshot) async {
              try {
                AppLogger.debug(
                  "Groups snapshot size=${querySnapshot.docs.length} for uid=$uid",
                );
                List<Groups> groups = [];
                for (var doc in querySnapshot.docs) {
                  Map<String, dynamic> data = doc.data();
                  Groups group = Groups.defFromJsonDbObject(data, doc.id);
                  groups.add(group);
                }

                // Update provider with the full list of groups
                await providerGroups.updateGroupsList(groups);
                success = true;
              } catch (e) {
                AppLogger.error("Failed to parse groups snapshot: $e");
                await providerGroups.updateGroupsList([]);
              }
            },
            onError: (e) async {
              AppLogger.error(
                "Groups stream error (permissions/network): $e",
              );
              await providerGroups.updateGroupsList([]);
            },
            cancelOnError: false,
          );
    } catch (e) {
      AppLogger.error(
        "Encountered problem loading user profile from firestore: $e",
      );
      await providerGroups.updateGroupsList([]);
    }

    // Return status
    return success;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  // Writes the user profile data to Firestore
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> writeGroup(Groups group, {merge = true}) async {
    // Initialize success variable
    bool success = false;

    // Get Firebase instance
    var db = FirebaseFirestore.instance;
    if (FirebaseAuth.instance.currentUser != null) {
      // Get the authenticated firebase user
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      // If no user logged in, return; otherwise continue
      if (user == null) {
        return false;
      }
      String uid = user.uid;

      // Try to get the user's data from firestore
      try {
        // Prepare data for write
        Map<String, dynamic> json = group.toJsonForDb();

        // normalize keys to snake_case to satisfy security rules
        if (json.containsKey('groupName')) {
          json['group_name'] = json.remove('groupName');
        }
        if (json.containsKey('groupDescription')) {
          json['group_description'] = json.remove('groupDescription');
        }
        if (json.containsKey('ownerId')) {
          json['owner_id'] = json.remove('ownerId');
        }

        // Ensure members is a list and includes the creator
        final rawMembers = json['members'];
        List<dynamic> members =
            rawMembers is List ? List<dynamic>.from(rawMembers) : <dynamic>[];
        if (!members.contains(uid)) {
          members.add(uid);
        }
        json['members'] = members;

        if (group.groupId.isEmpty) {
          // Create new group: set owner_id and server timestamp for created_at
          json['owner_id'] = uid;
          json['created_at'] = FieldValue.serverTimestamp();
          await db.collection(FS_COL_IC_GROUPS).add(json);
        } else {
          // Update existing group document
          await db
              .collection(FS_COL_IC_GROUPS)
              .doc(group.groupId)
              .set(json, SetOptions(merge: merge));
        }
        success = true;
      } catch (e) {
        AppLogger.error(
          "Encountered problem writing user profile to firestore.$e",
        );

        success = false;
      }
    }

    // Return status
    return success;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  // Deletes a group document. Firestore security rules ensure only the owner can delete.
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> deleteGroup(String groupId) async {
    bool success = false;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      final db = FirebaseFirestore.instance;
      await db.collection(FS_COL_IC_GROUPS).doc(groupId).delete();
      success = true;
    } catch (e) {
      AppLogger.error("Encountered problem deleting group: $e");
      success = false;
    }

    return success;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  // Pulls the Firebase user's profile image from Cloud Storage and uses the passed in provider to
  // update displays throughout the app.
  //
  // Returns true if image data was fetched and set in provider; false otherwise
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> fetchUserProfileImageAndSyncProvider(
    ProviderUserProfile providerUserProfile,
  ) async {
    // Initialize success variable
    bool success = false;

    // Get a Google Storage reference to the profile picture
    final ref = FirebaseStorage.instance.ref().child(
      'users/${providerUserProfile.uid}/profile_picture/userProfilePicture.jpg',
    );

    // Try to download the image
    try {
      Uint8List? imageData = await ref.getData();
      if (imageData == null) {
        providerUserProfile.userImage = null;
      } else {
        providerUserProfile.userImage = MemoryImage(imageData);
      }
      //var url = await ref.getDownloadURL();
      //userProfileProvider.userImage = NetworkImage(url);
      success = true;
    } catch (e) {
      // If ref is bad/incomplete, set to local image
      providerUserProfile.userImage = null;
    }

    // Return status
    return success;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  // Attempts to pull a profile picture from Cloud Storage using a UID that is passed in. Only
  // attempts fetch if the attemptFetch parameter is true; otherwise, returns default icon.
  //
  // Returns an image (MIC logo if no image retreived)
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<ImageProvider?> fetchUserProfileImageFromUid(
    String uid,
    bool attemptFetch,
  ) async {
    if (attemptFetch) {
      // Get a Google Storage reference to the profile picture
      final ref = FirebaseStorage.instance.ref().child(
        'users/$uid/profile_picture/userProfilePicture.jpg',
      );

      // Try to download the image
      try {
        Uint8List? imageData = await ref.getData();
        if (imageData != null) {
          return MemoryImage(imageData);
        }
      } catch (e) {
        AppLogger.error("Failed to fetch user profile image from uid: $e");
      }
    }

    // If image fetch failed, return null
    return null;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  // Uplads the user profile image to Google Cloud Storage
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> uploadNewUserProfileImage(
    File imageFile,
    ProviderUserProfile providerUserProfile,
  ) async {
    // Initialize success variable
    bool success = false;

    try {
      // Get a reference to the logged-in user's profile pic and upload the new picture
      final gcsPath =
          'users/${providerUserProfile.uid}/profile_picture/userProfilePicture.jpg';
      final ref = FirebaseStorage.instance.ref().child(gcsPath);

      // Get existing metadata, upload the file, and then re-upload the metadata
      try {
        final existingMetadata = await ref.getMetadata();
        await ref.putFile(
          imageFile,
          SettableMetadata(
            customMetadata:
                existingMetadata.customMetadata ?? <String, String>{},
          ),
        );
      } catch (e) {
        Map<String, String> customMetadata = {};
        ref.putFile(
          imageFile,
          SettableMetadata(customMetadata: customMetadata),
        );
      }
      success = true;
    } catch (e) {
      AppLogger.error("Failed To Upload: $e");

      success = false;
    }

    return success;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////
  // Deletes the user profile image from Google Cloud Storage
  ////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> deleteUserProfileImage(
    ProviderUserProfile providerUserProfile,
  ) async {
    // Initialize success variable
    bool success = false;

    try {
      // Get a reference to the logged-in user's profile pic and upload the new picture
      final gcsPath =
          'users/${providerUserProfile.uid}/profile_picture/userProfilePicture.jpg';
      final ref = FirebaseStorage.instance.ref().child(gcsPath);
      await ref.delete();
      success = true;
    } catch (e) {
      success = false;
    }

    return success;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // Deletes the account data associated with the current user.
  //
  // Returns: A Future that completes when the account data is successfully deleted.
  ////////////////////////////////////////////////////////////////////////////////
  static Future<void> deleteAccountData() async {
    try {
      User? currentUser = FirebaseAuth
          .instance
          .currentUser; // Retrieve the currently authenticated user
      if (currentUser == null) {
        return; // Exit the method if the user is null
      }
      String userID = currentUser.uid; // User ID
      await FirebaseFirestore.instance
          .collection(FS_COL_IC_USER_PROFILES)
          .doc(userID)
          .delete(); // Delete the document associated with the user ID from the "FS_COL_MIC_USER_PROFILES" collection

      AppLogger.print('Document deleted successfully!');
    } catch (e) {
      AppLogger.error('Error deleting document: $e');
    }
  }
}
