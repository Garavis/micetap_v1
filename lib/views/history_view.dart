import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:micetap_v1/controllers/history_controller.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';
import 'dart:math' as Math;

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final HistoryController _controller = HistoryController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Al inicializar, configurar para recibir actualizaciones automáticas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.iniciarAutoActualizacion();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obtener el ID del dispositivo de los argumentos
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _controller.setDeviceId(args);
      _cargarDatos();
    }
  }

  @override
  void dispose() {
    // Limpiar recursos al cerrar la vista
    _controller.dispose();
    super.dispose();
  }

  // Método para cargar datos y actualizar la UI
  Future<void> _cargarDatos() async {
    if (!mounted) return;

    setState(() {
      _controller.isLoading = true;
    });

    await _controller.cargarDatos();

    if (!mounted) return;

    setState(() {
      _controller.isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('Historial de Consumo'),
      body: SafeArea(
        child:
            _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del dispositivo
                        if (_controller.deviceId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dispositivo: ${_controller.deviceId}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Botón de actualización manual
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.blue,
                                  ),
                                  onPressed:
                                      _controller.isLoading
                                          ? null
                                          : _cargarDatos,
                                  tooltip: 'Actualizar datos',
                                ),
                              ],
                            ),
                          ),

                        // Filtro de período
                        Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Período de análisis',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text(
                                    'Seleccionar:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<String>(
                                        value: _controller.selectedPeriod,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        onChanged: (String? newValue) async {
                                          if (newValue != null) {
                                            await _controller.cambiarPeriodo(
                                              newValue,
                                            );
                                            if (mounted) setState(() {});
                                          }
                                        },
                                        items:
                                            _controller.periodOptions.map((
                                              String value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Información de estrato
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Estrato ${_controller.userEstrato}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tarifa: ${_currencyFormat.format(_controller.tarifaActual)}/kWh',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Gráfico de consumo
                        _controller.consumoData.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.bar_chart_sharp,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No hay datos disponibles para el período seleccionado',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : Container(
                              height: 300,
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _buildConsumoChart(),
                            ),

                        // Resumen de consumo
                        if (!_controller.isLoading &&
                            _controller.consumoData.isNotEmpty)
                          _buildConsumoSummary(),

                        // Espacio para el botón flotante
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
      ),
      floatingActionButton: const FloatingBackButton(route: '/home'),
    );
  }

  Widget _buildConsumoChart() {
    // Si no hay datos suficientes, mostrar mensaje
    if (_controller.consumoData.isEmpty || _controller.consumoData.length < 2) {
      return const Center(
        child: Text(
          "No hay suficientes datos para generar la gráfica",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Calcular valores mínimos y máximos para mejorar la escala
    double minY = double.infinity;
    double maxY = 0;

    for (var dato in _controller.consumoData) {
      if (dato.consumo < minY) {
        minY = dato.consumo;
      }
      if (dato.consumo > maxY) {
        maxY = dato.consumo;
      }
    }

    // Calcular el promedio para centrar el gráfico
    double avgConsumo = _controller.getConsumoPromedio();

    // Hacer que las variaciones se vean más dramáticas, pero con límite superior de 5.0
    double maxRange = 5.0; // Máximo valor para el eje Y
    double minRange = 0.0; // Mínimo valor para el eje Y

    // Calcular el rango basado en los datos pero respetando los límites
    double targetRange;

    if (maxY > minY) {
      // Conservar algo de la dinámica de exageración para visualizar mejor las diferencias
      double actualRange = maxY - minY;
      double exaggeratedRange =
          actualRange * (_controller.selectedPeriod == 'Día' ? 3.0 : 2.0);

      // Asegurar que estamos dentro del rango deseado
      targetRange = Math.min(exaggeratedRange, maxRange - minRange);

      // Centrar alrededor del promedio, pero respetar los límites
      double halfRange = targetRange / 2;
      minY = Math.max(
        minRange,
        Math.min(avgConsumo - halfRange, maxRange - targetRange),
      );
      maxY = Math.min(maxRange, minY + targetRange);
    } else {
      // Si solo hay un valor o todos son iguales
      minY = minRange;
      maxY = maxRange;
    }

    // Ajustar el cálculo del intervalo Y para que sea apropiado para el rango 0-5
    double yInterval;
    double range = maxY - minY;

    if (range <= 1.0) {
      yInterval = 0.2;
    } else if (range <= 2.0) {
      yInterval = 0.5;
    } else if (range <= 5.0) {
      yInterval = 1.0;
    } else {
      yInterval =
          1.0; // Por seguridad, aunque deberíamos estar siempre en el rango 0-5
    }

    // Calcular intervalo horizontal para que se muestren menos etiquetas en la vista diaria
    double hInterval = 1.0;
    if (_controller.selectedPeriod == 'Día') {
      // Para vista diaria, mostrar menos puntos en el eje X
      hInterval = _controller.consumoData.length > 18 ? 3.0 : 2.0;
    } else if (_controller.selectedPeriod == 'Semana') {
      // Para vista semanal, usar intervalo de 1 para mostrar todos los días
      hInterval = 1.0;
    } else {
      // Mes
      hInterval = _controller.consumoData.length > 20 ? 4.0 : 2.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 0.8,
                dashArray: [5, 5],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 0.8,
              );
            },
            horizontalInterval: yInterval,
            verticalInterval: hInterval,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval:
                    _controller.selectedPeriod == 'Semana'
                        ? 1.0
                        : hInterval, // Mostrar cada día en vista semanal
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < _controller.consumoData.length) {
                    final fecha = _controller.consumoData[value.toInt()].fecha;

                    // Determinar si esta etiqueta debe mostrarse
                    bool showLabel = true;
                    if (_controller.selectedPeriod == 'Día') {
                      // En vista diaria, mostrar solo etiquetas en horas específicas
                      showLabel = fecha.hour % 3 == 0; // Cada 3 horas
                    } else if (_controller.selectedPeriod == 'Semana') {
                      // En vista semanal, asegurarse de mostrar un punto por día
                      if (value > 0 &&
                          value < _controller.consumoData.length - 1) {
                        final prevFecha =
                            _controller.consumoData[value.toInt() - 1].fecha;
                        // Solo mostrar si cambia el día de la semana
                        showLabel = prevFecha.weekday != fecha.weekday;
                      } else {
                        // Primera y última etiqueta siempre se muestran
                        showLabel = true;
                      }
                    }

                    if (!showLabel && _controller.selectedPeriod != 'Semana') {
                      return const SizedBox.shrink(); // No mostrar esta etiqueta excepto en vista semanal
                    }

                    // Formato de hora/día compacto
                    String labelText = _formatDate(fecha);

                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: SizedBox(
                        width: _controller.selectedPeriod == 'Semana' ? 30 : 25,
                        child: Text(
                          labelText,
                          style: TextStyle(
                            color: Color(0xff68737d),
                            fontWeight: FontWeight.bold,
                            fontSize:
                                _controller.selectedPeriod == 'Semana' ? 10 : 9,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${value.toStringAsFixed(1)} kWh',
                      style: const TextStyle(
                        color: Color(0xff67727d),
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: const Color(0xff37434d).withOpacity(0.6),
              width: 1,
            ),
          ),
          minX: 0,
          maxX: _controller.consumoData.length.toDouble() - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: _getFlSpots(),
              isCurved: true,
              curveSmoothness: 0.3,
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
              ),
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  Color dotColor;
                  double radius;

                  if (index == _controller.consumoData.length - 1) {
                    dotColor = Colors.red;
                    radius = 5;
                  } else if (index == 0) {
                    dotColor = Colors.green;
                    radius = 4;
                  } else {
                    // Colorear en función de si está por encima o debajo del promedio
                    final valor = _controller.consumoData[index].consumo;
                    if (valor > avgConsumo * 1.1) {
                      dotColor =
                          Colors.orange; // Más del 10% por encima del promedio
                      radius = 4;
                    } else if (valor < avgConsumo * 0.9) {
                      dotColor =
                          Colors
                              .lightBlue; // Más del 10% por debajo del promedio
                      radius = 4;
                    } else {
                      dotColor = Colors.blue;
                      radius = 3.5;
                    }
                  }

                  return FlDotCirclePainter(
                    radius: radius,
                    color: dotColor,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  if (index >= 0 && index < _controller.consumoData.length) {
                    final value = _controller.consumoData[index];
                    // Calcular costo para el tooltip
                    final costo = value.consumo * _controller.tarifaActual;
                    return LineTooltipItem(
                      '${DateFormat('dd/MM HH:mm').format(value.fecha)}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${value.consumo.toStringAsFixed(5)} kWh\n',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextSpan(
                          text: '${_currencyFormat.format(costo)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }
                  return null;
                }).toList();
              },
            ),
            touchSpotThreshold: 20,
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (
              LineChartBarData barData,
              List<int> spotIndexes,
            ) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.blue, strokeWidth: 2, dashArray: [3, 3]),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: Colors.blue,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              // Línea de promedio
              HorizontalLine(
                y: avgConsumo,
                color: Colors.green.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                  labelResolver: (line) => 'Promedio',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getChartInterval() {
    if (_controller.consumoData.length <= 12) {
      return 1;
    } else if (_controller.consumoData.length <= 24) {
      return 2;
    } else {
      return (_controller.consumoData.length / 6).ceil().toDouble();
    }
  }

  List<FlSpot> _getFlSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _controller.consumoData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _controller.consumoData[i].consumo));
    }
    return spots;
  }

  String _formatDate(DateTime fecha) {
    if (_controller.selectedPeriod == 'Día') {
      // Formato para hora del día: solo la hora (sin minutos, compacto)
      return '${fecha.hour}h'; // Ej: 9h, 15h, 21h
    } else if (_controller.selectedPeriod == 'Semana') {
      // Formato para semana: abreviatura del día (lunes a domingo)
      final weekdayNames = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
      return weekdayNames[fecha.weekday - 1];
    } else {
      // Formato para mes: día/mes (compacto)
      return '${fecha.day}/${fecha.month}';
    }
  }

  // Método para formatear valores grandes, añadiendo K para miles
  String _formatLargeValue(double value) {
    if (value > 1000) {
      return "${(value / 1000).toStringAsFixed(2)}K";
    } else {
      return value.toStringAsFixed(2);
    }
  }

  Widget _buildConsumoSummary() {
    final total = _controller.getConsumoTotal();
    final promedio = _controller.getConsumoPromedio();
    final maximo = _controller.getConsumoMaximo();
    final costoTotal = _controller.getCostoTotal();
    final esPico = _controller.esHoraPico();

    // Etiqueta de eficiencia
    final etiqueta = _controller.getEtiquetaEficiencia();
    final colorEtiqueta = Color(_controller.getColorEficiencia());
    if (_controller.esUsuarioNuevo()) {
      // Mostrar mensaje informativo sobre datos estimados
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Los valores mostrados son estimados porque aún no hay suficiente historial de consumo. La información será más precisa con el tiempo.",
                style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de eficiencia energética
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorEtiqueta.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorEtiqueta.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorEtiqueta,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      etiqueta,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Nivel de consumo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                etiqueta == 'EXCELENTE'
                    ? 'Tu consumo energético es muy eficiente. ¡Sigue así!'
                    : etiqueta == 'BUENO'
                    ? 'Buen trabajo manteniendo tu consumo bajo control.'
                    : etiqueta == 'NORMAL'
                    ? 'Tu consumo está dentro de lo esperado, pero podrías mejorarlo.'
                    : 'Tu consumo energético es alto. Considera reducirlo para ahorrar.',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
        ),

        if (esPico)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Estás en horario de alto consumo. Considera reducir el uso de electrodomésticos de alta potencia para optimizar tu consumo.",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

        // Sección de consumo - rediseñada para manejar valores grandes
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de Consumo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),

              // Utilizamos un enfoque más compacto para los valores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCompactSummaryItem(
                    'Total',
                    _formatLargeValue(total),
                    'kWh',
                    Colors.blue,
                    Icons.power,
                  ),
                  _buildCompactSummaryItem(
                    'Promedio',
                    promedio.toStringAsFixed(2),
                    'kWh',
                    Colors.green,
                    Icons.show_chart,
                  ),
                  _buildCompactSummaryItem(
                    'Máximo',
                    maximo.toStringAsFixed(2),
                    'kWh',
                    Colors.orange,
                    Icons.trending_up,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Sección de costos
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimación de Costos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              // Costo total del período
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Costo total (Estrato ${_controller.userEstrato}):',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    costoTotal > 1000000
                        ? '${_currencyFormat.format(costoTotal / 1000000)}M'
                        : _currencyFormat.format(costoTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Información adicional según el período
              if (_controller.selectedPeriod == 'Día')
                _buildInfoCard(
                  "Consumo diario estimado: ${(total * 24 / _controller.consumoData.length).toStringAsFixed(2)} kWh",
                  "Costo aproximado: ${_currencyFormat.format(_controller.getCostoDiarioEstimado())} por día.",
                )
              else if (_controller.selectedPeriod == 'Mes')
                _buildInfoCard(
                  "Costo mensual estimado: ${_currencyFormat.format(_controller.getCostoMensualEstimado())}",
                  "Basado en la tarifa de Estrato ${_controller.userEstrato}: ${_currencyFormat.format(_controller.tarifaActual)}/kWh.",
                )
              else // Semana
                _buildInfoCard(
                  "Consumo semanal: ${total.toStringAsFixed(2)} kWh",
                  "Costo mensual proyectado: ${_currencyFormat.format(_controller.getCostoMensualEstimado())}",
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // Versión compacta y rediseñada para evitar desbordamientos
  Widget _buildCompactSummaryItem(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      width:
          MediaQuery.of(context).size.width * 0.26, // Reducido de 0.27 a 0.26
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16), // Reducido de 18 a 16
              const SizedBox(width: 3), // Reducido de 4 a 3
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12, // Reducido de 13 a 12
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reducido de 8 a 6
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15, // Reducido de 16 a 15
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11, // Reducido de 12 a 11
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
