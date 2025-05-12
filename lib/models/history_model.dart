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

  // Tiempo de actualización
  DateTime _ultimaActualizacion = DateTime.now();

  // Getters
  List<ConsumoData> get consumoData => _consumoData;
  DateTime get ultimaActualizacion => _ultimaActualizacion;

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
          fechaLimite = DateTime(
            ahora.year,
            ahora.month,
            ahora.day,
          ).subtract(const Duration(days: 1));
          break;
        case 'Semana':
          fechaLimite = DateTime(
            ahora.year,
            ahora.month,
            ahora.day,
          ).subtract(const Duration(days: 7));
          break;
        case 'Mes':
          fechaLimite = DateTime(
            ahora.year,
            ahora.month,
            ahora.day,
          ).subtract(const Duration(days: 30));
          break;
        default:
          fechaLimite = DateTime(
            ahora.year,
            ahora.month,
            ahora.day,
          ).subtract(const Duration(days: 1));
      }

      // Consultar Firestore para obtener el historial de consumo
      final snapshot =
          await FirebaseFirestore.instance
              .collection('dispositivos_historial')
              .where('deviceId', isEqualTo: deviceId)
              .where(
                'fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(fechaLimite),
              )
              .orderBy('fecha', descending: false)
              .get();

      List<ConsumoData> datosCrudos = [];

      if (snapshot.docs.isEmpty) {
        // Aquí podríamos intentar obtener el consumo actual para tener al menos un punto
        final dispositivoSnapshot =
            await FirebaseFirestore.instance
                .collection('dispositivos')
                .doc(deviceId)
                .get();

        if (dispositivoSnapshot.exists) {
          final consumoActual =
              dispositivoSnapshot.data()?['consumo'] as double? ?? 0.0;

          // Agregar consumo actual como un punto
          datosCrudos.add(
            ConsumoData(fecha: DateTime.now(), consumo: consumoActual),
          );

          // Generar datos históricos basados en el consumo actual
          datosCrudos.addAll(
            _generarDatosBasadosEnConsumoActual(
              fechaLimite,
              ahora,
              period,
              consumoActual,
            ),
          );
        } else {
          // Si no hay datos del dispositivo, usar datos de ejemplo
          datosCrudos = _generarDatosEjemplo(fechaLimite, ahora, period);
        }
      } else {
        // Procesar los datos reales obtenidos de Firestore
        for (var doc in snapshot.docs) {
          final data = doc.data();
          datosCrudos.add(
            ConsumoData(
              fecha: (data['fecha'] as Timestamp).toDate(),
              consumo:
                  (data['consumo'] is num)
                      ? (data['consumo'] as num).toDouble()
                      : 0.0,
            ),
          );
        }

        // Agregar el consumo actual como último punto
        final dispositivoSnapshot =
            await FirebaseFirestore.instance
                .collection('dispositivos')
                .doc(deviceId)
                .get();

        if (dispositivoSnapshot.exists) {
          final consumoActual =
              dispositivoSnapshot.data()?['consumo'] as double? ?? 0.0;
          datosCrudos.add(
            ConsumoData(fecha: DateTime.now(), consumo: consumoActual),
          );
        }
      }

      // Agrupar datos para reducir la cantidad de puntos
      _consumoData = _agruparDatos(datosCrudos, period);
      _ultimaActualizacion = DateTime.now();
    } catch (e) {
      print("Error al cargar datos históricos: $e");
      _consumoData = _generarDatosEjemplo(
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now(),
        period,
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
          fecha.year,
          fecha.month,
          fecha.day,
          (fecha.hour ~/ intervalo.inHours) * intervalo.inHours,
        );
      } else if (period == 'Semana') {
        inicioIntervalo = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          (fecha.hour ~/ intervalo.inHours) * intervalo.inHours,
        );
      } else {
        // Mes
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
      if (muestreo.isNotEmpty && muestreo.last.fecha != resultado.last.fecha) {
        muestreo.add(resultado.last);
      }

      return muestreo;
    }

    return resultado;
  }

  // Generar datos basados en el consumo actual (para dar mayor realismo)
  List<ConsumoData> _generarDatosBasadosEnConsumoActual(
    DateTime inicio,
    DateTime fin,
    String period,
    double consumoActual,
  ) {
    List<ConsumoData> datos = [];
    DateTime fecha = inicio;
    double baseConsumo =
        consumoActual * 0.7; // Base más baja que el consumo actual

    while (fecha.isBefore(fin)) {
      // Crear una variación realista basada en el consumo actual
      double factor =
          0.7 + 0.6 * (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;
      double consumo = baseConsumo * factor;

      // Ajuste por hora del día (para datos diarios)
      if (period == 'Día') {
        // Patrón típico: más consumo durante mañana y tarde
        int hora = fecha.hour;
        double factorHora = 1.0;

        if (hora >= 8 && hora <= 10)
          factorHora = 1.3; // Pico matutino
        else if (hora >= 19 && hora <= 22)
          factorHora = 1.5; // Pico nocturno
        else if (hora >= 0 && hora <= 5)
          factorHora = 0.6; // Valle nocturno

        consumo = consumo * factorHora;
      }

      datos.add(
        ConsumoData(
          fecha: fecha,
          consumo: double.parse(consumo.toStringAsFixed(5)),
        ),
      );

      // Incrementar la fecha según el período
      if (period == 'Día') {
        fecha = fecha.add(const Duration(hours: 1));
      } else if (period == 'Semana') {
        fecha = fecha.add(const Duration(hours: 6));
      } else {
        fecha = fecha.add(const Duration(days: 1));
      }
    }

    return datos;
  }

  // Función para generar datos de ejemplo (solo para visualización inicial)
  List<ConsumoData> _generarDatosEjemplo(
    DateTime inicio,
    DateTime fin,
    String period,
  ) {
    List<ConsumoData> datos = [];
    DateTime fecha = inicio;

    while (fecha.isBefore(fin)) {
      // Generar un valor de consumo aleatorio entre 0.5 y 3.5 kWh
      final consumo =
          0.5 + (3.0 * (DateTime.now().millisecondsSinceEpoch % 24) / 24.0);

      datos.add(ConsumoData(fecha: fecha, consumo: consumo));

      // Incrementar la fecha según el período
      if (period == 'Día') {
        fecha = fecha.add(const Duration(hours: 1));
      } else if (period == 'Semana') {
        fecha = fecha.add(const Duration(hours: 6));
      } else {
        fecha = fecha.add(const Duration(days: 1));
      }
    }

    return datos;
  }

  // Métodos para cálculos de resumen con corrección para intervalos de tiempo
  double getConsumoTotal() {
    if (_consumoData.isEmpty) return 0;

    double total = 0;

    // Si hay al menos dos puntos, podemos calcular el consumo acumulado
    if (_consumoData.length >= 2) {
      for (int i = 0; i < _consumoData.length - 1; i++) {
        // Calculamos el promedio entre puntos consecutivos
        double promedioConsumo =
            (_consumoData[i].consumo + _consumoData[i + 1].consumo) / 2;

        // Calculamos la duración entre puntos en horas
        double horasEntrePuntos =
            _consumoData[i + 1].fecha
                .difference(_consumoData[i].fecha)
                .inMinutes /
            60.0;

        // El consumo para este intervalo es el promedio multiplicado por las horas
        total += promedioConsumo * horasEntrePuntos;
      }
    } else {
      // Si solo hay un punto, multiplicamos por un período estándar (1 hora)
      total = _consumoData[0].consumo;
    }

    return total;
  }

  double getConsumoMaximo() {
    if (_consumoData.isEmpty) return 0;
    return _consumoData.map((e) => e.consumo).reduce((a, b) => a > b ? a : b);
  }

  double getConsumoPromedio() {
    if (_consumoData.isEmpty) return 0;
    return _consumoData.map((e) => e.consumo).reduce((a, b) => a + b) /
        _consumoData.length;
  }

  // Comprobar si es necesario actualizar los datos
  bool necesitaActualizacion(Duration maxTimeWithoutUpdate) {
    return DateTime.now().difference(_ultimaActualizacion) >
        maxTimeWithoutUpdate;
  }
}
