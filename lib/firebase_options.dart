
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


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
    apiKey: 'AIzaSyBcLPYSUAKWSKWILN1LNEEcw_SovdqROz4',
    appId: '1:878248142446:web:2b9712f1db96836cca287f',
    messagingSenderId: '878248142446',
    projectId: 'muuguzi-2',
    authDomain: 'muuguzi-2.firebaseapp.com',
    storageBucket: 'muuguzi-2.firebasestorage.app',
    measurementId: 'G-K8E9EC09J7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFMgTrogABz9mbGMRjBGAI_X1W-vzL0ME',
    appId: '1:878248142446:android:ca5dd5f91e253dadca287f',
    messagingSenderId: '878248142446',
    projectId: 'muuguzi-2',
    storageBucket: 'muuguzi-2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDHYudeqeznXm26Fwrha-6XxZ78BMgIqlQ',
    appId: '1:878248142446:ios:78d3cc68d37f3d1dca287f',
    messagingSenderId: '878248142446',
    projectId: 'muuguzi-2',
    storageBucket: 'muuguzi-2.firebasestorage.app',
    iosBundleId: 'com.example.muuguziApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDHYudeqeznXm26Fwrha-6XxZ78BMgIqlQ',
    appId: '1:878248142446:ios:78d3cc68d37f3d1dca287f',
    messagingSenderId: '878248142446',
    projectId: 'muuguzi-2',
    storageBucket: 'muuguzi-2.firebasestorage.app',
    iosBundleId: 'com.example.muuguziApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBcLPYSUAKWSKWILN1LNEEcw_SovdqROz4',
    appId: '1:878248142446:web:1de9dbb929ebf03bca287f',
    messagingSenderId: '878248142446',
    projectId: 'muuguzi-2',
    authDomain: 'muuguzi-2.firebaseapp.com',
    storageBucket: 'muuguzi-2.firebasestorage.app',
    measurementId: 'G-BVG50W7VG6',
  );
}
