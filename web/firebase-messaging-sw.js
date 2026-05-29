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

  const notificationTitle = payload.notification.title || 'Новое сообщение / New message';
  const notificationOptions = {
    body: payload.notification.body || '',
    icon: '/favicon.png',
    badge: '/favicon.png',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
