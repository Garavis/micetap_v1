import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:micetap_v1/models/suggestion_model.dart';

class SuggestionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _deviceId;
  String? get deviceId => _deviceId;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Variable para controlar el estado de eliminación
  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  // Control de stream para sugerencias
  StreamSubscription? _suggestionSubscription;
  List<SuggestionModel> _currentSuggestions = [];

  // Función de callback para notificar cambios
  Function(List<SuggestionModel>)? _onSuggestionsUpdate;

  // Cargar el ID del dispositivo desde Firestore
  Future<bool> loadDeviceId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = "Usuario no autenticado";
        return false;
      }

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (!doc.exists) {
        _errorMessage = "Documento del usuario no encontrado en Firestore";
        return false;
      }

      final fetchedDeviceId = doc.data()?['deviceId'];
      if (fetchedDeviceId == null) {
        _errorMessage =
            "El campo 'deviceId' no existe en el documento de usuario.";
        return false;
      }

      _deviceId = fetchedDeviceId.toString().trim();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = "Error al cargar datos: $e";
      return false;
    }
  }

  // Iniciar escucha de sugerencias con límite
  void initSuggestionsListener(Function(List<SuggestionModel>) onUpdate) {
    if (_deviceId == null) return;

    // Guardar callback
    _onSuggestionsUpdate = onUpdate;

    // Verificar caché primero
    final cachedSuggestions = SuggestionCache.getFromCache(_deviceId!);
    if (cachedSuggestions != null) {
      _currentSuggestions = cachedSuggestions;
      onUpdate(cachedSuggestions);
    }

    // Cancelar suscripción anterior si existe
    _suggestionSubscription?.cancel();

    // Crear nueva suscripción con límite
    _suggestionSubscription = _firestore
        .collection('sugerencias')
        .where('deviceId', isEqualTo: _deviceId)
        .orderBy('fecha', descending: true)
        .limit(20) // Limitar a 20 sugerencias para reducir lecturas
        .snapshots()
        .listen((snapshot) {
          final suggestions =
              snapshot.docs
                  .map(
                    (doc) => SuggestionModel.fromFirestore(doc.id, doc.data()),
                  )
                  .toList();

          // Guardar en caché
          SuggestionCache.saveToCache(_deviceId!, suggestions);

          // Actualizar lista local
          _currentSuggestions = suggestions;

          // Notificar cambios
          if (_onSuggestionsUpdate != null) {
            _onSuggestionsUpdate!(suggestions);
          }
        });
  }

  // Obtener sugerencias de una sola vez (sin stream)
  Future<List<SuggestionModel>> getSuggestionsOnce() async {
    if (_deviceId == null) return [];

    // Verificar caché primero
    final cachedSuggestions = SuggestionCache.getFromCache(_deviceId!);
    if (cachedSuggestions != null) {
      _currentSuggestions = cachedSuggestions;
      return cachedSuggestions;
    }

    try {
      final snapshot =
          await _firestore
              .collection('sugerencias')
              .where('deviceId', isEqualTo: _deviceId)
              .orderBy('fecha', descending: true)
              .limit(20)
              .get();

      final suggestions =
          snapshot.docs
              .map((doc) => SuggestionModel.fromFirestore(doc.id, doc.data()))
              .toList();

      // Guardar en caché
      SuggestionCache.saveToCache(_deviceId!, suggestions);

      // Actualizar lista local
      _currentSuggestions = suggestions;

      return suggestions;
    } catch (e) {
      print('Error al cargar sugerencias: $e');
      return [];
    }
  }

  // Método obsoleto (mantenido por compatibilidad)
  Stream<List<SuggestionModel>> getSuggestionsStream() {
    if (_deviceId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('sugerencias')
        .where('deviceId', isEqualTo: _deviceId)
        .orderBy('fecha', descending: true)
        .limit(20) // Añadir límite para reducir lecturas
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SuggestionModel.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  // Eliminar todas las sugerencias del dispositivo con animación progresiva
  Future<String?> deleteAllSuggestions(Function(int, int) onProgress) async {
    if (_deviceId == null) return "No hay dispositivo seleccionado";
    if (_isDeleting) return "Ya hay una operación de eliminación en curso";

    _isDeleting = true;

    try {
      final snapshot =
          await _firestore
              .collection('sugerencias')
              .where('deviceId', isEqualTo: _deviceId)
              .orderBy(
                'fecha',
                descending: true,
              ) // Para asegurar que se eliminen de más reciente a más antiguo
              .limit(
                50,
              ) // Limitar la consulta de eliminación para evitar sobrecarga
              .get();

      final totalItems = snapshot.docs.length;
      int deletedItems = 0;

      // Usar un batch para eliminar documentos en grupos
      if (totalItems > 0) {
        // Procesar documentos en lotes de 10 para evitar operaciones excesivas
        for (int i = 0; i < snapshot.docs.length; i += 10) {
          final batch = _firestore.batch();

          // Determinar cuántos documentos procesaremos en este lote
          final endIdx =
              (i + 10 < snapshot.docs.length) ? i + 10 : snapshot.docs.length;

          // Agregar eliminaciones al batch
          for (int j = i; j < endIdx; j++) {
            batch.delete(snapshot.docs[j].reference);
          }

          // Ejecutar el batch
          await batch.commit();

          // Actualizar el contador y notificar progreso
          deletedItems = endIdx;
          onProgress(deletedItems, totalItems);

          // Pequeña pausa para permitir actualización de UI
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Limpiar caché después de eliminar
      SuggestionCache.clearCacheForDevice(_deviceId!);

      _isDeleting = false;
      return null; // Éxito, sin mensaje de error
    } catch (e) {
      _isDeleting = false;
      return "Error al eliminar sugerencias: $e";
    }
  }

  // Método para realizar pruebas de consulta (para debug)
  void testQuery() async {
    if (_deviceId == null) return;

    try {
      await _firestore
          .collection('sugerencias')
          .where('deviceId', isEqualTo: _deviceId)
          .limit(1) // Añadir límite para reducir costo de la consulta
          .get();
    } catch (e) {
      _errorMessage = "Error en consulta: $e";
    }
  }

  // Método para liberar recursos
  void dispose() {
    _suggestionSubscription?.cancel();
    _suggestionSubscription = null;
    _onSuggestionsUpdate = null;
  }
}
