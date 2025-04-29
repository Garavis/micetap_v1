import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:micetap_v1/controllers/user_config_controller.dart';
import 'package:micetap_v1/models/user_config_model.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class ConfigView extends StatefulWidget {
  const ConfigView({Key? key}) : super(key: key);

  @override
  _ConfigViewState createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  final ConfigController _controller = ConfigController();
  bool _isEditing = false;
  final TextEditingController _nombreController = TextEditingController();

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'No disponible';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('CONFIGURACIÓN'),
      body: StreamBuilder<UserConfigModel>(
        stream: _controller.getUserConfigStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          final userData = snapshot.data!;

          if (!_isEditing) {
            _nombreController.text = userData.nombre;
          }

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Avatar y nombre de usuario
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditing = !_isEditing;
                                if (!_isEditing &&
                                    _nombreController.text.isNotEmpty &&
                                    _nombreController.text != userData.nombre) {
                                  _controller.updateProfileInfo({
                                    'nombre': _nombreController.text,
                                  });
                                }
                              });
                            },
                            child: Icon(
                              _isEditing ? Icons.check : Icons.edit,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Nombre (editable o de solo lectura)
                  _isEditing
                      ? TextField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _controller.updateProfileInfo({'nombre': value});
                          }
                          setState(() {
                            _isEditing = false;
                          });
                        },
                      )
                      : Text(
                        userData.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                  const SizedBox(height: 25),

                  // Tarjeta de información personal
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            const Icon(
                              Icons.email,
                              color: Colors.blue,
                              size: 20,
                            ),
                            'Correo electrónico',
                            userData.email,
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.blue,
                              size: 20,
                            ),
                            'Último acceso',
                            _formatDateTime(userData.lastLogin),
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            const Icon(
                              Icons.access_time,
                              color: Colors.blue,
                              size: 20,
                            ),
                            'Cuenta creada',
                            userData.createdAt.isNotEmpty
                                ? _formatDateTime(userData.createdAt)
                                : 'No disponible',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta de información del dispositivo
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del Dispositivo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            const Icon(
                              Icons.device_hub,
                              color: Colors.blue,
                              size: 20,
                            ),
                            'ID del Dispositivo',
                            userData.deviceId,
                            valueStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            const Icon(
                              Icons.security,
                              color: Colors.blue,
                              size: 20,
                            ),
                            'Estado',
                            'Activo',
                            valueStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botón de cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _controller.signOut();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FloatingBackButton(route: '/home'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    Icon icon,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    valueStyle ??
                    const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
