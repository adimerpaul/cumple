// GENERADO POR: flutterfire configure
// Ejecuta ese comando en la carpeta app/ para reemplazar este archivo
// con los valores reales de tu proyecto Firebase.
//
// Pasos:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure
//   3. Selecciona tu proyecto Firebase

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma. '
          'Ejecuta: flutterfire configure',
        );
    }
  }

  // ⚠️  Reemplaza estos valores ejecutando: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU-API-KEY-ANDROID',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'tu-proyecto-firebase',
    storageBucket: 'tu-proyecto-firebase.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU-API-KEY-IOS',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'tu-proyecto-firebase',
    storageBucket: 'tu-proyecto-firebase.appspot.com',
    iosBundleId: 'com.example.cumple',
  );
}
