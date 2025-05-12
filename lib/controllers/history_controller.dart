import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:micetap_v1/models/history_model.dart';
import 'package:micetap_v1/models/user_config_model.dart';

class HistoryController {
  final HistoryModel _model = HistoryModel();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _autoRefreshTimer;

  // Guardar la información del estrato
  int _userEstrato = 1;

  // Período de tiempo seleccionado
  String _selectedPeriod = 'Día';
  final List<String> _periodOptions = ['Día', 'Semana', 'Mes'];

  // Tarifas por estrato (en pesos colombianos por kWh)
  final Map<int, double> _tarifasPorEstrato = {
    1: 349.8,
    2: 437.3,
    3: 737.6,
    4: 867.8,
    5: 1040.0,
    6: 1040.0,
  };

  // Getters
  String get selectedPeriod => _selectedPeriod;
  List<String> get periodOptions => _periodOptions;
  List<ConsumoData> get consumoData => _model.consumoData;
  String? get deviceId => _model.deviceId;
  bool get isLoading => _model.isLoading;
  int get userEstrato => _userEstrato;

  // Obtener la tarifa correspondiente al estrato del usuario
  double get tarifaActual =>
      _tarifasPorEstrato[_userEstrato] ?? _tarifasPorEstrato[1]!;

  // Setters
  set isLoading(bool value) => _model.isLoading = value;

  // Inicialización con el ID del dispositivo
  void setDeviceId(String? id) {
    _model.deviceId = id;
    _cargarDatosUsuario(); // Cargar datos del usuario cuando se establece el ID
  }

  // Cargar datos del usuario para obtener el estrato
  Future<void> _cargarDatosUsuario() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          final userData = UserConfigModel.fromFirestore(user.uid, doc.data()!);
          _userEstrato = userData.estrato;
        }
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    }
  }

  // Cambiar período y actualizar datos
  Future<void> cambiarPeriodo(String newPeriod) async {
    _selectedPeriod = newPeriod;
    await cargarDatos();
  }

  // Cargar datos históricos
  Future<void> cargarDatos() async {
    isLoading = true;
    await _model.cargarDatosHistoricos(_selectedPeriod);
    isLoading = false;
  }

  // Iniciar escucha de cambios en el dispositivo para actualización automática
  void iniciarAutoActualizacion() {
    // Detener el timer existente si hay uno
    _detenerAutoActualizacion();

    // Iniciar un nuevo timer que verifica cada minuto si necesitamos actualizar
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) async {
      if (_model.necesitaActualizacion(const Duration(minutes: 5))) {
        await cargarDatos();
      }
    });

    // También configurar escucha de cambios en Firestore si hay un deviceId
    if (_model.deviceId != null) {
      FirebaseFirestore.instance
          .collection('dispositivos')
          .doc(_model.deviceId)
          .snapshots()
          .listen((snapshot) {
            // Si detectamos un cambio en el consumo actual, actualizamos los datos
            if (snapshot.exists) {
              cargarDatos();
            }
          });
    }
  }

  // Detener la auto-actualización
  void _detenerAutoActualizacion() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  // Método para llamar al cerrar la vista
  void dispose() {
    _detenerAutoActualizacion();
  }

  // Obtener información de resumen
  double getConsumoTotal() => _model.getConsumoTotal();
  double getConsumoMaximo() => _model.getConsumoMaximo();
  double getConsumoPromedio() => _model.getConsumoPromedio();

  // Calcular costo según estrato
  double getCostoTotal() {
    return getConsumoTotal() * tarifaActual;
  }

  double getCostoDiarioEstimado() {
    if (_selectedPeriod == 'Día') {
      // Si estamos viendo datos diarios, proyectamos a 24 horas
      return (getConsumoTotal() * 24 / consumoData.length) * tarifaActual;
    } else if (_selectedPeriod == 'Semana') {
      // Para semana, estimamos el costo por día
      return (getConsumoTotal() / 7) * tarifaActual;
    } else {
      // Para mes, estimamos el costo por día
      return (getConsumoTotal() / 30) * tarifaActual;
    }
  }

  double getCostoMensualEstimado() {
    if (_selectedPeriod == 'Día') {
      // Proyectar consumo de un día a un mes
      return (getConsumoTotal() * 30) * tarifaActual;
    } else if (_selectedPeriod == 'Semana') {
      // Proyectar consumo de una semana a un mes
      return (getConsumoTotal() * 4.3) *
          tarifaActual; // 4.3 semanas promedio en un mes
    } else {
      // Ya estamos viendo datos mensuales
      return getConsumoTotal() * tarifaActual;
    }
  }

  // Verificar si la hora del día está en horas de mayor consumo (para destacar)
  bool esHoraPico() {
    final hora = DateTime.now().hour;
    return (hora >= 7 && hora <= 9) || (hora >= 18 && hora <= 22);
  }

  // Obtener etiqueta de eficiencia basada en el consumo
  String getEtiquetaEficiencia() {
    final consumoDiario =
        _selectedPeriod == 'Día'
            ? getConsumoTotal()
            : getConsumoTotal() / (_selectedPeriod == 'Semana' ? 7 : 30);

    if (consumoDiario < 5) {
      return 'EXCELENTE';
    } else if (consumoDiario < 8) {
      return 'BUENO';
    } else if (consumoDiario < 12) {
      return 'NORMAL';
    } else {
      return 'ALTO';
    }
  }

  // Obtener color para la etiqueta de eficiencia
  int getColorEficiencia() {
    final etiqueta = getEtiquetaEficiencia();
    switch (etiqueta) {
      case 'EXCELENTE':
        return 0xFF4CAF50; // Verde
      case 'BUENO':
        return 0xFF8BC34A; // Lima
      case 'NORMAL':
        return 0xFFFFC107; // Ámbar
      case 'ALTO':
        return 0xFFF44336; // Rojo
      default:
        return 0xFF2196F3; // Azul
    }
  }
}
