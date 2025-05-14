import 'dart:io';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:micetap_v1/models/alert_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async'; // Importamos para StreamSubscription

class AlertsController {
  final AlertsModel _model = AlertsModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variable para almacenar las alertas actuales
  List<Alert> _currentAlerts = [];

  // Variable para controlar el estado de eliminación
  bool _isDeleting = false;

  // Stream subscription para manejar la limpieza
  StreamSubscription<QuerySnapshot>? _alertsSubscription;

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

  // Obtener stream de alertas (limitado a 50 alertas)
  Stream<QuerySnapshot> getAlertsStream() {
    return _model.getAlertsStreamLimited(50);
  }

  // Método para cargar alertas por demanda (sin stream continuo)
  Future<List<Alert>> loadAlertsByDeviceId(
    String deviceId, {
    int limit = 50,
  }) async {
    final alerts = await _model.getAlertsByDeviceIdLimited(deviceId, limit);
    _currentAlerts = alerts;
    return alerts;
  }

  // Vaciar alertas con animación progresiva - FIX para RangeError
  Future<void> clearAlerts(
    String deviceId,
    Function(int, int) onProgress,
  ) async {
    if (_isDeleting) return; // Prevenir múltiples eliminaciones simultáneas

    _isDeleting = true;
    final totalItems = _currentAlerts.length;
    int deletedItems = 0;

    try {
      if (totalItems > 0) {
        // Procesamos las alertas en lotes para evitar problemas
        for (int i = 0; i < totalItems; i += 10) {
          // Crear un nuevo batch para cada grupo
          final batch = _firestore.batch();

          // Determinar cuántos elementos procesar en este lote
          final end = i + 10 < totalItems ? i + 10 : totalItems;

          // Agregar los documentos del lote al batch
          for (int j = i; j < end; j++) {
            if (j < _currentAlerts.length && _currentAlerts[j].docId != null) {
              batch.delete(
                _firestore.collection('alertas').doc(_currentAlerts[j].docId),
              );
            }
          }

          // Ejecutar el batch
          await batch.commit();

          // Actualizar el progreso
          deletedItems = end;
          onProgress(deletedItems, totalItems);

          // Pequeña pausa para la UI
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Asegurarnos de que no queden alertas sin eliminar
      final snapshot =
          await _firestore
              .collection('alertas')
              .where('deviceId', isEqualTo: deviceId)
              .limit(100) // Limitar la consulta de limpieza
              .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
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

  // Método para iniciar la escucha de alertas
  void initAlertsListener(
    String deviceId,
    Function(List<Alert>) onAlertsUpdate,
  ) {
    // Cancelar suscripción previa si existe
    _alertsSubscription?.cancel();

    // Crear nueva suscripción con límite
    _alertsSubscription = _model.getAlertsStreamLimited(50).listen((snapshot) {
      final filteredAlerts = filterAlertsByDeviceId(snapshot, deviceId);
      onAlertsUpdate(filteredAlerts);
    });
  }

  // Método para liberar recursos
  void dispose() {
    _alertsSubscription?.cancel();
    _alertsSubscription = null;
  }
}
