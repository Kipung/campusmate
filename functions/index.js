const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onUnfriend = functions.firestore
  .document('user_profiles/{userId}/friends/{friendId}')
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    const friendId = context.params.friendId;

    const db = admin.firestore();

    // 1. Delete the matching friend request(s)
    const requests = await db
      .collection('friend_requests')
      .where('from', 'in', [userId, friendId])
      .get();

    const batch = db.batch();

    requests.forEach(doc => {
      const data = doc.data();
      if (
        (data.from === userId && data.to === friendId) ||
        (data.from === friendId && data.to === userId)
      ) {
        batch.delete(doc.ref);
      }
    });

    // 2. Delete the OTHER user's friend entry
    const otherFriendRef = db
      .collection('user_profiles')
      .doc(friendId)
      .collection('friends')
      .doc(userId);

    batch.delete(otherFriendRef);

    await batch.commit();
  });