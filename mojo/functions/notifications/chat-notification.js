const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that sends push notifications when a new message is added to a chat
 * Triggered by: Firestore document creation in 'messages' collection
 */
exports.sendChatNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const messageData = snap.data();
      const messageId = context.params.messageId;
      
      console.log(`Processing new message: ${messageId}`);
      
      // Extract message details
      const {
        communityId,
        senderId,
        senderName,
        content,
        messageType = 'text',
        timestamp
      } = messageData;
      
      if (!communityId || !senderId || !senderName) {
        console.log('Missing required message data, skipping notification');
        return null;
      }
      
      // Get community details
      const communityDoc = await db.collection('communities').doc(communityId).get();
      if (!communityDoc.exists) {
        console.log(`Community not found: ${communityId}`);
        return null;
      }
      
      const communityData = communityDoc.data();
      const communityName = communityData.name;
      const members = communityData.members || [];
      
      // Exclude sender from notification recipients
      const recipients = members.filter(memberId => memberId !== senderId);
      
      if (recipients.length === 0) {
        console.log('No recipients for notification');
        return null;
      }
      
      // Get FCM tokens for recipients
      const userDocs = await db.collection('users')
        .where(admin.firestore.FieldPath.documentId, 'in', recipients)
        .where('fcmToken', '!=', null)
        .get();
      
      const tokens = userDocs.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => token && token.length > 0);
      
      if (tokens.length === 0) {
        console.log('No FCM tokens found for recipients');
        return null;
      }
      
      // Prepare notification payload
      const notificationPayload = {
        notification: {
          title: `${senderName} in ${communityName}`,
          body: messageType === 'text' ? content : `Sent a ${messageType}`,
          sound: 'default',
        },
        data: {
          type: 'chat_message',
          communityId: communityId,
          messageId: messageId,
          senderId: senderId,
          senderName: senderName,
          messageType: messageType,
          timestamp: timestamp?.toMillis?.() || Date.now().toString(),
          navigation: `/chat/${communityId}`,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'mojo_chat',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      // Send notification to each token
      const sendPromises = tokens.map(token => {
        return messaging.send({
          token: token,
          ...notificationPayload,
        }).catch(error => {
          console.error(`Failed to send notification to token ${token.substring(0, 20)}...:`, error);
          return null;
        });
      });
      
      const results = await Promise.all(sendPromises);
      const successfulSends = results.filter(result => result !== null).length;
      
      console.log(`Notification sent to ${successfulSends}/${tokens.length} recipients for message ${messageId}`);
      
      // Update message with notification status
      await snap.ref.update({
        notificationSent: true,
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
        notificationRecipients: successfulSends,
      });
      
      return { success: true, recipients: successfulSends };
      
    } catch (error) {
      console.error('Error sending chat notification:', error);
      throw error;
    }
  });

/**
 * Cloud Function to send notification to specific users
 * Can be called from other functions or HTTP requests
 */
exports.sendNotificationToUsers = functions.https.onCall(async (data, context) => {
  try {
    // Check if user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const { userIds, title, body, data: notificationData } = data;
    
    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'userIds must be a non-empty array');
    }
    
    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'title and body are required');
    }
    
    // Get FCM tokens for users
    const userDocs = await db.collection('users')
      .where(admin.firestore.FieldPath.documentId, 'in', userIds)
      .where('fcmToken', '!=', null)
      .get();
    
    const tokens = userDocs.docs
      .map(doc => doc.data().fcmToken)
      .filter(token => token && token.length > 0);
    
    if (tokens.length === 0) {
      console.log('No FCM tokens found for users');
      return { success: false, message: 'No FCM tokens found' };
    }
    
    // Prepare notification payload
    const notificationPayload = {
      notification: {
        title: title,
        body: body,
        sound: 'default',
      },
      data: {
        ...notificationData,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        notification: {
          channelId: 'mojo_chat',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    // Send notification to each token
    const sendPromises = tokens.map(token => {
      return messaging.send({
        token: token,
        ...notificationPayload,
      }).catch(error => {
        console.error(`Failed to send notification to token ${token.substring(0, 20)}...:`, error);
        return null;
      });
    });
    
    const results = await Promise.all(sendPromises);
    const successfulSends = results.filter(result => result !== null).length;
    
    console.log(`Notification sent to ${successfulSends}/${tokens.length} users`);
    
    return { 
      success: true, 
      recipients: successfulSends,
      totalTokens: tokens.length 
    };
    
  } catch (error) {
    console.error('Error sending notification to users:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}); 