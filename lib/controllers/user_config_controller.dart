// lib/controllers/config_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:micetap_v1/models/user_config_model.dart';

class ConfigController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  
  // Obtener el stream de datos del usuario
  Stream<UserConfigModel> getUserConfigStream() {
    final user = _auth.currentUser;
    
    if (user == null) {
      // Si no hay usuario autenticado, devolver un modelo vacío
      return Stream.value(UserConfigModel.empty());
    }
    
    return _firestore
        .collection('usuarios')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return UserConfigModel.empty();
          }
          return UserConfigModel.fromFirestore(user.uid, snapshot.data()!);
        });
  }
  
  // Método para cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}