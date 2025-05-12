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

  // Variable para controlar el estado de eliminación
  bool _isDeleting = false;

  // Getters
  List<Alert> get currentAlerts => _currentAlerts;
  bool get isDeleting => _isDeleting;

  // Setter para el estado de eliminación
  set isDeleting(bool value) => _isDeleting = value;

  // Obtener el deviceId del usuario actual
  Future<String?> loadDeviceId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final fetchedId = doc.data()!['deviceId'];

        if (fetchedId == null) {
          return null;
        }

        return fetchedId.toString().trim();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Filtrar alertas por deviceId
  List<Alert> filterAlertsByDeviceId(QuerySnapshot snapshot, String deviceId) {
    final allAlerts = snapshot.docs;

    final filtered =
        allAlerts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final alertDeviceId = data['deviceId']?.toString().trim();
          return alertDeviceId == deviceId;
        }).toList();

    _currentAlerts =
        filtered.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final alert = Alert.fromFirestore(data);
          alert.docId =
              doc.id; // Guardar el ID del documento para la eliminación
          return alert;
        }).toList();

    return _currentAlerts;
  }

  // Obtener stream de alertas
  Stream<QuerySnapshot> getAlertsStream() {
    return _model.getAlertsStream();
  }

  // Vaciar alertas con animación progresiva
  Future<void> clearAlerts(
    String deviceId,
    Function(int, int) onProgress,
  ) async {
    if (_isDeleting) return; // Prevenir múltiples eliminaciones simultáneas

    _isDeleting = true;
    final totalItems = _currentAlerts.length;
    int deletedItems = 0;

    try {
      // Ordenamos las alertas por fecha más reciente primero (para eliminar de arriba a abajo)
      _currentAlerts.sort((a, b) {
        if (a.dateTime == null || b.dateTime == null) return 0;
        return b.dateTime!.compareTo(a.dateTime!);
      });

      for (final alert in _currentAlerts) {
        if (alert.docId != null) {
          await _firestore.collection('alertas').doc(alert.docId).delete();
          deletedItems++;
          onProgress(deletedItems, totalItems); // Actualizamos el progreso

          // Pequeña pausa para hacer visible la eliminación progresiva
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      // Eliminar cualquier alerta restante que pueda no tener ID
      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('alertas')
              .where('deviceId', isEqualTo: deviceId)
              .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error al eliminar alertas: $e');
    } finally {
      _isDeleting = false;
    }
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
        ['Fecha', 'Tipo', 'Mensaje'],
      ];

      for (final alerta in _currentAlerts) {
        rows.add([
          alerta.date ?? 'Sin fecha',
          alerta.type ?? 'Desconocido',
          alerta.message ?? 'Mensaje vacío',
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);

      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/alertas_exportadas.csv');
        await file.writeAsString(csvData);

        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
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
    return {'icon': icon, 'color': iconColor};
  }
}
