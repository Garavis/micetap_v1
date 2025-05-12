import 'dart:math';
import 'package:flutter/material.dart';
import 'package:micetap_v1/controllers/suggestion_controller.dart';
import 'package:micetap_v1/models/suggestion_model.dart';
import 'package:micetap_v1/widgets/appbard.dart';
import 'package:micetap_v1/widgets/buttonback.dart';

class SuggestionsView extends StatefulWidget {
  const SuggestionsView({super.key});

  @override
  _SuggestionsViewState createState() => _SuggestionsViewState();
}

class _SuggestionsViewState extends State<SuggestionsView>
    with TickerProviderStateMixin {
  final SuggestionController _controller = SuggestionController();
  bool _isLoading = true;

  // Variables para el progreso de eliminación
  int _totalSuggestions = 0;
  int _deletedSuggestions = 0;
  bool _showProgress = false;

  // Controller para las animaciones
  late AnimationController _progressController;

  // Lista de claves globales para el animatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<SuggestionModel> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final success = await _controller.loadDeviceId();

    if (success) {
      _controller.testQuery();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _vaciar() async {
    if (_controller.isDeleting) return; // Prevenir múltiples eliminaciones

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Vaciar sugerencias'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar todas las sugerencias? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    setState(() {
      _showProgress = true;
      _totalSuggestions = _currentSuggestions.length;
      _deletedSuggestions = 0;
      _progressController.forward(from: 0.0);
    });

    final error = await _controller.deleteAllSuggestions((deleted, total) {
      if (mounted) {
        setState(() {
          _deletedSuggestions = deleted;
          _progressController.value = deleted / total;

          // Si tenemos la lista actual, podemos animar la eliminación de los elementos
          if (deleted <= _currentSuggestions.length &&
              _listKey.currentState != null) {
            // Animamos la eliminación del elemento más reciente (de arriba a abajo)
            _listKey.currentState!.removeItem(
              0,
              (context, animation) => _buildAnimatedSuggestionItem(
                _currentSuggestions[0],
                animation,
              ),
              duration: const Duration(milliseconds: 200),
            );

            // Eliminamos el elemento de nuestra lista local
            if (_currentSuggestions.isNotEmpty) {
              _currentSuggestions.removeAt(0);
            }
          }
        });
      }
    });

    // Pequeña pausa para que se vea que ha terminado al 100%
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _showProgress = false;
    });

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sugerencias eliminadas')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _showSuggestionDetails(SuggestionModel suggestion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    suggestion.tipoAlerta == 'warning'
                        ? Icons.warning_amber_outlined
                        : suggestion.tipoAlerta == 'critical'
                        ? Icons.close
                        : Icons.info_outline,
                    color:
                        suggestion.tipoAlerta == 'warning'
                            ? Colors.orange
                            : suggestion.tipoAlerta == 'critical'
                            ? Colors.red
                            : Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion.mensajeCorto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                suggestion.descripcion,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSuggestionItem(
    SuggestionModel suggestion,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildSuggestionItem(suggestion),
      ),
    );
  }

  Widget _buildSuggestionItem(SuggestionModel suggestion) {
    final IconData icon;
    final Color iconColor;

    switch (suggestion.tipoAlerta) {
      case 'warning':
        icon = Icons.warning_amber_outlined;
        iconColor = Colors.orange;
        break;
      case 'critical':
        icon = Icons.close;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _showSuggestionDetails(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    suggestion.mensajeCorto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionList() {
    return Column(
      children: [
        if (_showProgress)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _progressController,
                  builder:
                      (context, _) => LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Eliminando... $_deletedSuggestions de $_totalSuggestions',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<SuggestionModel>>(
            stream: _controller.getSuggestionsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final suggestions = snapshot.data ?? [];

              // Actualizar nuestra lista actual para las animaciones
              _currentSuggestions = suggestions;

              if (suggestions.isEmpty) {
                return const Center(
                  child: Text("No hay sugerencias registradas."),
                );
              }

              // Usamos AnimatedList para animar los cambios
              return AnimatedList(
                key: _listKey,
                initialItemCount: suggestions.length,
                itemBuilder: (context, index, animation) {
                  return _buildAnimatedSuggestionItem(
                    suggestions[index],
                    animation,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('SUGERENCIAS'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.deviceId == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _controller.errorMessage ??
                          'Error al cargar el dispositivo',
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recomendaciones:',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'ID: ${_controller.deviceId?.substring(0, min(_controller.deviceId!.length, 6))}...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(child: _buildSuggestionList()),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _controller.isDeleting ? null : _vaciar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _controller.isDeleting
                                  ? Colors.grey
                                  : Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _controller.isDeleting
                                ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Vaciando...',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                )
                                : const Text(
                                  'Vaciar',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const FloatingBackButton(route: '/home'),
                  ],
                ),
              ),
    );
  }
}
