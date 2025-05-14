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
      fecha:
          data['fecha'] != null
              ? (data['fecha'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Método para comparar modelos (para caché optimizada)
  bool equals(SuggestionModel other) {
    return id == other.id &&
        deviceId == other.deviceId &&
        tipoAlerta == other.tipoAlerta &&
        mensajeCorto == other.mensajeCorto;
  }
}

// Extensión para manejar caché de sugerencias
class SuggestionCache {
  // Caché de sugerencias por dispositivo
  static Map<String, List<SuggestionModel>> _cacheByDevice = {};
  static Map<String, DateTime> _lastFetchTime = {};

  // Tiempo de caducidad de caché (10 minutos)
  static const Duration _cacheDuration = Duration(minutes: 10);

  // Obtener de caché
  static List<SuggestionModel>? getFromCache(String deviceId) {
    if (!_cacheByDevice.containsKey(deviceId) ||
        !_lastFetchTime.containsKey(deviceId)) {
      return null;
    }

    // Verificar si el caché está caducado
    final lastFetch = _lastFetchTime[deviceId]!;
    if (DateTime.now().difference(lastFetch) > _cacheDuration) {
      return null;
    }

    return _cacheByDevice[deviceId];
  }

  // Guardar en caché
  static void saveToCache(String deviceId, List<SuggestionModel> suggestions) {
    _cacheByDevice[deviceId] = suggestions;
    _lastFetchTime[deviceId] = DateTime.now();
  }

  // Limpiar caché para un dispositivo
  static void clearCacheForDevice(String deviceId) {
    _cacheByDevice.remove(deviceId);
    _lastFetchTime.remove(deviceId);
  }

  // Limpiar toda la caché
  static void clearAllCache() {
    _cacheByDevice.clear();
    _lastFetchTime.clear();
  }
}
