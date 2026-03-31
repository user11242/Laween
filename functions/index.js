const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * 1. WhatsApp-Style Chat Notifications
 * Triggered when a new document is created in groups/{groupId}/messages/{messageId}
 */
exports.onMessageSent = functions.firestore
  .document("groups/{groupId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const groupId = context.params.groupId;

    const senderId = messageData.senderId;
    const senderName = messageData.senderName || "Someone";
    const text = messageData.text;

    // 1. Get the group document to find all participants
    const groupRef = admin.firestore().collection("groups").doc(groupId);
    const groupDoc = await groupRef.get();

    if (!groupDoc.exists) return null;

    const groupData = groupDoc.data();
    const groupName = groupData.name || "A Group";
    const members = groupData.members || [];

    // 2. Filter out the sender so they don't get their own notification
    const receiverIds = members.filter((uid) => uid !== senderId);
    if (receiverIds.length === 0) return null;

    // 3. Fetch fcmTokens for all receivers
    const tokens = [];
    for (const uid of receiverIds) {
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      if (userDoc.exists) {
        const token = userDoc.data().fcmToken;
        if (token) tokens.push(token);
      }
    }

    if (tokens.length === 0) {
      console.log("No valid FCM tokens found for receivers.");
      return null;
    }

    // 4. Build the Push Notification Payload
    const payload = {
      notification: {
        title: `${senderName} (${groupName})`,
        body: text,
      },
      data: {
        type: "chat_message",
        groupId: groupId,
      },
      tokens: tokens,
    };

    // 5. Blast to all tokens
    try {
      const response = await admin.messaging().sendMulticast(payload);
      console.log(`Successfully sent ${response.successCount} chat messages.`);
    } catch (error) {
      console.error("Error sending chat notification:", error);
    }
    return null;
  });

/**
 * 2. Careem-Style Outing Notifications
 * Triggered when groups/{groupId}/outings/{outingId} changes status to 'completed'
 */
exports.onOutingStatusChanged = functions.firestore
  .document("groups/{groupId}/outings/{outingId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if status changed TO 'completed' (Meaning Winner was decided)
    if (beforeData.status !== "completed" && afterData.status === "completed") {
      const groupId = context.params.groupId;
      const winner = afterData.winner?.name || "The Destination";
      const participants = afterData.participants || [];

      // Extract all UIDs of people who joined the outing
      const uids = participants.map(p => p.uid);
      if (uids.length === 0) return null;

      // Fetch tokens
      const tokens = [];
      for (const uid of uids) {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        if (userDoc.exists) {
          const token = userDoc.data().fcmToken;
          if (token) tokens.push(token);
        }
      }

      if (tokens.length === 0) return null;

      const payload = {
        notification: {
          title: "🚀 Let's Go!",
          body: `We have a winner: ${winner}. Everyone is on the map. Start driving!`,
        },
        data: {
          type: "outing_started",
          groupId: groupId,
          outingId: context.params.outingId,
        },
        tokens: tokens,
      };

      try {
        const response = await admin.messaging().sendMulticast(payload);
        console.log(`Successfully sent ${response.successCount} tracking alerts.`);
      } catch (error) {
        console.error("Error sending outing alert:", error);
      }
    }
    return null;
  });

/**
 * 3. Pre-existing helper function: getUserProviders
 */
exports.getUserProviders = functions.https.onCall(async (data, context) => {
  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "The function must be called with an 'email' argument.");
  }
  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    const providers = userRecord.providerData.map(userInfo => userInfo.providerId);
    return { providers: providers };
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      return { providers: [] };
    }
    throw new functions.https.HttpsError("internal", "Error fetching user providers.");
  }
});
