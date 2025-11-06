import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyCEEqeKASx5URajnK-Z6dgeD4l8CtLcIFc",
  authDomain: "test1-ffa7d.firebaseapp.com",
  projectId: "test1-ffa7d",
  storageBucket: "test1-ffa7d.firebasestorage.app",
  messagingSenderId: "753827092251",
  appId: "1:753827092251:web:e8b4bdcd80b6881d81e5be",
  measurementId: "G-01YG56NN4Y"

      );
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for this platform.',
    );
  }
}
