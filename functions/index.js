const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

// Define region for functions
const region = defineString('LOCATION', { default: 'us-central1' });

// Helper function to validate and send FCM notification
async function sendNotification(token, payload, userId) {
    if (!token || typeof token !== 'string' || token.trim() === '') {
        console.error(`Invalid FCM token for user ${userId}:`, token);
        return false;
    }

    try {
        // Create message using FCM v1 API format with enhanced configuration
        const message = {
            token: token,
            notification: {
                title: payload.notification.title,
                body: payload.notification.body,
            },
            android: {
                priority: 'high',
                notification: {
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    priority: 'high',
                    channelId: 'high_importance_channel',
                    sound: 'default',
                    visibility: 'public',
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        sound: 'default',
                        priority: 10,
                    }
                }
            },
            data: {
                ...payload.data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                priority: 'high',
            },
        };

        // Send using v1 API
        const response = await admin.messaging().send(message);
        console.log('Successfully sent message:', response);
        return true;
    } catch (error) {
        console.error('Error sending notification:', error);
        
        // Handle invalid token
        if (error.code === 'messaging/invalid-registration-token' || 
            error.code === 'messaging/registration-token-not-registered') {
            try {
                await admin.firestore()
                    .collection('users')
                    .doc(userId)
                    .collection('tokens')
                    .doc('fcm')
                    .delete();
                console.log(`Removed invalid token for user ${userId}`);
            } catch (deleteError) {
                console.error('Error removing invalid token:', deleteError);
            }
        }
        return false;
    }
}

// Send notification when a new message is created
exports.onNewMessage = onDocumentCreated({
    document: 'conversations/{conversationId}/messages/{messageId}',
    region: region,
}, async (event) => {
    try {
        const message = event.data.data();
        const conversationId = event.params.conversationId;

        console.log('Processing new message:', { conversationId, messageId: event.params.messageId });

        // Get the conversation to find the recipient
        const conversationSnap = await admin.firestore()
            .collection('conversations')
            .doc(conversationId)
            .get();

        if (!conversationSnap.exists) {
            console.log('Conversation not found:', conversationId);
            return;
        }

        const conversation = conversationSnap.data();
        const recipientId = conversation.participants.find(id => id !== message.senderId);

        if (!recipientId) {
            console.error('Recipient not found in conversation participants');
            return;
        }

        // Get the recipient's FCM token
        const tokenDoc = await admin.firestore()
            .collection('users')
            .doc(recipientId)
            .collection('tokens')
            .doc('fcm')
            .get();

        if (!tokenDoc.exists) {
            console.log('FCM token not found for recipient:', recipientId);
            return;
        }

        const token = tokenDoc.data().token;
        console.log('Retrieved FCM token for recipient:', { recipientId, tokenExists: !!token });

        // Get sender's display name
        const senderDoc = await admin.firestore()
            .collection('users')
            .doc(message.senderId)
            .get();

        const senderName = senderDoc.exists ? senderDoc.data().displayName || 'Someone' : 'Someone';

        // Create the notification
        const payload = {
            notification: {
                title: `New message from ${senderName}`,
                body: message.content,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: {
                type: 'message',
                conversationId: conversationId,
                senderId: message.senderId,
            }
        };

        // Send the notification
        const success = await sendNotification(token, payload, recipientId);

        if (success) {
            // Add to notifications collection
            await admin.firestore()
                .collection('notifications')
                .add({
                    userId: recipientId,
                    title: `New message from ${senderName}`,
                    message: message.content,
                    type: 'message',
                    chatId: conversationId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
        }

    } catch (error) {
        console.error('Error in onNewMessage function:', error);
    }
});

// Send notification when a new order is created
exports.onNewOrder = onDocumentCreated({
    document: 'orders/{orderId}',
    region: region,
}, async (event) => {
    try {
        const order = event.data.data();
        const orderId = event.params.orderId;

        console.log('Processing new order:', { orderId });

        // Get seller's FCM token
        const sellerTokenDoc = await admin.firestore()
            .collection('users')
            .doc(order.sellerId)
            .collection('tokens')
            .doc('fcm')
            .get();

        if (sellerTokenDoc.exists) {
            const token = sellerTokenDoc.data().token;
            console.log('Retrieved seller FCM token:', { sellerId: order.sellerId, tokenExists: !!token });

            // Get buyer's display name
            const buyerDoc = await admin.firestore()
                .collection('users')
                .doc(order.buyerId)
                .get();

            const buyerName = buyerDoc.exists ? buyerDoc.data().displayName || 'Someone' : 'Someone';

            // Notification for seller
            const sellerPayload = {
                notification: {
                    title: 'New Order Received',
                    body: `${buyerName} placed a new order`,
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
                data: {
                    type: 'order',
                    orderId: orderId,
                    buyerId: order.buyerId,
                }
            };

            // Send notification to seller
            const sellerSuccess = await sendNotification(token, sellerPayload, order.sellerId);

            if (sellerSuccess) {
                // Add to seller's notifications
                await admin.firestore()
                    .collection('notifications')
                    .add({
                        userId: order.sellerId,
                        title: 'New Order Received',
                        message: `${buyerName} placed a new order`,
                        type: 'orderUpdate',
                        orderId: orderId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
            }
        }

        // Get buyer's FCM token
        const buyerTokenDoc = await admin.firestore()
            .collection('users')
            .doc(order.buyerId)
            .collection('tokens')
            .doc('fcm')
            .get();

        if (buyerTokenDoc.exists) {
            const token = buyerTokenDoc.data().token;
            console.log('Retrieved buyer FCM token:', { buyerId: order.buyerId, tokenExists: !!token });

            // Notification for buyer
            const buyerPayload = {
                notification: {
                    title: 'Order Placed Successfully',
                    body: `Your order #${orderId} has been placed`,
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
                data: {
                    type: 'order',
                    orderId: orderId,
                }
            };

            // Send notification to buyer
            const buyerSuccess = await sendNotification(token, buyerPayload, order.buyerId);

            if (buyerSuccess) {
                // Add to buyer's notifications
                await admin.firestore()
                    .collection('notifications')
                    .add({
                        userId: order.buyerId,
                        title: 'Order Placed Successfully',
                        message: `Your order #${orderId} has been placed`,
                        type: 'orderUpdate',
                        orderId: orderId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
            }
        }

    } catch (error) {
        console.error('Error in onNewOrder function:', error);
    }
});

// Send notification when order status changes
exports.onOrderUpdate = onDocumentUpdated({
    document: 'orders/{orderId}',
    region: region,
}, async (event) => {
    try {
        const newOrder = event.data.after.data();
        const previousOrder = event.data.before.data();
        const orderId = event.params.orderId;

        // Only send notification if status has changed
        if (newOrder.status === previousOrder.status) {
            return;
        }

        console.log('Processing order status update:', { 
            orderId, 
            oldStatus: previousOrder.status, 
            newStatus: newOrder.status 
        });

        const statusMessage = getStatusMessage(newOrder.status);

        // Get buyer's FCM token
        const buyerTokenDoc = await admin.firestore()
            .collection('users')
            .doc(newOrder.buyerId)
            .collection('tokens')
            .doc('fcm')
            .get();

        // Send notification to buyer
        if (buyerTokenDoc.exists) {
            const token = buyerTokenDoc.data().token;
            console.log('Retrieved buyer FCM token:', { buyerId: newOrder.buyerId, tokenExists: !!token });

            // Notification for buyer
            const buyerPayload = {
                notification: {
                    title: 'Order Status Updated',
                    body: `Order #${orderId} ${statusMessage}`,
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
                data: {
                    type: 'order',
                    orderId: orderId,
                }
            };

            // Send notification to buyer
            const buyerSuccess = await sendNotification(token, buyerPayload, newOrder.buyerId);

            if (buyerSuccess) {
                // Add to buyer's notifications
                await admin.firestore()
                    .collection('notifications')
                    .add({
                        userId: newOrder.buyerId,
                        title: 'Order Status Updated',
                        message: `Order #${orderId} ${statusMessage}`,
                        type: 'orderUpdate',
                        orderId: orderId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
            }
        }

        // Get seller's FCM token
        const sellerTokenDoc = await admin.firestore()
            .collection('users')
            .doc(newOrder.sellerId)
            .collection('tokens')
            .doc('fcm')
            .get();

        // Send notification to seller for important status changes
        if (sellerTokenDoc.exists && ['delivered', 'refund_requested'].includes(newOrder.status)) {
            const token = sellerTokenDoc.data().token;
            console.log('Retrieved seller FCM token:', { sellerId: newOrder.sellerId, tokenExists: !!token });

            // Get buyer's name for the notification
            const buyerDoc = await admin.firestore()
                .collection('users')
                .doc(newOrder.buyerId)
                .get();

            const buyerName = buyerDoc.exists ? buyerDoc.data().displayName || 'A customer' : 'A customer';

            // Customize message based on status
            let title = 'Order Status Updated';
            let message = '';
            
            if (newOrder.status === 'delivered') {
                title = 'Order Delivered';
                message = `${buyerName} has received order #${orderId}`;
            } else if (newOrder.status === 'refund_requested') {
                title = 'Refund Requested';
                message = `${buyerName} has requested a refund for order #${orderId}`;
            }

            // Notification for seller
            const sellerPayload = {
                notification: {
                    title: title,
                    body: message,
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                },
                data: {
                    type: 'order',
                    orderId: orderId,
                    buyerId: newOrder.buyerId,
                }
            };

            // Send notification to seller
            const sellerSuccess = await sendNotification(token, sellerPayload, newOrder.sellerId);

            if (sellerSuccess) {
                // Add to seller's notifications
                await admin.firestore()
                    .collection('notifications')
                    .add({
                        userId: newOrder.sellerId,
                        title: title,
                        message: message,
                        type: 'orderUpdate',
                        orderId: orderId,
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
            }
        }
    } catch (e) {
        console.error('Error in onOrderUpdate:', e);
    }
});

function getStatusMessage(status) {
    switch (status) {
        case 'processing':
            return 'is being processed';
        case 'shipped':
            return 'has been shipped';
        case 'delivered':
            return 'has been delivered';
        case 'cancelled':
            return 'has been cancelled';
        case 'refunded':
            return 'has been refunded';
        default:
            return 'has been updated';
    }
} 