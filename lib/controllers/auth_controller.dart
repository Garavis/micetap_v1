// controllers/auth_controller.dart
import '../models/user_model.dart';

class AuthController {
  Future<bool> login(UserModel user) async {
    // Aquí iría la lógica de autenticación real
    // Por ahora, simulamos un delay y devolvemos true
    await Future.delayed(Duration(seconds: 2));
    
    // En un caso real, aquí enviarías las credenciales a tu backend
    // y manejarías la respuesta
    return true;
  }
}