import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as Math;

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

  // Variable para controlar el período seleccionado
  String _selectedPeriod = 'Día';

  // Tiempo de actualización
  DateTime _ultimaActualizacion = DateTime.now();

  // Cache de consultas a Firestore
  Map<String, List<ConsumoData>> _cacheData = {};
  Map<String, DateTime> _cacheFechas = {};

  // Tarifas por estrato (en pesos colombianos por kWh)
  final Map<int, double> _tarifasPorEstrato = {
    1: 349.8,
    2: 437.3,
    3: 737.6,
    4: 867.8,
    5: 1040.0,
    6: 1040.0,
  };

  // Estrato actual
  int _userEstrato = 1;

  // Getters
  List<ConsumoData> get consumoData => _consumoData;
  DateTime get ultimaActualizacion => _ultimaActualizacion;
  String get selectedPeriod => _selectedPeriod;
  double get tarifaActual =>
      _tarifasPorEstrato[_userEstrato] ?? _tarifasPorEstrato[1]!;

  // Setter para el período seleccionado
  set selectedPeriod(String value) {
    _selectedPeriod = value;
  }

  // Setter para el estrato
  set userEstrato(int value) {
    if (value >= 1 && value <= 6) {
      _userEstrato = value;
    }
  }

  // Función para cargar datos desde Firestore con optimización de caché
  Future<void> cargarDatosHistoricos(String period) async {
    try {
      // Actualizar el período seleccionado
      _selectedPeriod = period;

      if (deviceId == null) {
        throw Exception("ID de dispositivo no disponible");
      }

      // Clave de caché: deviceId + periodo
      final cacheKey = "${deviceId!}_$period";

      // Verificar si tenemos datos en caché y son recientes (menos de 30 minutos)
      if (_cacheData.containsKey(cacheKey) &&
          _cacheFechas.containsKey(cacheKey) &&
          DateTime.now().difference(_cacheFechas[cacheKey]!).inMinutes < 30) {
        _consumoData = _cacheData[cacheKey]!;
        return;
      }

      // Calcular la fecha límite según el período seleccionado
      DateTime fechaLimite;
      final ahora = DateTime.now();

      switch (period) {
        case 'Día':
          // Para un día, tomar 24 horas exactas
          fechaLimite = DateTime(
            ahora.year,
            ahora.month,
            ahora.day,
            ahora.hour,
            ahora.minute,
          ).subtract(const Duration(hours: 24));
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
            ahora.hour,
            ahora.minute,
          ).subtract(const Duration(hours: 24));
      }

      // Para vista de día, aumentamos el límite a 100 para tener más detalle
      int queryLimit = period == 'Día' ? 100 : 50;

      // Consultar Firestore para obtener el historial de consumo con límite
      final snapshot =
          await FirebaseFirestore.instance
              .collection('dispositivos_historial')
              .where('deviceId', isEqualTo: deviceId)
              .where(
                'fecha',
                isGreaterThanOrEqualTo: Timestamp.fromDate(fechaLimite),
              )
              .orderBy('fecha', descending: false)
              .limit(queryLimit)
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

          // Generar datos históricos coherentes basados en el último consumo conocido
          datosCrudos.addAll(
            _generarDatosCoherentes(fechaLimite, ahora, period, consumoActual),
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

      // Para la vista diaria, realizar menos agrupación para mantener más detalle
      if (period == 'Día') {
        // Agrupar datos en intervalos más cortos para día (1 hora)
        _consumoData = _agruparDatosDiarios(datosCrudos);
      } else {
        // Agrupar datos para semana/mes como antes
        _consumoData = _agruparDatos(datosCrudos, period);
      }

      _ultimaActualizacion = DateTime.now();

      // Guardar en caché
      _cacheData[cacheKey] = List.from(_consumoData);
      _cacheFechas[cacheKey] = _ultimaActualizacion;
    } catch (e) {
      print("Error al cargar datos históricos: $e");
      _consumoData = _generarDatosEjemplo(
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now(),
        period,
      );
    }
  }

  // Limpiar caché para forzar recarga
  void limpiarCache() {
    _cacheData.clear();
    _cacheFechas.clear();
  }

  // Método para determinar si el usuario es nuevo (pocos datos reales)
  bool esUsuarioNuevo() {
    // Criterios para considerar a un usuario nuevo:
    // 1. Pocos puntos de datos
    // 2. Historial muy corto (menos de 48 horas entre primer y último punto)

    if (_consumoData.length < 5) return true;

    if (_consumoData.length >= 2) {
      DateTime primerFecha = _consumoData.first.fecha;
      DateTime ultimaFecha = _consumoData.last.fecha;
      Duration duracion = ultimaFecha.difference(primerFecha);

      return duracion.inHours < 48;
    }

    return true;
  }

  // Método para filtrar solo datos que parecen ser reales (no generados)
  List<ConsumoData> _filtrarDatosReales() {
    // Criterio simple: considerar solo los últimos N puntos (siendo más probable que sean reales)
    int puntosReales = Math.min(3, _consumoData.length);
    return _consumoData.sublist(_consumoData.length - puntosReales);
  }

  // Nuevo método específico para agrupar datos diarios con más detalle
  List<ConsumoData> _agruparDatosDiarios(List<ConsumoData> datos) {
    if (datos.isEmpty) return [];

    // Para datos diarios, intentamos mantener una resolución de 1 hora
    final Duration intervalo = const Duration(hours: 1);

    Map<DateTime, List<double>> gruposDatos = {};

    // Agrupar datos por intervalos de 1 hora
    for (var dato in datos) {
      DateTime fecha = dato.fecha;
      // Normalizar la fecha al inicio de la hora
      DateTime inicioIntervalo = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        fecha.hour,
      );

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

    // Rellenar horas faltantes para tener las 24 horas completas
    if (resultado.isNotEmpty) {
      // Determinar el día de inicio (usando el primer punto)
      final diaInicio = DateTime(
        resultado.first.fecha.year,
        resultado.first.fecha.month,
        resultado.first.fecha.day,
      );

      // Crear un mapa con las horas existentes para rápida verificación
      final horasExistentes = Map.fromIterable(
        resultado,
        key: (dato) => dato.fecha.hour,
        value: (dato) => true,
      );

      // Lista para los puntos interpolados
      final puntosInterpolados = <ConsumoData>[];

      // Iterar por las 24 horas del día
      for (int hora = 0; hora < 24; hora++) {
        // Si no tenemos datos para esta hora, interpolar
        if (!horasExistentes.containsKey(hora)) {
          final fechaHora = DateTime(
            diaInicio.year,
            diaInicio.month,
            diaInicio.day,
            hora,
          );

          // Insertar punto interpolado
          puntosInterpolados.add(
            ConsumoData(
              fecha: fechaHora,
              consumo: _interpolarConsumo(resultado, fechaHora),
            ),
          );
        }
      }

      // Añadir puntos interpolados
      resultado.addAll(puntosInterpolados);

      // Reordenar después de añadir puntos
      resultado.sort((a, b) => a.fecha.compareTo(b.fecha));
    }

    return resultado;
  }

  // Método para interpolar consumo entre puntos existentes
  double _interpolarConsumo(List<ConsumoData> datos, DateTime fecha) {
    // Encontrar los puntos anterior y siguiente más cercanos
    ConsumoData? anterior;
    ConsumoData? siguiente;

    for (var dato in datos) {
      if (dato.fecha.isBefore(fecha) &&
          (anterior == null || dato.fecha.isAfter(anterior.fecha))) {
        anterior = dato;
      }
      if (dato.fecha.isAfter(fecha) &&
          (siguiente == null || dato.fecha.isBefore(siguiente.fecha))) {
        siguiente = dato;
      }
    }

    // Si no tenemos ambos puntos, usar el promedio general
    if (anterior == null || siguiente == null) {
      return datos.map((e) => e.consumo).reduce((a, b) => a + b) / datos.length;
    }

    // Calcular interpolación lineal
    final totalDuration =
        siguiente.fecha.difference(anterior.fecha).inMilliseconds;
    final currentPosition = fecha.difference(anterior.fecha).inMilliseconds;
    final ratio = totalDuration > 0 ? currentPosition / totalDuration : 0.5;

    return anterior.consumo + (siguiente.consumo - anterior.consumo) * ratio;
  }

  // Función para agrupar datos (para semana/mes)
  List<ConsumoData> _agruparDatos(List<ConsumoData> datos, String period) {
    if (datos.isEmpty) return [];

    // Decidir el intervalo de agrupación según el período
    Duration intervalo;
    switch (period) {
      case 'Día':
        intervalo = const Duration(hours: 2); // Agrupar cada 2 horas
        break;
      case 'Semana':
        intervalo = const Duration(
          hours: 6,
        ); // Agrupar cada 6 horas para permitir 4 puntos por día
        break;
      case 'Mes':
        intervalo = const Duration(days: 1); // Agrupar por día
        break;
      default:
        intervalo = const Duration(hours: 2);
    }

    // Establecer un número máximo de puntos deseados
    int maxPuntos =
        period == 'Semana' ? 28 : 12; // Permitir más puntos en vista semanal

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

    // Para vista semanal, asegurarnos de tener un punto representativo por día
    if (period == 'Semana') {
      // Agrupar por día de la semana para asegurar un punto representativo por día
      Map<int, List<ConsumoData>> datosPorDia = {};

      for (var dato in resultado) {
        int diaSemana = dato.fecha.weekday; // 1-7 (lunes-domingo)
        if (!datosPorDia.containsKey(diaSemana)) {
          datosPorDia[diaSemana] = [];
        }
        datosPorDia[diaSemana]!.add(dato);
      }

      // Crear un nuevo resultado con exactamente un punto por día
      List<ConsumoData> resultadoFinal = [];

      // Para cada día de la semana (1-7)
      for (int dia = 1; dia <= 7; dia++) {
        if (datosPorDia.containsKey(dia) && datosPorDia[dia]!.isNotEmpty) {
          // Si tenemos datos para este día, usar el más representativo (promedio)
          List<ConsumoData> datosDia = datosPorDia[dia]!;
          double consumoPromedio =
              datosDia.map((d) => d.consumo).reduce((a, b) => a + b) /
              datosDia.length;

          // Usar la fecha del punto central del día
          DateTime fechaRepresentativa = datosDia[datosDia.length ~/ 2].fecha;

          resultadoFinal.add(
            ConsumoData(fecha: fechaRepresentativa, consumo: consumoPromedio),
          );
        } else {
          // Si no tenemos datos para este día, intentar interpolar
          // Buscar un día cercano para crear una fecha con el mismo día de la semana
          DateTime? fechaReferencia;

          // Usar el primer día que tengamos como referencia
          if (resultado.isNotEmpty) {
            fechaReferencia = resultado.first.fecha;

            // Ajustar a la fecha con el día de la semana correcto
            int diferenciaDias = dia - fechaReferencia.weekday;
            if (diferenciaDias < 0) diferenciaDias += 7;
            fechaReferencia = fechaReferencia.add(
              Duration(days: diferenciaDias),
            );

            // Interpolar consumo basado en el promedio
            double consumoPromedio = 0.0;
            if (datosPorDia.isNotEmpty) {
              // Calcular promedio de todos los días disponibles
              int totalPuntos = 0;
              double sumaConsumos = 0.0;

              datosPorDia.forEach((_, puntos) {
                for (var punto in puntos) {
                  sumaConsumos += punto.consumo;
                  totalPuntos++;
                }
              });

              if (totalPuntos > 0) {
                consumoPromedio = sumaConsumos / totalPuntos;
              }
            } else if (resultado.isNotEmpty) {
              // Si no tenemos ningún día, usar el promedio general
              consumoPromedio =
                  resultado.map((d) => d.consumo).reduce((a, b) => a + b) /
                  resultado.length;
            }

            resultadoFinal.add(
              ConsumoData(fecha: fechaReferencia, consumo: consumoPromedio),
            );
          }
        }
      }

      // Si tenemos al menos un día, ordenar el resultado final
      if (resultadoFinal.isNotEmpty) {
        resultadoFinal.sort((a, b) => a.fecha.compareTo(b.fecha));
        return resultadoFinal;
      }
    }

    return resultado;
  }

  // Generar datos coherentes basados en el último consumo conocido
  List<ConsumoData> _generarDatosCoherentes(
    DateTime inicio,
    DateTime fin,
    String period,
    double consumoActual,
  ) {
    List<ConsumoData> datos = [];
    DateTime fecha = inicio;

    // Usar el consumo actual como base, con ligeras variaciones
    double baseConsumo =
        consumoActual * 0.8; // Base ligeramente inferior al consumo actual

    while (fecha.isBefore(fin)) {
      // Pequeña variación aleatoria pero determinista (basada en la hora/día)
      double factorHora = 1.0;
      int hora = fecha.hour;

      // Patrones de consumo típicos por hora del día
      if (hora >= 8 && hora <= 10)
        factorHora = 1.2; // Más consumo por la mañana
      else if (hora >= 19 && hora <= 22)
        factorHora = 1.3; // Más consumo por la noche
      else if (hora >= 0 && hora <= 5)
        factorHora = 0.7; // Menos consumo durante la madrugada

      // Variación suave para evitar cambios bruscos
      double factorRandom =
          0.9 + (0.2 * ((Math.sin(fecha.hour * 0.5) + 1) / 2));
      double consumo = baseConsumo * factorHora * factorRandom;

      // Redondear a 5 decimales para consistencia
      consumo = double.parse(consumo.toStringAsFixed(5));

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

  // Función para generar datos de ejemplo (solo para visualización inicial)
  // Esta versión genera datos más uniformes entre períodos
  List<ConsumoData> _generarDatosEjemplo(
    DateTime inicio,
    DateTime fin,
    String period,
  ) {
    List<ConsumoData> datos = [];
    DateTime fecha = inicio;

    // Valor constante base para todos los períodos para mayor consistencia
    double baseConsumo = 1.0;

    while (fecha.isBefore(fin)) {
      // Variación suave determinista basada en la hora
      double variacion = 0.3 * ((Math.sin(fecha.hour * 0.5) + 1) / 2);
      double consumo = baseConsumo + variacion;

      // Redondear a 5 decimales para consistencia
      consumo = double.parse(consumo.toStringAsFixed(5));

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
  // Con ajustes para usuarios nuevos para mayor consistencia entre vistas
  double getConsumoTotal() {
    if (_consumoData.isEmpty) return 0;

    // Enfoque especial para usuario nuevo
    if (esUsuarioNuevo()) {
      // Usar solo el último valor conocido (más probable que sea real)
      double consumoActual = _consumoData.last.consumo;

      if (_selectedPeriod == 'Día') {
        // Para día: consumo actual × 24 horas
        return consumoActual * 24;
      } else if (_selectedPeriod == 'Semana') {
        // Para semana: consumo actual × 24 horas × 7 días
        return consumoActual * 24 * 7;
      } else {
        // Para mes: consumo actual × 24 horas × 30 días
        return consumoActual * 24 * 30;
      }
    }

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

  // Costo diario estimado
  double getCostoDiarioEstimado() {
    if (esUsuarioNuevo()) {
      // Para usuario nuevo, usar solo el consumo actual multiplicado por 24 horas
      final consumoActual =
          _consumoData.isNotEmpty ? _consumoData.last.consumo : 0.0;
      return (consumoActual * 24) * tarifaActual;
    }

    if (_selectedPeriod == 'Día') {
      // Si estamos viendo datos diarios, proyectamos a 24 horas
      return (getConsumoTotal() * 24 / _consumoData.length) * tarifaActual;
    } else if (_selectedPeriod == 'Semana') {
      // Para semana, estimamos el costo por día
      return (getConsumoTotal() / 7) * tarifaActual;
    } else {
      // Para mes, estimamos el costo por día
      return (getConsumoTotal() / 30) * tarifaActual;
    }
  }

  // Costo mensual estimado
  double getCostoMensualEstimado() {
    if (esUsuarioNuevo()) {
      // Para usuario nuevo, proyectar conservadoramente desde el último consumo conocido
      final consumoActual =
          _consumoData.isNotEmpty ? _consumoData.last.consumo : 0.0;
      return (consumoActual * 24 * 30) *
          tarifaActual; // Consumo actual × 24 horas × 30 días
    }

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

  // Comprobar si es necesario actualizar los datos
  bool necesitaActualizacion(Duration maxTimeWithoutUpdate) {
    return DateTime.now().difference(_ultimaActualizacion) >
        maxTimeWithoutUpdate;
  }
}
