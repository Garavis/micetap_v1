import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:micetap_v1/models/suggestion_model.dart';

class SuggestionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _deviceId;
  String? get deviceId => _deviceId;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Cargar el ID del dispositivo desde Firestore
  Future<bool> loadDeviceId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = "Usuario no autenticado";
        return false;
      }

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (!doc.exists) {
        _errorMessage = "Documento del usuario no encontrado en Firestore";
        return false;
      }

      final fetchedDeviceId = doc.data()?['deviceId'];
      if (fetchedDeviceId == null) {
        _errorMessage = "⚠️ El campo 'deviceId' no existe en el documento de usuario.";
        return false;
      }

      _deviceId = fetchedDeviceId.toString().trim();
      _errorMessage = null;
      print("✅ deviceId cargado: $_deviceId");
      return true;
    } catch (e) {
      _errorMessage = "Error al cargar datos: $e";
      print("❌ Error en loadDeviceId: $e");
      return false;
    }
  }

  // Obtener el stream de sugerencias
  Stream<List<SuggestionModel>> getSuggestionsStream() {
    if (_deviceId == null) {
      return Stream.value([]);
    }
    
    return _firestore
      .collection('sugerencias')
      .where('deviceId', isEqualTo: _deviceId)
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
          .map((doc) => SuggestionModel.fromFirestore(doc.id, doc.data()))
          .toList();
      });
  }

  // Eliminar todas las sugerencias del dispositivo
  Future<String?> deleteAllSuggestions() async {
    if (_deviceId == null) return "No hay dispositivo seleccionado";

    try {
      final snapshot = await _firestore
          .collection('sugerencias')
          .where('deviceId', isEqualTo: _deviceId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      return null; // Éxito, sin mensaje de error
    } catch (e) {
      print("❌ Error al vaciar sugerencias: $e");
      return "Error al eliminar sugerencias: $e";
    }
  }
  
  // Método para realizar pruebas de consulta
  void testQuery() async {
    if (_deviceId == null) return;
    
    try {
      final snapshot = await _firestore
        .collection('sugerencias')
        .where('deviceId', isEqualTo: _deviceId)
        .get();
      
      print("📋 Documentos encontrados: ${snapshot.docs.length}");
      for (var doc in snapshot.docs) {
        print("📄 Documento: ${doc.data()}");
      }
    } catch (e) {
      print("❌ Error en consulta: $e");
    }
  }
}