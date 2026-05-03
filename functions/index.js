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
      // We don't return yet, we might have VoIP tokens!
    }

    const isSos = data.type === 'sos';

    // ========================================================================
    // 🔥 iOS CALLKIT VOIP PUSH (Critical for SOS)
    // ========================================================================
    if (isSos) {
      try {
        const apn = require('apn');
        
        // Initialize APN Provider with the user's certificates
        const options = {
          token: {
            key: __dirname + "/AuthKey_6LXRP4GFM7.p8",
            keyId: "6LXRP4GFM7",
            teamId: "34G33F4QZ5"
          },
          production: false // Sandbox for now, change to true for TestFlight/App Store
        };
        
        const apnProvider = new apn.Provider(options);

        // Fetch VoIP tokens from users
        const voipTokens = [];
        userDocs.forEach(doc => {
          if (doc.exists && doc.data().voipToken) {
            voipTokens.push(doc.data().voipToken);
          }
        });

        if (voipTokens.length > 0) {
          const callUuid = `sos-${Date.now()}`;
          const note = new apn.Notification();
          note.topic = "com.company.laween.voip"; // MUST append .voip for PushKit
          note.expiry = Math.floor(Date.now() / 1000) + 60; // Expires in 60s
          note.priority = 10; // Immediate delivery
          // 🔥 flutter_callkit_incoming expects these EXACT field names
          note.payload = {
            "id": callUuid,
            "uuid": callUuid,
            "nameCaller": `🚨 SOS: ${titlePrefix}`,
            "handle": "Emergency Alert",
            "type": 0,
            "duration": 45000,
            "textAccept": "SEE MAP",
            "textDecline": "DISMISS",
            "extra": {
              "groupId": groupId,
              "sessionId": data.sessionId || ""
            }
          };

          const result = await apnProvider.send(note, voipTokens);
          console.log("📱 VoIP Push Result:", JSON.stringify(result));
          
          if (result.failed && result.failed.length > 0) {
            console.error("❌ VoIP Push Failures:", JSON.stringify(result.failed));
          }
        } else {
          console.log("⚠️ No VoIP tokens found for iOS CallKit.");
        }
        
        apnProvider.shutdown();
      } catch (voipError) {
        console.error("❌ Failed to send VoIP push:", voipError);
      }
    }
    // ========================================================================

    if (tokens.length === 0) return; // If no standard FCM tokens, we can stop here.

    const message = {
      data: {
        ...data,
        groupId: groupId,
        senderId: senderId || "",
        // Pass title and body in data so the Flutter background handler can read them
        title: `${groupName}: ${titlePrefix}`,
        body: body
      },
      tokens: tokens, // Multicast
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-topic': 'com.company.laween',
          'apns-push-type': isSos ? 'background' : 'alert',
          'apns-priority': '10',
        },
        payload: {
          aps: isSos
            ? {
                // SOS: Data-only message to wake background handler reliably
                'content-available': 1,
                sound: { critical: 1, name: "default", volume: 1.0 },
                badge: 1
              }
            : {
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

    // Only add root notification and android channel config if it's NOT an SOS.
    // For SOS, Android gets a DATA-ONLY message so it wakes the background isolate.
    if (!isSos) {
      message.notification = { 
        title: `${groupName}: ${titlePrefix}`, 
        body: body 
      };
      message.android.notification = {
        channelId: 'chat_messages',
        sound: 'default'
      };
    }

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
    const isSos = messageData.isSos === true;
    const sessionId = messageData.sessionId || "";
    
    let body = messageData.text;
    if (messageData.type === 'image') body = "📷 Photo";
    if (messageData.type === 'location') body = "📍 Shared a location";
    if (messageData.type === 'outing') body = "🚀 New Outing Started! Join the journey.";

    return sendGroupNotification(
      groupId, 
      senderId, 
      senderName, 
      body, 
      { 
        type: isSos ? "sos" : "chat_message", 
        groupId: groupId, 
        sessionId: sessionId 
      }
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
