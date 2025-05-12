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
                                            _controller.periodOptions.map<
                                              DropdownMenuItem<String>
                                            >((String value) {
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
    // Determinar el valor máximo de consumo
    double maxY = 0;
    for (var dato in _controller.consumoData) {
      if (dato.consumo > maxY) {
        maxY = dato.consumo;
      }
    }

    // Añadir un 20% extra de espacio
    maxY = maxY * 1.2;
    // Establecer un mínimo razonable
    maxY = maxY < 1.0 ? 1.0 : maxY;

    // Definir el intervalo dinámico para el eje Y
    double yInterval;
    if (maxY <= 1.5) {
      yInterval = 0.2;
    } else if (maxY <= 3.0) {
      yInterval = 0.5;
    } else if (maxY <= 6.0) {
      yInterval = 1.0;
    } else {
      yInterval = 2.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: yInterval,
            verticalInterval: _getChartInterval(),
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
                interval: _getChartInterval(),
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
                  return Text(
                    '${value.toStringAsFixed(1)} kWh',
                    style: const TextStyle(
                      color: Color(0xff67727d),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: _controller.consumoData.length.toDouble() - 1,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: _getFlSpots(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.lightBlue],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Destacar el último punto como consumo actual
                  if (index == _controller.consumoData.length - 1) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: Colors.red,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 1,
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
      return DateFormat('HH:mm').format(fecha);
    } else if (_controller.selectedPeriod == 'Semana') {
      return DateFormat('E').format(fecha);
    } else {
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
