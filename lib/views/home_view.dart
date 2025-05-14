import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:micetap_v1/controllers/home_controller.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController _controller = HomeController();
  String? deviceId;
  bool _isLoading = true;

  // Control de actualización automática
  bool _autoUpdateEnabled = true; // Por defecto activado

  // Variables para mostrar consumo si no hay actualización automática
  double _lastConsumo = 0.0;
  DateTime _lastUpdateTime = DateTime.now();

  // Para forzar la reconstrucción del StreamBuilder
  int _streamRebuildCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
    _loadAutoUpdatePreference();
  }

  // Cargar preferencia de actualización automática
  Future<void> _loadAutoUpdatePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPreference = prefs.getBool('autoUpdateEnabled');

      if (savedPreference != null) {
        setState(() {
          _autoUpdateEnabled = savedPreference;
        });
      }
    } catch (e) {
      print('Error al cargar preferencia de actualización: $e');
    }
  }

  // Guardar preferencia de actualización automática
  Future<void> _saveAutoUpdatePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoUpdateEnabled', value);
    } catch (e) {
      print('Error al guardar preferencia de actualización: $e');
    }
  }

  // Cambiar modo de actualización
  void _toggleAutoUpdate(bool value) async {
    // Guardar preferencia
    await _saveAutoUpdatePreference(value);

    // Actualizar UI
    setState(() {
      _autoUpdateEnabled = value;
      // Forzar reconstrucción del StreamBuilder si cambiamos a tiempo real
      if (value) {
        _streamRebuildCounter++;
      }
    });

    // Mostrar mensaje de confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Actualización en tiempo real activada'
                : 'Actualización en tiempo real desactivada',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Si desactivamos las actualizaciones en tiempo real, actualizar manualmente una vez
    if (!value && deviceId != null) {
      _actualizarManualmente();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    try {
      // Primero intentamos cargar desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString('deviceId');

      if (mounted) {
        setState(() {
          deviceId =
              savedDeviceId ??
              'MT-2504-98A7'; // Usa el ID guardado o el predeterminado
          _isLoading = false;
        });
      }

      // Inicializar datos si tenemos deviceId
      if (deviceId != null && !_autoUpdateEnabled) {
        // Si no está en tiempo real, cargar datos una vez
        _actualizarManualmente();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          deviceId = 'MT-2504-98A7'; // Fallback al ID predeterminado
          _isLoading = false;
        });

        if (!_autoUpdateEnabled) {
          _actualizarManualmente();
        }
      }
    }
  }

  // Método para actualización manual
  Future<void> _actualizarManualmente() async {
    if (deviceId == null) return;

    setState(() => _isLoading = true);

    try {
      final consumo = await _controller.getConsumoActual(deviceId!);

      setState(() {
        _lastConsumo = consumo;
        _lastUpdateTime = DateTime.now();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos actualizados correctamente'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Intentamos obtener el ID desde los argumentos de la ruta
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      // Solo actualizamos si es diferente al actual para evitar recargas innecesarias
      if (deviceId != args) {
        setState(() {
          deviceId = args;
          // Forzar reconstrucción del StreamBuilder al cambiar de dispositivo
          _streamRebuildCounter++;
        });

        // Si no es tiempo real, actualizar una vez
        if (!_autoUpdateEnabled) {
          _actualizarManualmente();
        }

        // Guardar en SharedPreferences para futura referencia
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('deviceId', args);
        });
      }
    }
  }

  // Obtener el Stream de Firebase para el consumo en tiempo real
  Stream<DocumentSnapshot> _getRealtimeStream() {
    if (deviceId == null) {
      // Devolver un stream vacío si no hay deviceId
      return Stream.empty();
    }

    // Usar el stream directo de Firestore para asegurar actualización en tiempo real
    return FirebaseFirestore.instance
        .collection('dispositivos')
        .doc(deviceId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('MICETAP'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grid de opciones
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.85,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildMenuCard(
                            title: 'Historial',
                            imagePath: 'assets/images/home/history.png',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/history',
                                arguments: deviceId,
                              );
                            },
                          ),
                          _buildMenuCard(
                            title: 'Alertas',
                            imagePath: 'assets/images/home/alert.png',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/alerts',
                                arguments: deviceId,
                              );
                            },
                          ),
                          _buildMenuCard(
                            title: 'Sugerencias',
                            imagePath: 'assets/images/home/suge.png',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/suggestions',
                                arguments: deviceId,
                              );
                            },
                          ),
                          _buildMenuCard(
                            title: 'Configuración',
                            imagePath: 'assets/images/home/config.png',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/config',
                                arguments: deviceId,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Switch para activar/desactivar actualización en tiempo real
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.blue, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Actualización en tiempo real',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          Switch(
                            value: _autoUpdateEnabled,
                            onChanged: _toggleAutoUpdate,
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    // Indicador de consumo
                    Column(
                      children: [
                        const Text(
                          'Consumo Actual kWh:',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),

                        if (_autoUpdateEnabled)
                          // Modo tiempo real usando Key único para forzar reconstrucción
                          StreamBuilder<DocumentSnapshot>(
                            key: Key('consumo_stream_$_streamRebuildCounter'),
                            stream: _getRealtimeStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              }

                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return const Text(
                                  "Sin datos",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }

                              // Obtener consumo directamente del snapshot
                              final data =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>?;
                              final consumo = data?['consumo'] ?? 0.0;
                              final consumoValue =
                                  consumo is double
                                      ? consumo
                                      : double.parse(consumo.toString());

                              return Column(
                                children: [
                                  Text(
                                    consumoValue
                                        .toStringAsFixed(5)
                                        .padLeft(8, '0'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Text(
                                    '(Actualización en tiempo real)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          // Modo manual: mostrar último dato obtenido
                          Column(
                            children: [
                              Text(
                                _lastConsumo.toStringAsFixed(5).padLeft(8, '0'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Actualizado a las ${_lastUpdateTime.hour.toString().padLeft(2, '0')}:${_lastUpdateTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : _actualizarManualmente,
                                    tooltip: 'Actualizar datos',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),

                        // ID del dispositivo
                        Text(
                          'ID: $deviceId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                        const Text(
                          '©Powered by: Garavis A, Paz H',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey[50],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
