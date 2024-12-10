// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8G7sv20ecIa_6JaI-kSaxYH4UJCqSK7I',
    appId: '1:262335133582:web:e42d6f7f44bd82244196df',
    messagingSenderId: '262335133582',
    projectId: 'sportmate-ed9db',
    authDomain: 'sportmate-ed9db.firebaseapp.com',
    storageBucket: 'sportmate-ed9db.firebasestorage.app',
    measurementId: 'G-43DE5XP1L3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDxmnEi_3M-jX9_ZG2iIY2FeWAxXUB26Pg',
    appId: '1:262335133582:android:70ff570ca1335c794196df',
    messagingSenderId: '262335133582',
    projectId: 'sportmate-ed9db',
    storageBucket: 'sportmate-ed9db.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjNURFsTngygPkZGSE5wDyJyug6wvEPA0',
    appId: '1:262335133582:ios:f3eb2e331ba6302a4196df',
    messagingSenderId: '262335133582',
    projectId: 'sportmate-ed9db',
    storageBucket: 'sportmate-ed9db.firebasestorage.app',
    iosBundleId: 'com.example.sportmate',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDjNURFsTngygPkZGSE5wDyJyug6wvEPA0',
    appId: '1:262335133582:ios:f3eb2e331ba6302a4196df',
    messagingSenderId: '262335133582',
    projectId: 'sportmate-ed9db',
    storageBucket: 'sportmate-ed9db.firebasestorage.app',
    iosBundleId: 'com.example.sportmate',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA8G7sv20ecIa_6JaI-kSaxYH4UJCqSK7I',
    appId: '1:262335133582:web:5b5c3c6a9958ecdb4196df',
    messagingSenderId: '262335133582',
    projectId: 'sportmate-ed9db',
    authDomain: 'sportmate-ed9db.firebaseapp.com',
    storageBucket: 'sportmate-ed9db.firebasestorage.app',
    measurementId: 'G-HC09SBSQBV',
  );
}
