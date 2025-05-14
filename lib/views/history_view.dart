import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:micetap_v1/controllers/history_controller.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

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

  // Control de actualización automática
  bool _isAutoUpdateEnabled = false;

  @override
  void initState() {
    super.initState();

    // Por defecto, NO configurar para recibir actualizaciones automáticas
    // Solo lo haremos en el didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obtener el ID del dispositivo de los argumentos
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      _controller.setDeviceId(args);
      _cargarDatos();

      // Solo iniciar auto-actualización si está habilitada
      _controller.autoUpdateEnabled = _isAutoUpdateEnabled;
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

  // Método para forzar recarga manual
  Future<void> _forzarRecarga() async {
    if (!mounted || _controller.isLoading) return;

    setState(() {
      _controller.isLoading = true;
    });

    await _controller.forzarRecarga();

    if (!mounted) return;

    setState(() {
      _controller.isLoading = false;
    });

    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos actualizados correctamente')),
    );
  }

  // Método para cambiar el estado de actualización automática
  void _toggleAutoUpdate(bool newValue) {
    setState(() {
      _isAutoUpdateEnabled = newValue;
      _controller.autoUpdateEnabled = newValue;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newValue
              ? 'Actualización automática activada'
              : 'Actualización automática desactivada',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
                                          : _forzarRecarga,
                                  tooltip: 'Actualizar datos',
                                ),
                              ],
                            ),
                          ),

                        // Switch para activar/desactivar actualización automática
                        Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sync,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Actualización automática',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isAutoUpdateEnabled,
                                onChanged: _toggleAutoUpdate,
                                activeColor: Colors.blue,
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

    // Exagerar la escala para hacer visibles las variaciones pequeñas
    // Reducir el mínimo y aumentar el máximo
    double avgConsumo = _controller.getConsumoPromedio();

    // Hacer que las variaciones se vean mucho más dramáticas
    double rangeMultiplier = 5.0; // Factor de multiplicación de la diferencia

    if (_controller.selectedPeriod == 'Día') {
      // Para vista de día, hacemos que las variaciones sean aún más visibles
      rangeMultiplier = 8.0;
    }

    // Calcular rango exagerado
    double currentRange = maxY - minY;
    double exaggeratedRange = currentRange * rangeMultiplier;

    // Asegurar un rango mínimo de visualización basado en el promedio
    double minVisibleRange = avgConsumo * 0.5; // Al menos 50% del promedio

    // Usar el mayor entre el rango exagerado y el mínimo visible
    double targetRange = Math.max(exaggeratedRange, minVisibleRange);

    // Calcular nuevos límites manteniendo el promedio en el centro
    minY = avgConsumo - (targetRange / 2);
    maxY = avgConsumo + (targetRange / 2);

    // Ajustar para asegurar que el mínimo no sea negativo
    if (minY < 0) {
      double adjustment = -minY;
      minY = 0;
      maxY += adjustment; // Mantener el rango
    }

    // Añadir un margen extra arriba y abajo
    double paddingY = (maxY - minY) * 0.1;
    minY = Math.max(0, minY - paddingY);
    maxY = maxY + paddingY;

    // Definir el intervalo dinámico para el eje Y
    double? yInterval;
    double range = maxY - minY;

    if (range <= 0.5) {
      yInterval = 0.1;
    } else if (range <= 1.0) {
      yInterval = 0.2;
    } else if (range <= 2.0) {
      yInterval = 0.5;
    } else if (range <= 5.0) {
      yInterval = 1.0;
    } else {
      yInterval = range / 5; // Aproximadamente 5 líneas en el eje
      // Redondear a un número "bonito"
      // Redondear a un número "bonito"
      if (yInterval > 10) {
        yInterval = (Math.pow(10, 0) * (yInterval / 10).ceil()).toDouble();
      } else if (yInterval > 5) {
        yInterval = (Math.pow(5, 1) * (yInterval / 5).ceil()).toDouble();
      } else if (yInterval > 2) {
        yInterval = (2 * (yInterval / 2).ceil()).toDouble();
      } else {
        yInterval = yInterval.ceil().toDouble();
      }
    }

    // Calcular intervalo horizontal para que se muestren más puntos
    double hInterval = 1.0;
    if (_controller.selectedPeriod == 'Día') {
      // Para vista diaria, mostrar más puntos
      hInterval = _controller.consumoData.length > 12 ? 2.0 : 1.0;
    } else if (_controller.selectedPeriod == 'Semana') {
      hInterval = _controller.consumoData.length > 14 ? 2.0 : 1.0;
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
                reservedSize: 30,
                interval: hInterval,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < _controller.consumoData.length) {
                    final fecha = _controller.consumoData[value.toInt()].fecha;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatDate(fecha),
                        style: const TextStyle(
                          color: Color(0xff68737d),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
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
      // Formato para hora del día: solo la hora
      return DateFormat('HH:mm').format(fecha);
    } else if (_controller.selectedPeriod == 'Semana') {
      // Formato para semana: abreviatura del día
      return DateFormat('E').format(fecha);
    } else {
      // Formato para mes: día/mes
      return DateFormat('dd/MM').format(fecha);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resto del método permanece igual...
        // (Código de _buildConsumoSummary())
        // ...

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
