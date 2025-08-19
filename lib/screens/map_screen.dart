// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import '../widgets/custom_header.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/poi_card.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final AppThemeData appColors;

  const MapScreen({
    super.key,
    required this.tenantConfig,
    required this.appColors,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> _pointsOfInterest = [];
  int? _selectedPoiIndex;
  bool _isLoading = true;
  String _mapImagePath = ''; // Para armazenar o caminho da imagem de fundo do mapa
  String _statusMessage = ''; // Para exibir mensagens de erro/status

  @override
  void initState() {
    super.initState();
    _loadMapData(); // Renomeado para carregar tudo relacionado ao mapa
  }

  Future<void> _loadMapData() async {
    try {
      // Pega o caminho do JSON do mapa do tenantConfig
      final String? mapJsonPath = widget.tenantConfig['mapJsonPath'];
      // Pega o caminho da imagem de fundo do mapa do tenantConfig
      final String? mapImagePath = widget.tenantConfig['mapImagePath'];

      if (mapJsonPath == null || mapJsonPath.isEmpty) {
        throw Exception('mapJsonPath não definido ou vazio no tenantConfig. Não é possível carregar POIs.');
      }
      if (mapImagePath == null || mapImagePath.isEmpty) {
        throw Exception('mapImagePath não definido ou vazio no tenantConfig. Não é possível exibir a imagem do mapa.');
      }

      final String response = await rootBundle.loadString(mapJsonPath);
      final Map<String, dynamic> data = json.decode(response);

      setState(() {
        _pointsOfInterest = data['pointsOfInterest'] ?? []; // Garante que é uma lista vazia se 'pointsOfInterest' não existir
        _mapImagePath = mapImagePath; // Define o caminho da imagem
        _isLoading = false;
        _statusMessage = ''; // Limpa qualquer mensagem de erro anterior
      });
    } catch (e) {
      print('ERRO FATAL: Falha ao carregar os dados ou imagem do mapa.');
      print('Detalhes do erro: $e');
      setState(() {
        _isLoading = false;
        _pointsOfInterest = []; // Limpa POIs em caso de erro
        _mapImagePath = ''; // Garante que a imagem não tente carregar
        _statusMessage = 'Falha ao carregar o mapa. Verifique a configuração: $e'; // Mensagem de erro detalhada para o usuário
      });
    }
  }

  void _onPoiTapped(int index) {
    setState(() {
      _selectedPoiIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.appColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: CustomHeader(
          title: 'Mapa do Hotel',
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: widget.appColors.primaryText),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          trailing: const SizedBox.shrink(),
          appColors: widget.appColors,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: widget.appColors.primary),
            )
          : (_mapImagePath.isEmpty && _pointsOfInterest.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 80, color: widget.appColors.secondaryText), // Ícone CORRIGIDO AQUI
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage.isNotEmpty ? _statusMessage : 'Nenhum mapa ou ponto de interesse encontrado para este hotel.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: widget.appColors.primaryText, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildPoiList(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  _mapImagePath,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: widget.appColors.borderColor,
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 80,
                                          color: widget.appColors.error,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              ..._buildMarkers(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _buildPoiList() {
    if (_pointsOfInterest.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Nenhum ponto de interesse configurado para este mapa.',
            style: TextStyle(color: widget.appColors.primaryText),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16.0),
      itemCount: _pointsOfInterest.length,
      itemBuilder: (context, index) {
        final poi = _pointsOfInterest[index];
        return PoiCard(
          title: poi['title'],
          description: poi['description'],
          imagePath: poi['imagePath'],
          appColors: widget.appColors,
          isSelected: _selectedPoiIndex == index,
          onTap: () => _onPoiTapped(index),
        );
      },
    );
  }

  List<Widget> _buildMarkers() {
    return _pointsOfInterest.asMap().entries.map((entry) {
      int index = entry.key;
      final poi = entry.value;
      final double xPos = (poi['x'] as num).toDouble();
      final double yPos = (poi['y'] as num).toDouble();

      if (_selectedPoiIndex == null || _selectedPoiIndex == index) {
        return Positioned(
          left: xPos,
          top: yPos,
          child: InkWell(
            onTap: () => _onPoiTapped(index),
            child: Icon(
              Icons.location_pin,
              color: _selectedPoiIndex == index ? widget.appColors.accent : widget.appColors.primaryText.withOpacity(0.7),
              size: _selectedPoiIndex == index ? 50 : 35,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }
}