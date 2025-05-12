import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Ya no actualizamos el lastLogin aquí, solo leemos la información
    return _firestore.collection('usuarios').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return UserConfigModel.empty();
      }
      return UserConfigModel.fromFirestore(user.uid, snapshot.data()!);
    });
  }

  // Actualizar información de perfil
  Future<bool> updateProfileInfo(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('usuarios').doc(user.uid).update(data);
      return true;
    } catch (e) {
      print('Error al actualizar perfil: $e');
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    // Antes de cerrar sesión, actualizamos la fecha de último acceso
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('usuarios').doc(user.uid).update({
          'lastLogin': DateTime.now().toString(),
        });
      } catch (e) {
        print('Error al actualizar lastLogin: $e');
      }
    }

    await _auth.signOut();
  }
}
