import 'package:cloud_firestore/cloud_firestore.dart';

class SuggestionModel {
  final String id;
  final String deviceId;
  final String tipoAlerta;
  final String mensajeCorto;
  final String descripcion;
  final DateTime fecha;

  SuggestionModel({
    required this.id,
    required this.deviceId,
    required this.tipoAlerta,
    required this.mensajeCorto,
    required this.descripcion,
    required this.fecha,
  });

  factory SuggestionModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SuggestionModel(
      id: id,
      deviceId: data['deviceId'] ?? '',
      tipoAlerta: data['tipoAlerta'] ?? 'info',
      mensajeCorto: data['mensajeCorto'] ?? 'Sin título',
      descripcion: data['descripcion'] ?? 'Sin descripción',
      fecha: data['fecha'] != null 
          ? (data['fecha'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}