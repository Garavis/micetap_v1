import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';
import 'package:path_provider/path_provider.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  _AlertsViewState createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  String? deviceId;
  bool _isLoading = true;
  String? _debugError;
  List<Map<String, dynamic>> _alertasActuales = [];

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _debugError = "No hay usuario autenticado";
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final fetchedId = doc.data()?['deviceId'];
        setState(() {
          deviceId = fetchedId.toString().trim();
          _isLoading = false;
        });
      } else {
        _debugError = "Usuario no encontrado";
        _isLoading = false;
      }
    } catch (e) {
      _debugError = "Error al obtener usuario: $e";
      _isLoading = false;
    }
  }

  void _exportar() async {
    if (_alertasActuales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay alertas para exportar')),
      );
      return;
    }

    try {
      final List<List<String>> rows = [
        ['Fecha', 'Tipo', 'Mensaje']
      ];

      for (final alerta in _alertasActuales) {
        rows.add([
          alerta['date'] ?? 'Sin fecha',
          alerta['type'] ?? 'Desconocido',
          alerta['message'] ?? 'Mensaje vacío',
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        final blob = html.Blob([csvData]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'alertas_exportadas.csv';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/alertas_exportadas.csv');
        await file.writeAsString(csvData);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exportación exitosa'),
            content: Text('El archivo se ha guardado en:\n\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error al exportar alertas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al exportar alertas')),
      );
    }
  }

  void _vaciar() async {
    if (deviceId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('alertas')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alertas eliminadas')),
    );
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
            stream: FirebaseFirestore.instance
                .collection('alertas')
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay alertas registradas."));
              }

              final allAlertas = snapshot.data!.docs;

              final filtered = allAlertas.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final alertDeviceId = data['deviceId']?.toString().trim();
                return alertDeviceId == deviceId;
              }).toList();

              _alertasActuales = filtered.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'type': data['tipo'],
                  'message': data['mensaje'],
                  'date': (data['fecha'] as Timestamp?)?.toDate().toLocal().toString(),
                };
              }).toList();

              if (_alertasActuales.isEmpty) {
                return const Center(child: Text("No hay alertas para este dispositivo."));
              }

              return ListView.builder(
                itemCount: _alertasActuales.length,
                itemBuilder: (context, index) =>
                    _buildAlertItemCard(_alertasActuales[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItemCard(Map<String, dynamic> alert) {
    IconData icon;
    Color iconColor;

    switch (alert['type']) {
      case 'warning':
        icon = Icons.warning_amber_outlined;
        iconColor = Colors.orange;
        break;
      case 'critical':
        icon = Icons.close;
        iconColor = Colors.red;
        break;
      case 'excellent':
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
                      alert['message'] ?? '',
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
              if (alert['date'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 34.0),
                  child: Text(
                    alert['date'],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: deviceId == null
                        ? const Center(child: Text("No hay deviceId"))
                        : _buildAlertList(deviceId!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _exportar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            child: const Text('Exportar', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _vaciar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            child: const Text('Vaciar', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const FloatingBackButton(route: '/home'),
                ],
              ),
            ),
    );
  }
}
