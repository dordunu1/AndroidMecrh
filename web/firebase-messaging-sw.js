importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

// Add error handling for script loading
self.addEventListener('error', function(e) {
  console.error('Service Worker error:', e);
  // Attempt recovery by clearing caches
  caches.keys().then(function(cacheNames) {
    return Promise.all(
      cacheNames.map(function(cacheName) {
        return caches.delete(cacheName);
      })
    );
  });
});

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

// Background message handler with error handling
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);
  
  try {
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
      body: payload.notification.body,
      icon: '/assets/images/app_icon.png',
      badge: '/assets/images/app_icon.png',
      tag: payload.data?.tag || 'default',
      data: payload.data,
      image: payload.notification.image,
      vibrate: [200, 100, 200]
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
  } catch (error) {
    console.error('Error showing notification:', error);
    // Attempt to show a simpler notification if the original fails
    return self.registration.showNotification('New Message', {
      body: 'You have a new message',
      icon: '/assets/images/app_icon.png'
    });
  }
});

// Add periodic cache cleanup
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'cleanup-caches') {
    event.waitUntil(
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            // Delete caches older than 7 days
            return caches.open(cacheName).then((cache) => {
              return cache.keys().then((requests) => {
                return Promise.all(
                  requests.map((request) => {
                    return cache.delete(request);
                  })
                );
              });
            });
          })
        );
      })
    );
  }
}); 