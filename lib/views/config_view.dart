import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:micetap_v1/controllers/user_config_controller.dart';
import 'package:micetap_v1/models/user_config_model.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class ConfigView extends StatefulWidget {
  const ConfigView({super.key});

  @override
  _ConfigViewState createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  final ConfigController _controller = ConfigController();
  bool _isEditing = false;
  final TextEditingController _nombreController = TextEditingController();
  int _selectedEstrato = 1; // Valor predeterminado: estrato 1

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 1,
  );

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

          // Inicializar el estrato seleccionado con el del usuario
          if (!_isEditing) {
            _nombreController.text = userData.nombre;
            _selectedEstrato = userData.estrato;
          }

          return SafeArea(
            child: Stack(
              children: [
                // Contenido principal en un SingleChildScrollView
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar y nombre de usuario (centrado)
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            // Avatar con botón de edición
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
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
                                              _nombreController
                                                  .text
                                                  .isNotEmpty &&
                                              (_nombreController.text !=
                                                      userData.nombre ||
                                                  _selectedEstrato !=
                                                      userData.estrato)) {
                                            _controller.updateProfileInfo({
                                              'nombre': _nombreController.text,
                                              'estrato': _selectedEstrato,
                                            });
                                          }
                                        });
                                      },
                                      child: Icon(
                                        _isEditing ? Icons.check : Icons.edit,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Nombre (editable o de solo lectura)
                            _isEditing
                                ? Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: TextField(
                                        controller: _nombreController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        onSubmitted: (value) {
                                          if (value.isNotEmpty) {
                                            _controller.updateProfileInfo({
                                              'nombre': value,
                                            });
                                          }
                                          setState(() {
                                            _isEditing = false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Selector de estrato
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: DropdownButtonFormField<int>(
                                        value: _selectedEstrato,
                                        decoration: const InputDecoration(
                                          labelText: 'Estrato',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        items:
                                            [1, 2, 3, 4, 5, 6].map((int value) {
                                              return DropdownMenuItem<int>(
                                                value: value,
                                                child: Text('Estrato $value'),
                                              );
                                            }).toList(),
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedEstrato = newValue;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                )
                                : Column(
                                  children: [
                                    Text(
                                      userData.nombre,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Estrato ${userData.estrato}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Tarjeta de información personal
                      _buildSectionTitle('Información Personal'),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                const Icon(
                                  Icons.email,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                'Correo electrónico',
                                userData.email,
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow(
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                'Último acceso',
                                _formatDateTime(userData.lastLogin),
                                badgeText: 'Actualizado',
                                badgeColor: Colors.green,
                                tooltip:
                                    'Última vez que iniciaste sesión en la aplicación',
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow(
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.blue,
                                  size: 24,
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

                      const SizedBox(height: 24),

                      // Tarjeta de información del dispositivo
                      _buildSectionTitle('Información del Dispositivo'),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                const Icon(
                                  Icons.device_hub,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                'ID del Dispositivo',
                                userData.deviceId,
                                valueStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow(
                                const Icon(
                                  Icons.security,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                'Estado',
                                'Activo',
                                valueStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                                badgeText: 'En línea',
                                badgeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tarjeta de tarifas energéticas
                      const SizedBox(height: 24),
                      _buildSectionTitle('Tarifas de Energía'),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTarifaRow(1, 349.8, userData.estrato == 1),
                              const SizedBox(height: 12),
                              _buildTarifaRow(2, 437.3, userData.estrato == 2),
                              const SizedBox(height: 12),
                              _buildTarifaRow(3, 737.6, userData.estrato == 3),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Las tarifas pueden variar según la región y el proveedor de energía.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Diálogo de confirmación antes de cerrar sesión
                            final confirmClose = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Cerrar Sesión'),
                                    content: const Text(
                                      '¿Estás seguro de que deseas cerrar sesión?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: const Text('Cerrar Sesión'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirmClose == true) {
                              await _controller.signOut();
                              // Usar pushNamedAndRemoveUntil para eliminar todas las rutas anteriores
                              // y evitar que se pueda volver al home sin iniciar sesión
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/', // Ruta hacia la pantalla de login
                                (route) =>
                                    false, // Esto elimina todas las rutas anteriores
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 80,
                      ), // Espacio adicional para el botón de volver
                    ],
                  ),
                ),

                // Botón flotante para volver
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingBackButton(route: '/home'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTarifaRow(int estrato, double tarifa, bool isCurrentEstrato) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isCurrentEstrato ? Colors.blue.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (isCurrentEstrato)
            const Icon(Icons.check_circle, color: Colors.blue, size: 24)
          else
            const SizedBox(width: 24),
          const SizedBox(width: 12),
          Text(
            'Estrato $estrato:',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  isCurrentEstrato ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            '${_currencyFormat.format(tarifa)}/kWh',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  isCurrentEstrato ? FontWeight.bold : FontWeight.normal,
              color: isCurrentEstrato ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    Icon icon,
    String label,
    String value, {
    TextStyle? valueStyle,
    String? badgeText,
    Color? badgeColor,
    String? tooltip,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style:
                          valueStyle ??
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  if (badgeText != null)
                    Tooltip(
                      message: tooltip ?? '',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              badgeColor?.withOpacity(0.2) ??
                              Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: badgeColor ?? Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
