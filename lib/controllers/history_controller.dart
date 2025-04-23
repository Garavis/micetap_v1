import 'package:flutter/material.dart';
import 'package:micetap_v1/models/history_model.dart';


class HistoryController {
  final HistoryModel _model = HistoryModel();
  
  // Período de tiempo seleccionado
  String _selectedPeriod = 'Día';
  final List<String> _periodOptions = ['Día', 'Semana', 'Mes'];
  
  // Getters
  String get selectedPeriod => _selectedPeriod;
  List<String> get periodOptions => _periodOptions;
  List<ConsumoData> get consumoData => _model.consumoData;
  String? get deviceId => _model.deviceId;
  bool get isLoading => _model.isLoading;
  
  // Setters
  set isLoading(bool value) => _model.isLoading = value;
  
  // Inicialización con el ID del dispositivo
  void setDeviceId(String? id) {
    _model.deviceId = id;
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
  
  // Obtener información de resumen
  double getConsumoTotal() => _model.getConsumoTotal();
  double getConsumoMaximo() => _model.getConsumoMaximo();
  double getConsumoPromedio() => _model.getConsumoPromedio();
}
