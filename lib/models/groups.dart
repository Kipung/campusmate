// -----------------------------------------------------------------------
// Filename: user_profile.dart
// Original Author: Dan Grissom
// Creation Date: 5/22/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the model for the user profile

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////
// Flutter external package imports
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum definition for account creation status
enum AccountCreationStep {
  ACC_STEP_ONBOARDING_PROFILE_CONTACT_INFO,
  ACC_STEP_ONBOARDING_COMPLETE,
}

// Enum definition for permission level
// NOTE: Do NOT change the order of these enums. They are used for permissions
// checking (e.g., Developer has access to Beta and Production, but not vice versa by
// the fact that Developer is the highest enum value)
enum PermissionLevel { PRODUCTION, BETA, DEVELOPER }

//////////////////////////////////////////////////////////////////////////
// Model class definitition
//////////////////////////////////////////////////////////////////////////
class Groups {
  ////////////////////////////////////////////////////////////////////////
  // Instance variables
  ////////////////////////////////////////////////////////////////////////
  String _groupId = "";
  String _ownerId = "";
  String _groupName = "";
  String _groupDescription = "";
  List<String> _members = [];
  List<String> _personalityTraits = [];
  List<String> _majors = [];
  PermissionLevel _permissionLevel = PermissionLevel.PRODUCTION;
  int _createdAt = 0; // milliseconds since epoch

  ////////////////////////////////////////////////////////////////////////
  // CONSTRUCTORS
  ////////////////////////////////////////////////////////////////////////
  // Positional Constructor
  Groups(
    this._groupId,
    this._ownerId,
    this._groupName,
    this._groupDescription,
    this._members,
    this._personalityTraits,
    this._majors,
    this._permissionLevel,
    this._createdAt,
  );

  // Named Constructor
  Groups.empty() {
    _groupId = "";
    _ownerId = "";
    _groupName = "";
    _groupDescription = "";
    _members = [];
    _personalityTraits = [];
    _majors = [];
    _permissionLevel = PermissionLevel.PRODUCTION;
    _createdAt = 0;
  }

  ////////////////////////////////////////////////////////////////////////
  // Creates a new User profile and populates using the JSON object passed
  // in as parameter
  ////////////////////////////////////////////////////////////////////////
  Groups.defFromJsonDbObject(Map<String, dynamic> jsonObject, String groupId) {
    _groupId = groupId;
    _groupName = jsonObject["group_name"] ?? "";
    _groupDescription = jsonObject["group_description"] ?? "";
    _members = List<String>.from(jsonObject["members"] ?? []);
    _personalityTraits = List<String>.from(
      jsonObject["personality_traits"] ?? [],
    );
    _majors = List<String>.from(jsonObject["majors"] ?? []);
    _ownerId = jsonObject["owner_id"] ?? "";
    // created_at may be stored as Timestamp or int millis
    var ca = jsonObject["created_at"];
    if (ca is int) {
      _createdAt = ca;
    } else if (ca is DateTime) {
      _createdAt = ca.millisecondsSinceEpoch;
    } else if (ca is Timestamp) {
      _createdAt = ca.millisecondsSinceEpoch;
    } else {
      _createdAt = 0;
    }
    _permissionLevel = _getPermissionLevelFromString(
      jsonObject["permission_level"] ??
          _getStringFromPermissionLevel(PermissionLevel.PRODUCTION),
    );
  }

  ////////////////////////////////////////////////////////////////////////
  // SETTERS
  ////////////////////////////////////////////////////////////////////////
  set groupId(String value) => _groupId = value;
  set ownerId(String value) => _ownerId = value;
  set groupName(String value) => _groupName = value;
  set groupDescription(String value) => _groupDescription = value;
  set members(List<String> value) => _members = value;
  set personalityTraits(List<String> value) => _personalityTraits = value;
  set majors(List<String> value) => _majors = value;

  set createdAt(int value) => _createdAt = value;

  set permissionLevel(PermissionLevel value) => _permissionLevel = value;

  ////////////////////////////////////////////////////////////////////////
  // GETTERS
  ////////////////////////////////////////////////////////////////////////
  String get groupId => _groupId;
  String get ownerId => _ownerId;
  String get groupName => _groupName;
  String get groupDescription => _groupDescription;
  List<String> get members => _members;
  List<String> get personalityTraits => _personalityTraits;
  List<String> get majors => _majors;
  int get createdAt => _createdAt;
  PermissionLevel get permissionLevel => _permissionLevel;

  ////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////
  /// UTILITY METHODS
  ////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////
  // Method checks to see if the user profile has been initialized
  // by checking if key data items exist
  ////////////////////////////////////////////////////////////////////////
  bool isMissingKeyData() {
    return (ownerId.isEmpty ||
        groupName.isEmpty ||
        groupDescription.isEmpty ||
        members.isEmpty ||
        personalityTraits.isEmpty ||
        majors.isEmpty);
  }

  ////////////////////////////////////////////////////////////////
  // Converts from enum status to string (for DB usage)
  ////////////////////////////////////////////////////////////////
  String getStringFromStep(AccountCreationStep step) {
    if (step == AccountCreationStep.ACC_STEP_ONBOARDING_PROFILE_CONTACT_INFO)
      return "Contact";
    if (step == AccountCreationStep.ACC_STEP_ONBOARDING_COMPLETE)
      return "Complete";
    return "Contact";
  }

  ////////////////////////////////////////////////////////////////
  // Converts from String to enum status (for DB usage)
  ////////////////////////////////////////////////////////////////
  AccountCreationStep getStepFromString(String stepStr) {
    if (stepStr == "Contact")
      return AccountCreationStep.ACC_STEP_ONBOARDING_PROFILE_CONTACT_INFO;
    if (stepStr == "Complete")
      return AccountCreationStep.ACC_STEP_ONBOARDING_COMPLETE;
    return AccountCreationStep.ACC_STEP_ONBOARDING_COMPLETE;
  }

  ////////////////////////////////////////////////////////////////////////
  // Converts from enum status to string (for DB usage) for
  // permission level
  ////////////////////////////////////////////////////////////////////////
  String _getStringFromPermissionLevel(PermissionLevel permissionLevel) {
    if (permissionLevel == PermissionLevel.PRODUCTION) return "Production";
    if (permissionLevel == PermissionLevel.BETA) return "Beta";
    if (permissionLevel == PermissionLevel.DEVELOPER) return "Developer";
    return "Production";
  }

  ////////////////////////////////////////////////////////////////////////
  // Converts from String to enum status for permission level
  ////////////////////////////////////////////////////////////////////////
  PermissionLevel _getPermissionLevelFromString(String permissionLevelStr) {
    if (permissionLevelStr == "Production") return PermissionLevel.PRODUCTION;
    if (permissionLevelStr == "Beta") return PermissionLevel.BETA;
    if (permissionLevelStr == "Developer") return PermissionLevel.DEVELOPER;
    return PermissionLevel.PRODUCTION;
  }

  ////////////////////////////////////////////////////////////////////////
  // Converts to JSON for saving to noSQL database
  ////////////////////////////////////////////////////////////////////////
  Map<String, dynamic> toJsonForDb() {
    // Create empty map
    Map<String, dynamic> jsonObject = {};

    // Add all fields to the json map
    //dbObject[""] = uid; // FYI: Not currently stored in DB
    jsonObject["group_name"] = groupName;
    jsonObject["group_description"] = groupDescription;
    jsonObject["members"] = members;
    jsonObject["personality_traits"] = personalityTraits;
    jsonObject["majors"] = majors;
    jsonObject["permission_level"] = _getStringFromPermissionLevel(
      permissionLevel,
    );

    // Return the JSON object
    return jsonObject;
  }
}
