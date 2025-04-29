import 'package:flutter/material.dart';
import 'package:micetap_v1/widgets/texfieldregistros.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  // Estados de carga separados para cada botón
  bool _isLoginLoading = false;
  bool _isRegisterLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoginLoading = true);
    final result = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (result['success']) {
      final deviceId = await _authController.getDeviceId();

      if (deviceId != null) {
        // Guardar en memoria o pasarlo por navegación
        Navigator.pushReplacementNamed(context, '/home', arguments: deviceId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener ID del dispositivo')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
    setState(() => _isLoginLoading = false);
  }

  void _handleRegister() {
    Navigator.pushNamed(context, '/register');
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ayuda'),
          content: const Text(
            'Para iniciar sesión, introduce tu correo electrónico y contraseña.\n\n'
            'Si no tienes una cuenta, pulsa "Registrarse" para crear una nueva.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla para mejor distribución
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.vertical,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Sección del logo
                Container(
                  margin: EdgeInsets.only(top: screenHeight * 0.05),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/MICETAP.png',
                        height: 100,
                        width: 100,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'MICETAP',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección de formulario
                Container(
                  margin: EdgeInsets.only(top: screenHeight * 0.05),
                  child: Column(
                    children: [
                      // Campo de usuario/correo
                      textfieldcampos(
                        Controller: _emailController,
                        text: 'Usuario o Correo Electronico',
                      ),
                      const SizedBox(height: 20),
                      // Campo de contraseña
                      textfieldcampos(
                        Controller: _passwordController,
                        text: 'Contrseña',
                        isPassword: true,
                      ),
                    ],
                  ),
                ),

                // Sección de botones
                Container(
                  margin: EdgeInsets.only(top: screenHeight * 0.05),
                  child: Column(
                    children: [
                      // Botón de inicio de sesión
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoginLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child:
                              _isLoginLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),

                      SizedBox(height: 15),

                      // Botón de registro
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _isRegisterLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child:
                              _isRegisterLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Registrarse',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Añadir en login_view.dart después de los campos de texto
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reset-password');
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ),
                // Espacio en la parte inferior
                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showHelp,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.help, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
