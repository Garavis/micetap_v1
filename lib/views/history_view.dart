import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';
 // Importamos el FloatingBackButton

class HistoryView extends StatefulWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  // Período de tiempo seleccionado
  String _selectedPeriod = 'Día';
  final List<String> _periodOptions = ['Día', 'Semana', 'Mes'];
  
  // Para almacenar el ID del dispositivo
  String? deviceId;
  
  // Para almacenar los datos de consumo
  List<Map<String, dynamic>> _consumoData = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Obtener el ID del dispositivo de los argumentos
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      setState(() {
        deviceId = args;
      });
      _cargarDatosHistoricos();
    }
  }
  
  // Función para cargar los datos históricos según el período seleccionado
  Future<void> _cargarDatosHistoricos() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    if (deviceId == null) {
      throw Exception("ID de dispositivo no disponible");
    }
    
    // Calcular la fecha límite según el período seleccionado
    DateTime fechaLimite;
    final ahora = DateTime.now();
    
    switch (_selectedPeriod) {
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
    
    List<Map<String, dynamic>> datosCrudos = [];
    
    if (snapshot.docs.isEmpty) {
      datosCrudos = _generarDatosEjemplo(fechaLimite, ahora);
    } else {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        datosCrudos.add({
          'fecha': (data['fecha'] as Timestamp).toDate(),
          'consumo': data['consumo'] ?? 0.0,
        });
      }
    }
    
    // Agrupar datos para reducir la cantidad de puntos
    final datosAgrupados = _agruparDatos(datosCrudos);
    
    setState(() {
      _consumoData = datosAgrupados;
      _isLoading = false;
    });
  } catch (e) {
    print("Error al cargar datos históricos: $e");
    setState(() {
      _isLoading = false;
      _consumoData = _generarDatosEjemplo(DateTime.now().subtract(const Duration(days: 30)), DateTime.now());
    });
  }
}

// Nueva función para agrupar datos
List<Map<String, dynamic>> _agruparDatos(List<Map<String, dynamic>> datos) {
  if (datos.isEmpty) return [];
  
  // Decidir el intervalo de agrupación según el período
  Duration intervalo;
  switch (_selectedPeriod) {
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
    DateTime fecha = dato['fecha'];
    // Normalizar la fecha al inicio del intervalo
    DateTime inicioIntervalo;
    
    if (_selectedPeriod == 'Día') {
      inicioIntervalo = DateTime(
        fecha.year, fecha.month, fecha.day, 
        (fecha.hour ~/ intervalo.inHours) * intervalo.inHours
      );
    } else if (_selectedPeriod == 'Semana') {
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
    gruposDatos[inicioIntervalo]!.add(dato['consumo']);
  }
  
  // Calcular promedio para cada grupo
  List<Map<String, dynamic>> resultado = [];
  gruposDatos.forEach((fecha, valores) {
    double consumoPromedio = valores.reduce((a, b) => a + b) / valores.length;
    resultado.add({
      'fecha': fecha,
      'consumo': consumoPromedio,
    });
  });
  
  // Ordenar por fecha
  resultado.sort((a, b) => (a['fecha'] as DateTime).compareTo(b['fecha']));
  
  // Si aún tenemos demasiados puntos, hacer un muestreo
  if (resultado.length > maxPuntos) {
    int paso = (resultado.length / maxPuntos).ceil();
    List<Map<String, dynamic>> muestreo = [];
    
    for (int i = 0; i < resultado.length; i += paso) {
      if (i < resultado.length) {
        muestreo.add(resultado[i]);
      }
    }
    
    // Asegurarnos de incluir el último punto
    if (muestreo.isNotEmpty && 
        muestreo.last['fecha'] != resultado.last['fecha']) {
      muestreo.add(resultado.last);
    }
    
    return muestreo;
  }
  
  return resultado;
}
  
  // Función para generar datos de ejemplo (solo para visualización inicial)
  List<Map<String, dynamic>> _generarDatosEjemplo(DateTime inicio, DateTime fin) {
    List<Map<String, dynamic>> datos = [];
    DateTime fecha = inicio;
    
    while (fecha.isBefore(fin)) {
      // Generar un valor de consumo aleatorio entre 0.5 y 3.5 kWh
      final consumo = 0.5 + (3.0 * (DateTime.now().hour % 24) / 24.0);
      
      datos.add({
        'fecha': fecha,
        'consumo': consumo,
      });
      
      // Incrementar la fecha según el período
      if (_selectedPeriod == 'Día') {
        fecha = fecha.add(const Duration(hours: 1));
      } else {
        fecha = fecha.add(const Duration(days: 1));
      }
    }
    
    return datos;
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
            if (deviceId != null)
              Text(
                'Dispositivo: $deviceId',
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
                    value: _selectedPeriod,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                        });
                        _cargarDatosHistoricos();
                      }
                    },
                    items: _periodOptions.map<DropdownMenuItem<String>>((String value) {
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _consumoData.isEmpty
                      ? const Center(child: Text('No hay datos disponibles para el período seleccionado'))
                      : _buildConsumoChart(),
            ),
            
            const SizedBox(height: 16),
            
            // Resumen de consumo
            if (!_isLoading && _consumoData.isNotEmpty)
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
  for (var dato in _consumoData) {
    if (dato['consumo'] > maxY) {
      maxY = dato['consumo'];
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
                if (value.toInt() >= 0 && value.toInt() < _consumoData.length) {
                  final fecha = _consumoData[value.toInt()]['fecha'] as DateTime;
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
        maxX: _consumoData.length.toDouble() - 1,
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
    if (_consumoData.length <= 12) {
      return 1;
    } else if (_consumoData.length <= 24) {
      return 2;
    } else {
      return (_consumoData.length / 6).ceil().toDouble();
    }
  }
  
  List<FlSpot> _getFlSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _consumoData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _consumoData[i]['consumo'].toDouble()));
    }
    return spots;
  }
  
  String _formatDate(DateTime fecha) {
    if (_selectedPeriod == 'Día') {
      return DateFormat('HH:mm').format(fecha);
    } else if (_selectedPeriod == 'Semana') {
      return DateFormat('E').format(fecha);
    } else {
      return DateFormat('dd/MM').format(fecha);
    }
  }
  
  Widget _buildConsumoSummary() {
    // Calcular valores resumen
    double consumoTotal = 0;
    double consumoMaximo = 0;
    double consumoPromedio = 0;
    
    for (var dato in _consumoData) {
      final consumo = dato['consumo'] as double;
      consumoTotal += consumo;
      if (consumo > consumoMaximo) {
        consumoMaximo = consumo;
      }
    }
    
    if (_consumoData.isNotEmpty) {
      consumoPromedio = consumoTotal / _consumoData.length;
    }
    
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
          _buildSummaryItem('Total', '${consumoTotal.toStringAsFixed(2)} kWh', Colors.blue),
          _buildSummaryItem('Promedio', '${consumoPromedio.toStringAsFixed(2)} kWh', Colors.green),
          _buildSummaryItem('Máximo', '${consumoMaximo.toStringAsFixed(2)} kWh', Colors.orange),
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