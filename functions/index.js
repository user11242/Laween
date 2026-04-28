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
    
    // We send to the topic: group_{groupId}
    const topic = `group_${groupId}`;

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
      topic: topic,
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages',
          sound: 'default'
        }
      },
      apns: {
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

    const response = await admin.messaging().send(message);
    console.log(`Successfully sent topic message to ${topic}:`, response);
  } catch (error) {
    console.error(`Error in sendGroupNotification (Topic):`, error);
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
