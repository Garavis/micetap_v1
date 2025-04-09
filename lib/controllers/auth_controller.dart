import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro con guardado en Firestore
  Future<bool> register(String email, String password, String name, String deviceId) async {
  try {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Guardar el usuario con su deviceId
    await _firestore.collection('usuarios').doc(cred.user!.uid).set({
      'email': email,
      'nombre': name,
      'deviceId': deviceId,
    });

    // Crear el dispositivo en Firestore si no existe
    final deviceDoc = _firestore.collection('dispositivos').doc(deviceId);
    final exists = await deviceDoc.get();

    if (!exists.exists) {
      await deviceDoc.set({
        'consumo': 0.0,
        'nombre': name,
      });
    }

    return true;
  } catch (e) {
    print('Error al registrar: $e');
    return false;
  }
}

  // Login
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      const SnackBar(content: Text('Credenciales incorrectas'));
      return false;
    }
  }

  // Obtener el deviceId del usuario actual
  Future<String?> getDeviceId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    return doc.data()?['deviceId'];
  }

  Future<void> logout() async => _auth.signOut();
}
