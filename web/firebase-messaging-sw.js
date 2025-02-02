importScripts("https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.x.x/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDPxnrmBdz3z9QsiNEhbQ1zitXVBVLApYQ",
  authDomain: "androind-merch.firebaseapp.com",
  projectId: "androind-merch",
  storageBucket: "androind-merch.firebasestorage.app",
  messagingSenderId: "984904295859",
  appId: "1:984904295859:web:dc1736ac3a7b520ed157c6",
  measurementId: "G-F6M0GV6HQL"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message:', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: 'notification-1'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
}); 