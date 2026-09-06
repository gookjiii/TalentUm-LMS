// Firebase Cloud Messaging Web Background Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

// Initialize Firebase App inside the background service worker
firebase.initializeApp({
  apiKey: "AIzaSyBzt1WCAzFElvDJaaBNmQ0S2GREQESWX80",
  authDomain: "school-wolrd.firebaseapp.com",
  databaseURL: "https://school-wolrd-default-rtdb.firebaseio.com",
  projectId: "school-wolrd",
  storageBucket: "school-wolrd.firebasestorage.app",
  messagingSenderId: "813433082673",
  appId: "1:813433082673:web:9709afd3339af0f58b9610"
});

const messaging = firebase.messaging();

// Handle background messaging events when the app is backgrounded or completely closed
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  // If payload already contains a 'notification' object, Firebase Messaging SDK
  // displays it automatically in the browser. Calling self.registration.showNotification
  // here causes duplicate notifications!
  if (payload && payload.notification) {
    console.log('[firebase-messaging-sw.js] Notification payload automatically handled by FCM SDK');
    return;
  }

  // Fallback for data-only messages
  const data = (payload && payload.data) ? payload.data : {};
  const notificationTitle = data.title || 'Новое сообщение / New message';
  const tag = data.messageId || data.tag || (data.roomId ? `room_${data.roomId}` : 'school_world_notification');
  const notificationOptions = {
    body: data.body || '',
    icon: data.icon || '/favicon.png',
    badge: data.badge || '/favicon.png',
    tag: tag,
    data: data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click to focus active tab or open app
self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url && client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
