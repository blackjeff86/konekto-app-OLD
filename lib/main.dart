// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'utils/app_theme_data.dart';
import 'screens/check_in_status_screen.dart'; // Tela inicial de check-in

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<AppThemeData> _konektoAppThemeFuture;

  @override
  void initState() {
    super.initState();
    _konektoAppThemeFuture = _loadKonektoAppTheme();
  }

  // Carrega o tema padrão da Konekto de um JSON
  Future<AppThemeData> _loadKonektoAppTheme() async {
    try {
      final String themeConfigString =
          await rootBundle.loadString('assets/themes/konekto_app_theme.json');
      final Map<String, dynamic> themeConfig = json.decode(themeConfigString);
      return AppThemeData.fromJson(themeConfig);
    } catch (e) {
      print('Erro ao carregar assets/themes/konekto_app_theme.json: $e');
      // Fallback para um tema padrão hardcoded em caso de erro
      return AppThemeData(
        primary: Colors.white,
        onPrimary: const Color(0xFF0F172A),
        accent: const Color(0xFF3B82F6),
        primaryText: const Color(0xFF111416),
        secondaryText: const Color(0xFF637287),
        background: Colors.grey[50]!,
        cardBackground: Colors.white,
        buttonBackground: const Color(0xFF0F172A),
        buttonText: Colors.white,
        borderColor: const Color(0xFFE5E8EA),
        success: Colors.green,
        warning: Colors.orange,
        error: Colors.red,
        onError: Colors.white,
        shadowColor: Colors.black.withOpacity(0.08),
        splashScreenIconPath: 'assets/images/icons/default_icon.png',
        // Valores padrão para transparentVariants
        cardTransparent: Colors.transparent,
        cardWhite70: const Color(0xB3FFFFFF),
        cardBlack50: const Color(0x80000000),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppThemeData>(
      future: _konektoAppThemeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            final AppThemeData konektoAppColors = snapshot.data!;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Konekto App',
              theme: ThemeData(
                primaryColor: konektoAppColors.primary,
                scaffoldBackgroundColor: konektoAppColors.background,
                textTheme: TextTheme(
                  headlineMedium:
                      TextStyle(color: konektoAppColors.primaryText),
                  titleLarge:
                      TextStyle(color: konektoAppColors.primaryText),
                  titleMedium:
                      TextStyle(color: konektoAppColors.primaryText),
                  bodyLarge:
                      TextStyle(color: konektoAppColors.primaryText),
                  bodyMedium:
                      TextStyle(color: konektoAppColors.primaryText),
                  headlineSmall:
                      TextStyle(color: konektoAppColors.primaryText),
                  titleSmall:
                      TextStyle(color: konektoAppColors.primaryText),
                ),
              ),
              home: CheckInStatusScreen(
                tenantConfig: const {}, // Configuração inicial vazia
                appColors: konektoAppColors, // Passa as cores padrão
              ),
            );
          } else if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text(
                    'Erro ao carregar o tema padrão da Konekto: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
        }

        // Exibe um loading enquanto o tema está sendo carregado
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
        );
      },
    );
  }
}
