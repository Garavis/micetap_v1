import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micetap_v1/controllers/alert_controller.dart';
import 'package:micetap_v1/models/alert_model.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  _AlertsViewState createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  final AlertsController _controller = AlertsController();
  String? deviceId;
  bool _isLoading = true;
  String? _debugError;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
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

  void _exportar() async {
    await _controller.exportAlerts(context);
  }

  void _vaciar() async {
    if (deviceId == null) return;

    await _controller.clearAlerts(deviceId!);

    if (!mounted) return;

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
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _controller.getAlertsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay alertas registradas."));
              }

              final alertas = _controller.filterAlertsByDeviceId(
                snapshot.data!,
                deviceId,
              );

              if (alertas.isEmpty) {
                return const Center(
                  child: Text("No hay alertas para este dispositivo."),
                );
              }

              return ListView.builder(
                itemCount: alertas.length,
                itemBuilder:
                    (context, index) => _buildAlertItemCard(alertas[index]),
              );
            },
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
                        onPressed: _exportar,
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
                        onPressed: _vaciar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
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
