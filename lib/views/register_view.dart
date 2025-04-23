import 'package:flutter/material.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';
import 'package:micetap_v1/widgets/texfieldregistros.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idDevice = TextEditingController();
  final TextEditingController _passwordAccess = TextEditingController();
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _idDevice.dispose();
    _passwordAccess.dispose();
    super.dispose();
  }

  void _handleRegister() async {
  if (_nameController.text.isEmpty || 
      _emailController.text.isEmpty || 
      _passwordController.text.isEmpty ||
      _idDevice.text.isEmpty ||
      _passwordAccess.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor completa todos los campos')),
    );
    return;
  }

  if (_passwordAccess.text != '1109') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña Administrativa no válida')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final result = await _authController.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      _idDevice.text.trim(),
    );

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error en el registro: ${e.toString()}')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: customAppBar('Registro'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              
              // Logo
              Image.asset(
                'assets/images/MICETAP.png',
                height: 80,
                width: 80,
              ),
              const SizedBox(height: 10),
              const Text(
                'MICETAP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              // Formulario de registro
              textfieldcampos(Controller: _nameController, text: 'Nombre completo'),
              const SizedBox(height: 15),
              textfieldcampos(Controller: _emailController, text: 'Correo Electrónico'),
              const SizedBox(height: 15),
              textfieldcampos(Controller: _passwordController, text: 'Contraseña', isPassword: true),
              const SizedBox(height: 15),
              textfieldcampos(Controller: _idDevice, text: 'Id de Dispositivo'),
              const SizedBox(height: 15),
              textfieldcampos(Controller: _passwordAccess, text: 'Clave Administrativa', isPassword: true),
              SizedBox(height: screenHeight * 0.02),
              
              // Botón de registro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              const FloatingBackButton(route: '/'),

            ],
          ),
        ),
      ),
    );
  }
}

