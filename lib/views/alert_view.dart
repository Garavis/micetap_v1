import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micetap_v1/controllers/alert_controller.dart';
import 'package:micetap_v1/models/alert_model.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});

  @override
  _AlertsViewState createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> with TickerProviderStateMixin {
  final AlertsController _controller = AlertsController();
  String? deviceId;
  bool _isLoading = true;
  String? _debugError;

  // Variables para el progreso de eliminación
  int _totalAlerts = 0;
  int _deletedAlerts = 0;
  bool _showProgress = false;

  // Lista local de alertas
  List<Alert> _alertsList = [];
  bool _isListeningToAlerts = false;

  // Controller para las animaciones
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadDeviceId();
  }

  @override
  void dispose() {
    _progressController.dispose();

    // IMPORTANTE: Detener el stream al salir de la pantalla
    _controller.dispose();

    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    setState(() {
      _isLoading = true;
      _debugError = null;
    });

    try {
      final fetchedId = await _controller.loadDeviceId();

      if (!mounted) return;

      setState(() {
        if (fetchedId != null && fetchedId.isNotEmpty) {
          deviceId = fetchedId;
          _isLoading = false;

          // Cargar datos una sola vez al inicio
          _loadAlerts(fetchedId);
        } else {
          _debugError = "deviceId no encontrado";
          _isLoading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _debugError = "Error al obtener usuario: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlerts(String deviceId) async {
    if (_isListeningToAlerts) return;

    _isListeningToAlerts = true;

    // Iniciar escucha con callback para actualizar UI
    _controller.initAlertsListener(deviceId, (alertas) {
      if (mounted) {
        setState(() {
          _alertsList = alertas;
        });
      }
    });
  }

  void _exportar() async {
    await _controller.exportAlerts(context);
  }

  void _vaciar() async {
    if (deviceId == null) return;
    if (_controller.isDeleting) return; // Prevenir múltiples eliminaciones

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Vaciar alertas'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar todas las alertas? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    setState(() {
      _showProgress = true;
      _totalAlerts = _controller.currentAlerts.length;
      _deletedAlerts = 0;
      _progressController.forward(from: 0.0);
    });

    await _controller.clearAlerts(deviceId!, (deleted, total) {
      if (mounted) {
        setState(() {
          _deletedAlerts = deleted;
          _progressController.value = deleted / total;
        });
      }
    });

    // Pequeña pausa para que se vea que ha terminado al 100%
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _showProgress = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Alertas eliminadas')));
  }

  Widget _buildAlertList(String deviceId) {
    return Column(
      children: [
        if (_debugError != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              color: Colors.red[100],
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Debug: $_debugError",
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
          ),
        if (_showProgress)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _progressController,
                  builder:
                      (context, _) => LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Eliminando... $_deletedAlerts de $_totalAlerts',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        Expanded(
          child:
              _alertsList.isEmpty
                  ? const Center(
                    child: Text(
                      "No hay alertas registradas para este dispositivo.",
                    ),
                  )
                  : ListView.builder(
                    itemCount: _alertsList.length,
                    itemBuilder:
                        (context, index) =>
                            _buildAlertItemCard(_alertsList[index]),
                  ),
        ),
      ],
    );
  }

  Widget _buildAlertItemCard(Alert alert) {
    final visualData = _controller.getAlertVisualData(alert.type);
    final IconData icon = visualData['icon'];
    final Color iconColor = visualData['color'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      alert.message ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              if (alert.date != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 34.0),
                  child: Text(
                    alert.date!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('ALERTAS'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Histórico de Alertas',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'ID: $deviceId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child:
                          deviceId == null
                              ? const Center(child: Text("No hay deviceId"))
                              : _buildAlertList(deviceId!),
                    ),
                    const SizedBox(height: 20),
                    // Botón de Exportar consistente con Config View
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _controller.isDeleting ? null : _exportar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Exportar',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Botón de Vaciar consistente con Config View
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _controller.isDeleting ? null : _vaciar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _controller.isDeleting
                                  ? Colors.grey
                                  : Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _controller.isDeleting
                                ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Vaciando...',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                )
                                : const Text(
                                  'Vaciar',
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
  }
}
