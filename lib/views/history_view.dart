import 'package:flutter/material.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:micetap_v1/widgets/buttonback.dart'; // Necesitarás esta dependencia para gráficos

class HistoryView extends StatefulWidget {
  const HistoryView({Key? key}) : super(key: key);

  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _periodoSeleccionado = 'Mes'; // Periodo por defecto
  final List<String> _periodos = ['Dia', 'Mes', 'Año'];
  
  // Datos de ejemplo para el gráfico
  List<BarChartGroupData> barGroups = [];
  
  @override
  void initState() {
    super.initState();
    // Inicializar datos del gráfico con datos de ejemplo
    _generarDatosEjemplo();
  }
  
  void _generarDatosEjemplo() {
    // Datos de ejemplo para el gráfico de barras
    barGroups = [
      _crearGrupoBarras(0, 5, 2),
      _crearGrupoBarras(1, 3.5, 3),
      _crearGrupoBarras(2, 4.5, 3.5),
      _crearGrupoBarras(3, 3, 5),
      _crearGrupoBarras(4, 6.5, 3.2),
      _crearGrupoBarras(5, 5, 7),
      _crearGrupoBarras(6, 7.5, 5.5),
      _crearGrupoBarras(7, 9, 8),
      _crearGrupoBarras(8, 11.5, 9.5),
    ];
  }
  
  BarChartGroupData _crearGrupoBarras(int x, double valor1, double valor2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: valor1,
          color: Colors.blue,
          width: 15,
          borderRadius: BorderRadius.zero,
        ),
        BarChartRodData(
          toY: valor2,
          color: Colors.green,
          width: 15,
          borderRadius: BorderRadius.zero,
        ),
      ],
    );
  }

  void _generarInforme() {
    // Aquí iría la lógica para generar un informe basado en el periodo seleccionado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generando informe por $_periodoSeleccionado...')),
    );
  }
  
  void _exportar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando informe...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('Historial de Consumo'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección "Generar informe por:"
              Text(
                'Generar informe por:',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(height: 10),
              
              // Botones de periodo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _periodos.map((periodo) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _periodoSeleccionado = periodo;
                      });
                      _generarInforme();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 25),
                    ),
                    child: Text(periodo),
                  );
                }).toList(),
              ),
              
              SizedBox(height: 25),
              
              // Contenedor del gráfico
              Container(
                height: 300,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumo eléctrico',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 12,
                          barGroups: barGroups,
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final labels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep'];
                                  if (value.toInt() < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        labels[value.toInt()],
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return Text('');
                                },
                                reservedSize: 25,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Leyenda
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.blue,
                              margin: EdgeInsets.only(right: 5),
                            ),
                            Text('Actual'),
                          ],
                        ),
                        SizedBox(width: 20),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.green,
                              margin: EdgeInsets.only(right: 5),
                            ),
                            Text('Anterior'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 25),
              
              // Botón de exportar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _exportar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  child: Text(
                    'Exportar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 100),
              const FloatingBackButton(route: '/home'),
            ],
          ),
        ),
      ),
    );
    
  }
}