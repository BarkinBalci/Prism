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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDgD0M4FfW2S__Lxy-RY9oFmVHFaniU9aM',
    appId: '1:1090710163878:web:2aef60c2af8d27f9233f67',
    messagingSenderId: '1090710163878',
    projectId: 'prism-64b15',
    authDomain: 'prism-64b15.firebaseapp.com',
    storageBucket: 'prism-64b15.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAp3-SX9EdOO9uImyTRg_7qregdmYdGfqM',
    appId: '1:1090710163878:android:75779a2a712f23bc233f67',
    messagingSenderId: '1090710163878',
    projectId: 'prism-64b15',
    storageBucket: 'prism-64b15.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAONv_VNRcn5sZxi8lLwZ0mFnY39leSBBI',
    appId: '1:1090710163878:ios:714a58ef4aa6676b233f67',
    messagingSenderId: '1090710163878',
    projectId: 'prism-64b15',
    storageBucket: 'prism-64b15.firebasestorage.app',
    iosBundleId: 'com.barkinb.prism',
  );
}
