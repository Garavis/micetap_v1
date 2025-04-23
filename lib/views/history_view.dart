import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:micetap_v1/controllers/history_controller.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final HistoryController _controller = HistoryController();
  
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
  
  // Método para cargar datos y actualizar la UI
  Future<void> _cargarDatos() async {
    setState(() {
      _controller.isLoading = true;
    });
    
    await _controller.cargarDatos();
    
    setState(() {
      _controller.isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('Historial de Consumo'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del dispositivo
            if (_controller.deviceId != null)
              Text(
                'Dispositivo: ${_controller.deviceId}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Filtro de período
            Row(
              children: [
                const Text(
                  'Período:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _controller.selectedPeriod,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _controller.cambiarPeriodo(newValue).then((_) {
                            setState(() {});
                          });
                        });
                      }
                    },
                    items: _controller.periodOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Gráfico de consumo
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _controller.consumoData.isEmpty
                      ? const Center(child: Text('No hay datos disponibles para el período seleccionado'))
                      : _buildConsumoChart(),
            ),
            
            const SizedBox(height: 16),
            
            // Resumen de consumo
            if (!_controller.isLoading && _controller.consumoData.isNotEmpty)
              _buildConsumoSummary(),
              
            // Añadido el FloatingBackButton
            const SizedBox(height: 20),
            const FloatingBackButton(route: '/home'),
          ],
        ),
      ),
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
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getChartInterval(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < _controller.consumoData.length) {
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
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
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
  
  Widget _buildConsumoSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', '${_controller.getConsumoTotal().toStringAsFixed(2)} kWh', Colors.blue),
          _buildSummaryItem('Promedio', '${_controller.getConsumoPromedio().toStringAsFixed(2)} kWh', Colors.green),
          _buildSummaryItem('Máximo', '${_controller.getConsumoMaximo().toStringAsFixed(2)} kWh', Colors.orange),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}