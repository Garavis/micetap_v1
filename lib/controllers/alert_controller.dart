//import 'dart:html' as html;
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:micetap_v1/models/alert_model.dart';
import 'package:path_provider/path_provider.dart';

class AlertsController {
  final AlertsModel _model = AlertsModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Variable para almacenar las alertas actuales
  List<Alert> _currentAlerts = [];
  
  // Getters
  List<Alert> get currentAlerts => _currentAlerts;
  
  // Obtener el deviceId del usuario actual
Future<String?> loadDeviceId() async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      print('Error: Usuario no autenticado');
      return null;
    }

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final fetchedId = doc.data()!['deviceId'];
      print('DeviceId encontrado: $fetchedId');  // Para depuración
      
      if (fetchedId == null) {
        print('Error: deviceId es null en el documento');
        return null;
      }
      
      return fetchedId.toString().trim();
    } else {
      print('Error: Documento de usuario no existe o está vacío');
      return null;
    }
  } catch (e) {
    print('Error al cargar deviceId: $e');
    return null;
  }
}
  
  // Filtrar alertas por deviceId
  List<Alert> filterAlertsByDeviceId(QuerySnapshot snapshot, String deviceId) {
    final allAlerts = snapshot.docs;
    
    final filtered = allAlerts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final alertDeviceId = data['deviceId']?.toString().trim();
      return alertDeviceId == deviceId;
    }).toList();
    _currentAlerts = filtered.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Alert.fromFirestore(data);
    }).toList();
    
    return _currentAlerts;
  }
  
  // Obtener stream de alertas
  Stream<QuerySnapshot> getAlertsStream() {
    return _model.getAlertsStream();
  }
  
  // Vaciar alertas
  Future<void> clearAlerts(String deviceId) async {
    await _model.deleteAlertsByDeviceId(deviceId);
  }
  
  // Exportar alertas a CSV
  Future<void> exportAlerts(BuildContext context) async {
    if (_currentAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay alertas para exportar')),
      );
      return;
    }

    try {
      final List<List<String>> rows = [
        ['Fecha', 'Tipo', 'Mensaje']
      ];

      for (final alerta in _currentAlerts) {
        rows.add([
          alerta.date ?? 'Sin fecha',
          alerta.type ?? 'Desconocido',
          alerta.message ?? 'Mensaje vacío',
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        
        /*
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
        */
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
  // Obtener el ícono y color según el tipo de alerta
  Map<String, dynamic> getAlertVisualData(String? type) {
    IconData icon;
    Color iconColor;

    switch (type) {
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
    return {
      'icon': icon,
      'color': iconColor,
    };
  }
}