import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro con guardado en Firestore
  Future<bool> register(
    String email,
    String password,
    String name,
    String deviceId,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final now = DateTime.now().toString();

      // Guardar el usuario con su deviceId y datos adicionales
      await _firestore.collection('usuarios').doc(cred.user!.uid).set({
        'email': email,
        'nombre': name,
        'deviceId': deviceId,
        'createdAt': now,
        'lastLogin': now,
        'additionalInfo': {
          'appVersion': '1.0.0',
          'registrationCompleted': true,
        },
      });

      // Crear el dispositivo en Firestore si no existe
      final deviceDoc = _firestore.collection('dispositivos').doc(deviceId);
      final exists = await deviceDoc.get();

      if (!exists.exists) {
        await deviceDoc.set({
          'consumo': 0.0,
          'nombre': name,
          'activationDate': now,
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Login con actualización de lastLogin
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar fecha de último inicio de sesión
      if (userCredential.user != null) {
        await _firestore
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .update({'lastLogin': DateTime.now().toString()});
      }

      return {'success': true, 'message': ''};
    } catch (e) {
      String errorMessage = 'Credenciales incorrectas';

      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'No existe una cuenta con este correo electrónico';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Contraseña incorrecta';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Formato de correo electrónico inválido';
        }
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Obtener el deviceId del usuario actual
  Future<String?> getDeviceId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    return doc.data()?['deviceId'];
  }

  // Cerrar sesión
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

  // Restablecer contraseña
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Se ha enviado un correo para restablecer tu contraseña',
      };
    } catch (e) {
      String errorMessage = 'No se pudo enviar el correo de restablecimiento';

      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'No existe una cuenta con este correo electrónico';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'El formato del correo electrónico no es válido';
        }
      }

      return {'success': false, 'message': errorMessage};
    }
  }
}
