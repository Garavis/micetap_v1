import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:micetap_v1/controllers/home_controller.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Necesitarás agregar esta dependencia

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController _controller = HomeController();
  Stream<DocumentSnapshot>? _consumoStream;
  String? deviceId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    try {
      // Primero intentamos cargar desde SharedPreferences (esto es opcional)
      final prefs = await SharedPreferences.getInstance();
      String? savedDeviceId = prefs.getString('deviceId');
      
      setState(() {
        deviceId = savedDeviceId ?? 'MT-2504-98A7'; // Usa el ID guardado o el predeterminado
        _isLoading = false;
      });
      
      // Importante: Inicializar el stream después de tener el deviceId
      if (deviceId != null) {
        _consumoStream = _controller.getConsumoStream(deviceId!);
      }
    } catch (e) {
      print("Error al cargar deviceId: $e");
      setState(() {
        deviceId = 'MT-2504-98A7'; // Fallback al ID predeterminado
        _consumoStream = _controller.getConsumoStream(deviceId!);
        _isLoading = false;
      });
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
          _consumoStream = _controller.getConsumoStream(deviceId!);
        });
        
        // Opcional: guardar en SharedPreferences para futura referencia
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('deviceId', deviceId!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('MICETAP'),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            Navigator.pushNamed(context, '/history', arguments: deviceId);
                          },
                        ),    
                        _buildMenuCard(
                          title: 'Alertas',
                          imagePath: 'assets/images/home/alert.png',
                          onTap: () {
                            Navigator.pushNamed(context, '/alerts', arguments: deviceId);
                          },
                        ),
                        _buildMenuCard(
                          title: 'Sugerencias',
                          imagePath: 'assets/images/home/suge.png',
                          onTap: () {
                            Navigator.pushNamed(context, '/suggestions', arguments: deviceId);
                          },
                        ),
                        _buildMenuCard(
                          title: 'Configuración',
                          imagePath: 'assets/images/home/config.png',
                          onTap: () {
                            Navigator.pushNamed(context, '/config', arguments: deviceId);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Indicador de consumo
                  if (_consumoStream != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: _consumoStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text(
                            "No se encontró información del dispositivo",
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          );
                        }

                        final consumo = _controller.getConsumoFromSnapshot(snapshot.data!);

                        return Column(
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
                            Text(
                              consumo.toStringAsFixed(5).padLeft(8, '0'),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            // ID del dispositivo (para depuración)
                            Text(
                              'ID: $deviceId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 50),
                            Text(
                              '©Powered by: Garavis A, Paz H',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        );
                      },
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
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