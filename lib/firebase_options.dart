
// File generated by FlutLab.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'try to add using FlutLab Firebase Configuration',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBmXabB3aiAKPnbPc-_N3Q5l6O9z6YCrBQ',
    authDomain: 'jibomonie-app.firebaseapp.com',
    projectId: 'jibomonie-app',
    storageBucket: 'jibomonie-app.firebasestorage.app',
    messagingSenderId: '1092509163883',
    appId: '1:1092509163883:web:4e61535b8cd557f065ec2e',
    measurementId: 'G-B1S7VB5DQJ'
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuz57L9cJWN_hMjpzqL3FFCO7VfZ2Tlbg',
    appId: '1:1092509163883:android:6fd90a3ca10aad3865ec2e',
    messagingSenderId: '1092509163883',
    projectId: 'jibomonie-app',
    storageBucket: 'jibomonie-app.firebasestorage.app'
  );
}
