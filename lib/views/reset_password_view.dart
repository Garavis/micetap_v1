import 'package:flutter/material.dart';
import 'package:micetap_v1/controllers/auth_controller.dart';
import 'package:micetap_v1/widgets/texfieldregistros.dart';
import 'package:micetap_v1/widgets/appbard.dart';
// Ya no importamos buttonback.dart

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({Key? key}) : super(key: key);

  @override
  _ResetPasswordViewState createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final TextEditingController _emailController = TextEditingController();
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu correo electrónico'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authController.resetPassword(
      _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));

    if (result['success']) {
      // Dar tiempo para que el usuario lea el mensaje exitoso
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('Restablecer Contraseña'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Logo
                      Image.asset(
                        'assets/images/MICETAP.png',
                        height: 80,
                        width: 80,
                      ),
                      const SizedBox(height: 20),

                      // Texto informativo
                      const Text(
                        'Ingresa tu correo electrónico para recibir un enlace de restablecimiento de contraseña',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 40),

                      // Campo de correo
                      textfieldcampos(
                        Controller: _emailController,
                        text: 'Correo Electrónico',
                      ),

                      const SizedBox(height: 30),

                      // Botón de enviar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Enviar Correo',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Botón de retroceso como un botón separado al final del Column principal
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
