importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBlsNLevb2Cw2ijIP-za6DcxxCzSaUXiuo",
  authDomain: "music-system-421ee.firebaseapp.com",
  projectId: "music-system-421ee",
  storageBucket: "music-system-421ee.firebasestorage.app",
  messagingSenderId: "108435262492",
  appId: "1:108435262492:web:fbf5d95559eb76267923d9",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
