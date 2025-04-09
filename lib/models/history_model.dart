// Modelo: history_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumoData {
  final DateTime fecha;
  final double consumo;

  ConsumoData({required this.fecha, required this.consumo});
}

class HistoryModel {
  // Datos de consumo
  List<ConsumoData> _consumoData = [];
  String? deviceId;
  bool isLoading = true;

  // Getters
  List<ConsumoData> get consumoData => _consumoData;
  
  // Función para cargar datos desde Firestore
  Future<void> cargarDatosHistoricos(String period) async {
    try {
      if (deviceId == null) {
        throw Exception("ID de dispositivo no disponible");
      }
      
      // Calcular la fecha límite según el período seleccionado
      DateTime fechaLimite;
      final ahora = DateTime.now();
      
      switch (period) {
        case 'Día':
          fechaLimite = DateTime(ahora.year, ahora.month, ahora.day).subtract(const Duration(days: 1));
          break;
        case 'Semana':
          fechaLimite = DateTime(ahora.year, ahora.month, ahora.day).subtract(const Duration(days: 7));
          break;
        case 'Mes':
          fechaLimite = DateTime(ahora.year, ahora.month, ahora.day).subtract(const Duration(days: 30));
          break;
        default:
          fechaLimite = DateTime(ahora.year, ahora.month, ahora.day).subtract(const Duration(days: 1));
      }
      
      // Consultar Firestore para obtener el historial de consumo
      final snapshot = await FirebaseFirestore.instance
          .collection('dispositivos_historial')
          .where('deviceId', isEqualTo: deviceId)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaLimite))
          .orderBy('fecha', descending: false)
          .get();
      
      List<ConsumoData> datosCrudos = [];
      
      if (snapshot.docs.isEmpty) {
        datosCrudos = _generarDatosEjemplo(fechaLimite, ahora, period);
      } else {
        for (var doc in snapshot.docs) {
          final data = doc.data();
          datosCrudos.add(ConsumoData(
            fecha: (data['fecha'] as Timestamp).toDate(),
            consumo: data['consumo'] ?? 0.0,
          ));
        }
      }
      
      // Agrupar datos para reducir la cantidad de puntos
      _consumoData = _agruparDatos(datosCrudos, period);
      
    } catch (e) {
      print("Error al cargar datos históricos: $e");
      _consumoData = _generarDatosEjemplo(
        DateTime.now().subtract(const Duration(days: 30)), 
        DateTime.now(),
        period
      );
    }
  }
  
  // Función para agrupar datos
  List<ConsumoData> _agruparDatos(List<ConsumoData> datos, String period) {
    if (datos.isEmpty) return [];
    
    // Decidir el intervalo de agrupación según el período
    Duration intervalo;
    switch (period) {
      case 'Día':
        intervalo = const Duration(hours: 2); // Agrupar cada 2 horas
        break;
      case 'Semana':
        intervalo = const Duration(hours: 12); // Agrupar cada 12 horas
        break;
      case 'Mes':
        intervalo = const Duration(days: 1); // Agrupar por día
        break;
      default:
        intervalo = const Duration(hours: 2);
    }
    
    // Establecer un número máximo de puntos deseados
    int maxPuntos = 12;
    
    // Si tenemos pocos datos, no es necesario agrupar
    if (datos.length <= maxPuntos) return datos;
    
    Map<DateTime, List<double>> gruposDatos = {};
    
    // Agrupar datos por intervalos
    for (var dato in datos) {
      DateTime fecha = dato.fecha;
      // Normalizar la fecha al inicio del intervalo
      DateTime inicioIntervalo;
      
      if (period == 'Día') {
        inicioIntervalo = DateTime(
          fecha.year, fecha.month, fecha.day, 
          (fecha.hour ~/ intervalo.inHours) * intervalo.inHours
        );
      } else if (period == 'Semana') {
        inicioIntervalo = DateTime(
          fecha.year, fecha.month, fecha.day, 
          (fecha.hour ~/ intervalo.inHours) * intervalo.inHours
        );
      } else { // Mes
        inicioIntervalo = DateTime(fecha.year, fecha.month, fecha.day);
      }
      
      if (!gruposDatos.containsKey(inicioIntervalo)) {
        gruposDatos[inicioIntervalo] = [];
      }
      gruposDatos[inicioIntervalo]!.add(dato.consumo);
    }
    
    // Calcular promedio para cada grupo
    List<ConsumoData> resultado = [];
    gruposDatos.forEach((fecha, valores) {
      double consumoPromedio = valores.reduce((a, b) => a + b) / valores.length;
      resultado.add(ConsumoData(fecha: fecha, consumo: consumoPromedio));
    });
    
    // Ordenar por fecha
    resultado.sort((a, b) => a.fecha.compareTo(b.fecha));
    
    // Si aún tenemos demasiados puntos, hacer un muestreo
    if (resultado.length > maxPuntos) {
      int paso = (resultado.length / maxPuntos).ceil();
      List<ConsumoData> muestreo = [];
      
      for (int i = 0; i < resultado.length; i += paso) {
        if (i < resultado.length) {
          muestreo.add(resultado[i]);
        }
      }
      
      // Asegurarnos de incluir el último punto
      if (muestreo.isNotEmpty && 
          muestreo.last.fecha != resultado.last.fecha) {
        muestreo.add(resultado.last);
      }
      
      return muestreo;
    }
    
    return resultado;
  }
  
  // Función para generar datos de ejemplo (solo para visualización inicial)
  List<ConsumoData> _generarDatosEjemplo(DateTime inicio, DateTime fin, String period) {
    List<ConsumoData> datos = [];
    DateTime fecha = inicio;
    
    while (fecha.isBefore(fin)) {
      // Generar un valor de consumo aleatorio entre 0.5 y 3.5 kWh
      final consumo = 0.5 + (3.0 * (DateTime.now().hour % 24) / 24.0);
      
      datos.add(ConsumoData(fecha: fecha, consumo: consumo));
      
      // Incrementar la fecha según el período
      if (period == 'Día') {
        fecha = fecha.add(const Duration(hours: 1));
      } else {
        fecha = fecha.add(const Duration(days: 1));
      }
    }
    
    return datos;
  }
  
  // Métodos para cálculos de resumen
  double getConsumoTotal() {
    double total = 0;
    for (var dato in _consumoData) {
      total += dato.consumo;
    }
    return total;
  }
  
  double getConsumoMaximo() {
    if (_consumoData.isEmpty) return 0;
    return _consumoData.map((e) => e.consumo).reduce((a, b) => a > b ? a : b);
  }
  
  double getConsumoPromedio() {
    if (_consumoData.isEmpty) return 0;
    return getConsumoTotal() / _consumoData.length;
  }
}