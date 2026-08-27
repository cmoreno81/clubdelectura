// Generado manualmente a partir de google-services.json y GoogleService-Info.plist
// Proyecto: clublectura-466c6
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web no está configurado.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Plataforma ${defaultTargetPlatform.name} no está configurada.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhqZW0q2GtN1RKysMyQ67OpXPA7Q_5aXg',
    appId: '1:13987033922:android:9085323ebb407ac4fbcedb',
    messagingSenderId: '13987033922',
    projectId: 'clublectura-466c6',
    storageBucket: 'clublectura-466c6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBopM5FyKlI2-wfRlGI1ZZoh8IQhk3I7hE',
    appId: '1:13987033922:ios:1dd530522af7fdbdfbcedb',
    messagingSenderId: '13987033922',
    projectId: 'clublectura-466c6',
    storageBucket: 'clublectura-466c6.firebasestorage.app',
    iosBundleId: 'com.cristinamoreno.clubreads',
  );
}
