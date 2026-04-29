const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Helper to send a high-priority notification to a group topic
 * This is the "ROOT FIX" for TestFlight reliability as it bypasses manual token management
 * and handles Sandbox/Production routing automatically via the topic subscription.
 */
async function sendGroupNotification(groupId, senderId, titlePrefix, body, data = {}) {
  try {
    const groupDoc = await admin.firestore().collection("groups").doc(groupId).get();
    if (!groupDoc.exists) return;
    
    const groupData = groupDoc.data();
    const groupName = groupData.name || "Group";
    const memberIds = groupData.memberIds || [];

    // Filter out the sender
    const recipientIds = memberIds.filter(id => id !== senderId);
    if (recipientIds.length === 0) {
      console.log("No recipients to notify (sender is only member or no members).");
      return;
    }

    // Fetch tokens for recipients
    const tokens = [];
    const userDocs = await Promise.all(
      recipientIds.map(id => admin.firestore().collection("users").doc(id).get())
    );

    userDocs.forEach(doc => {
      if (doc.exists && doc.data().fcmToken) {
        tokens.push(doc.data().fcmToken);
      }
    });

    if (tokens.length === 0) {
      console.log("No valid FCM tokens found for recipients.");
      return;
    }

    const message = {
      notification: { 
        title: `${groupName}: ${titlePrefix}`, 
        body: body 
      },
      data: {
        ...data,
        groupId: groupId,
        senderId: senderId || "",
      },
      tokens: tokens, // Multicast
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages',
          sound: 'default'
        }
      },
      apns: {
        headers: {
          'apns-topic': 'com.company.laween',
          'apns-push-type': 'alert',
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            alert: {
                title: `${groupName}: ${titlePrefix}`,
                body: body
            }
          }
        }
      }
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`Successfully sent multicast message to ${response.successCount} devices.`);
  } catch (error) {
    console.error(`Error in sendGroupNotification:`, error);
  }
}

/**
 * 1. Chat Notifications (Handles Chat, Outing Starts, etc.)
 */
exports.onMessageSent = functions.firestore
  .document("groups/{groupId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const groupId = context.params.groupId;
    const senderName = messageData.senderName || "Someone";
    const senderId = messageData.senderId;
    
    let body = messageData.text;
    if (messageData.type === 'image') body = "📷 Photo";
    if (messageData.type === 'location') body = "📍 Shared a location";
    if (messageData.type === 'outing') body = "🚀 New Outing Started! Join the journey.";

    return sendGroupNotification(
      groupId, 
      senderId, 
      senderName, 
      body, 
      { type: "chat_message", groupId: groupId }
    );
  });

/**
 * 2. New Member Joins
 */
exports.onMemberJoined = functions.firestore
  .document("groups/{groupId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data().memberIds || [];
    const after = change.after.data().memberIds || [];
    const groupId = context.params.groupId;

    if (after.length > before.length) {
      const newMemberId = after.find(id => !before.includes(id));
      if (!newMemberId) return null;

      const userDoc = await admin.firestore().collection("users").doc(newMemberId).get();
      const userName = userDoc.exists ? (userDoc.data().name || "A new member") : "A new member";

      return sendGroupNotification(
        groupId,
        null, // No single "sender" to exclude, everyone should see it
        "New Member! 🙌",
        `${userName} just joined the group.`
      );
    }
    return null;
  });

/**
 * 3. Outing Milestone: First Arrival
 */
exports.onFirstArrival = functions.firestore
  .document("groups/{groupId}/outings/{outingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const groupId = context.params.groupId;

    if (!before.firstArrivedUid && after.firstArrivedUid) {
      const userDoc = await admin.firestore().collection("users").doc(after.firstArrivedUid).get();
      const userName = userDoc.exists ? userDoc.data().name : "A friend";

      return sendGroupNotification(
        groupId,
        null, // Everyone gets congratulated
        "🎉 First Arrival!",
        `${userName} has reached the destination!`
      );
    }
    return null;
  });

// NOTE: onOutingCreated is removed to avoid duplicates, 
// as onMessageSent already notifies about the outing message.
