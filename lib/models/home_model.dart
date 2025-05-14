import 'package:cloud_firestore/cloud_firestore.dart';

class HomeModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Caché para evitar lecturas innecesarias
  Map<String, DocumentSnapshot> _cachedSnapshots = {};
  Map<String, DateTime> _lastFetchTimes = {};

  // Stream<DocumentSnapshot> getConsumoStream(String deviceId) {
  //   return _firestore
  //       .collection('dispositivos')
  //       .doc(deviceId)
  //       .snapshots();
  // }

  // Método optimizado que usa caché y reduce lecturas
  Stream<DocumentSnapshot> getConsumoStream(String deviceId) {
    // Si tenemos un caché reciente (menos de 5 minutos), devolver un stream simulado
    if (_cachedSnapshots.containsKey(deviceId) &&
        _lastFetchTimes.containsKey(deviceId) &&
        DateTime.now().difference(_lastFetchTimes[deviceId]!).inMinutes < 5) {
      // Crear un stream con el snapshot en caché
      return Stream.value(_cachedSnapshots[deviceId]!);
    }

    // Si no tenemos caché o ya está desactualizado, hacer una consulta real
    return _firestore.collection('dispositivos').doc(deviceId).snapshots().map((
      snapshot,
    ) {
      // Guardar en caché
      _cachedSnapshots[deviceId] = snapshot;
      _lastFetchTimes[deviceId] = DateTime.now();
      return snapshot;
    });
  }

  // Método para obtener consumo sin usar stream (una única lectura)
  Future<DocumentSnapshot?> getConsumoSingleRead(String deviceId) async {
    try {
      // Si tenemos un caché reciente (menos de 5 minutos), usar ese
      if (_cachedSnapshots.containsKey(deviceId) &&
          _lastFetchTimes.containsKey(deviceId) &&
          DateTime.now().difference(_lastFetchTimes[deviceId]!).inMinutes < 5) {
        return _cachedSnapshots[deviceId];
      }

      // Hacer una lectura única
      final snapshot =
          await _firestore.collection('dispositivos').doc(deviceId).get();

      // Guardar en caché
      if (snapshot.exists) {
        _cachedSnapshots[deviceId] = snapshot;
        _lastFetchTimes[deviceId] = DateTime.now();
      }

      return snapshot;
    } catch (e) {
      print('Error al obtener consumo: $e');
      return null;
    }
  }

  // Limpiar caché para dispositivo específico
  void limpiarCache(String deviceId) {
    _cachedSnapshots.remove(deviceId);
    _lastFetchTimes.remove(deviceId);
  }

  // Limpiar toda la caché
  void limpiarTodaCache() {
    _cachedSnapshots.clear();
    _lastFetchTimes.clear();
  }
}
