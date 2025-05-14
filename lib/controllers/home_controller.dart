import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:micetap_v1/models/home_model.dart';

class HomeController {
  final HomeModel _model = HomeModel();

  // Variables para control de actualizaciones
  StreamSubscription<DocumentSnapshot>? _streamSubscription;
  Timer? _refreshTimer;
  double _lastConsumoValue = 0.0;
  bool _isListening = false;

  // Callback para notificar cambios
  Function(double)? _onConsumoUpdate;

  // Detener la escucha de cambios
  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isListening = false;
  }

  // Método optimizado para obtener consumo actual (single read en lugar de stream)
  Future<double> getConsumoActual(String deviceId) async {
    final snapshot = await _model.getConsumoSingleRead(deviceId);

    if (snapshot == null || !snapshot.exists) {
      return 0.0;
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    final consumo = data?['consumo'] ?? 0.0;
    _lastConsumoValue =
        consumo is double ? consumo : double.parse(consumo.toString());
    return _lastConsumoValue;
  }

  // Iniciar escucha de cambios con frecuencia reducida
  void iniciarEscuchaConsumo(String deviceId, Function(double) onUpdate) {
    if (_isListening) return;

    _onConsumoUpdate = onUpdate;
    _isListening = true;

    // Primera carga instantánea
    getConsumoActual(deviceId).then((value) {
      if (_onConsumoUpdate != null) {
        _onConsumoUpdate!(value);
      }
    });

    // Configurar actualizaciones periódicas cada 30 segundos en lugar de stream continuo
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final newValue = await getConsumoActual(deviceId);

      // Solo notificar si el valor ha cambiado significativamente
      if ((newValue - _lastConsumoValue).abs() > 0.01 &&
          _onConsumoUpdate != null) {
        _onConsumoUpdate!(newValue);
      }
    });
  }

  // Método antiguo mantenido por compatibilidad
  Stream<DocumentSnapshot> getConsumoStream(String deviceId) {
    return _model.getConsumoStream(deviceId);
  }

  double getConsumoFromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      return 0.0;
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    return data?['consumo'] ?? 0.0;
  }

  // Método para forzar actualización manual
  Future<double> forzarActualizacion(String deviceId) async {
    // Limpiar caché para obtener datos frescos
    _model.limpiarCache(deviceId);
    final newValue = await getConsumoActual(deviceId);
    if (_onConsumoUpdate != null) {
      _onConsumoUpdate!(newValue);
    }
    return newValue;
  }

  // Método para liberar recursos
  void dispose() {
    stopListening();
    _onConsumoUpdate = null;
  }
}
