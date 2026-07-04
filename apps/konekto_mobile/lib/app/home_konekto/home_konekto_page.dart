import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import 'package:konekto/app/home_konekto/history_page.dart';
import 'package:konekto/app/home_konekto/profile_page.dart';
import 'package:konekto/app/navigation/checkin_status_page.dart';
import 'package:konekto/app/navigation/qr_scanner_page.dart';
import 'package:konekto/theme/konekto_brand.dart';

// Modelo de dados para as promoções
class Promotion {
  final String title;
  final String subtitle;
  final String imagePath;

  Promotion({required this.title, required this.subtitle, required this.imagePath});

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      title: json['title'],
      subtitle: json['subtitle'],
      imagePath: json['imagePath'],
    );
  }
}

// Modelo de dados para os tenants
class Tenant {
  final String id;
  final String name;

  Tenant({required this.id, required this.name});

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
    );
  }
}

class HomeKonektoPage extends StatefulWidget {
  const HomeKonektoPage({super.key});

  @override
  State<HomeKonektoPage> createState() => _HomeKonektoPageState();
}

class _HomeKonektoPageState extends State<HomeKonektoPage> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    _HomePageBody(),
    HistoryPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektoBrand.cream,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: KonektoBrand.gold,
            unselectedItemColor: KonektoBrand.slate.withValues(alpha: 0.6),
            showUnselectedLabels: true,
            selectedLabelStyle: KonektoBrand.body(fontSize: 12, fontWeight: FontWeight.w600, color: KonektoBrand.gold),
            unselectedLabelStyle: KonektoBrand.body(fontSize: 12),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Início'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Histórico'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePageBody extends StatefulWidget {
  const _HomePageBody({super.key});

  @override
  State<_HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<_HomePageBody> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final TextEditingController _accessCodeController = TextEditingController();
  int _currentPage = 0;
  Timer? _timer;
  bool _isValidating = false;
  late Future<List<Promotion>> _promotionsFuture;
  late List<Promotion> _promotions;

  @override
  void initState() {
    super.initState();
    _promotionsFuture = _loadPromotions();
    _promotionsFuture.then((promotions) {
      if (!mounted) return;
      _promotions = promotions;
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_pageController.hasClients) {
          if (_currentPage < _promotions.length - 1) {
            _currentPage++;
          } else {
            _currentPage = 0;
          }
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeIn,
          );
        }
      });
    });
  }

  Future<List<Tenant>> _loadTenants() async {
    final jsonString = await rootBundle.loadString('assets/data/tenants.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Tenant.fromJson(json)).toList();
  }

  Future<void> _scanQrCode() async {
    final String? scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );

    if (scannedValue == null || !mounted) return;
    _accessCodeController.text = scannedValue;
    _validateAccessCode();
  }

  void _validateAccessCode() async {
    final userInput = _accessCodeController.text.trim().toLowerCase();
    if (userInput.isEmpty) {
      _showError('Insira o código de acesso do hotel.');
      return;
    }

    setState(() => _isValidating = true);
    final tenants = await _loadTenants();
    bool isValid = false;
    String? foundTenantId;

    for (var tenant in tenants) {
      if (tenant.id.toLowerCase() == userInput || tenant.name.toLowerCase() == userInput) {
        isValid = true;
        foundTenantId = tenant.id;
        break;
      }
    }

    if (!mounted) return;
    setState(() => _isValidating = false);

    if (isValid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckinStatusPage(tenantId: foundTenantId!),
        ),
      );
    } else {
      _showError('Código de acesso ou nome do hotel inválido.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: KonektoBrand.body(color: Colors.white, fontSize: 14)),
        backgroundColor: KonektoBrand.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<List<Promotion>> _loadPromotions() async {
    final jsonString = await rootBundle.loadString('assets/data/promotions.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final List<dynamic> promotionsJson = jsonMap['promotions'];
    return promotionsJson.map((json) => Promotion.fromJson(json)).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KonektoHeroPanel(height: 210, eyebrowText: 'SUA ESTADIA COMEÇA AQUI'),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: KonektoBrand.cream,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Konekto', textAlign: TextAlign.center, style: KonektoBrand.display(fontSize: 30)),
                    const SizedBox(height: 4),
                    Text(
                      'Sua jornada começa aqui',
                      textAlign: TextAlign.center,
                      style: KonektoBrand.body(fontSize: 15, fontWeight: FontWeight.w500, color: KonektoBrand.gold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Conecte-se ao seu hotel e descubra uma experiência personalizada',
                      textAlign: TextAlign.center,
                      style: KonektoBrand.body(fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(color: KonektoBrand.ink.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          KonektoTextField(
                            label: 'Código de Acesso do Hotel',
                            icon: Icons.vpn_key_outlined,
                            controller: _accessCodeController,
                          ),
                          const SizedBox(height: 14),
                          KonektoPrimaryButton(
                            label: 'CONFIRMAR ACESSO',
                            isLoading: _isValidating,
                            onPressed: _validateAccessCode,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: Divider(color: KonektoBrand.sand, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('ou', style: KonektoBrand.body(fontSize: 13)),
                              ),
                              Expanded(child: Divider(color: KonektoBrand.sand, thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _scanQrCode,
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: KonektoBrand.gold),
                            label: Text(
                              'ESCANEAR QR CODE',
                              style: KonektoBrand.body(fontSize: 14, color: KonektoBrand.ink, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: KonektoBrand.sand, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        Text('EM DESTAQUE', style: KonektoBrand.eyebrow()),
                        const SizedBox(width: 10),
                        Expanded(child: Divider(color: KonektoBrand.sand, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Conheça nossas promoções', style: KonektoBrand.display(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                height: 210,
                child: FutureBuilder<List<Promotion>>(
                  future: _promotionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: KonektoBrand.gold));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erro ao carregar promoções: ${snapshot.error}', style: KonektoBrand.body()));
                    } else if (snapshot.hasData) {
                      final promotions = snapshot.data!;
                      return PageView.builder(
                        controller: _pageController,
                        itemCount: promotions.length,
                        onPageChanged: (int index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final promotion = promotions[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: KonektoBrand.ink.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 10)),
                              ],
                              image: DecorationImage(
                                image: AssetImage(promotion.imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    promotion.title,
                                    style: KonektoBrand.display(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Center(child: Text('Nenhuma promoção encontrada.', style: KonektoBrand.body()));
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Promotion>>(
              future: _promotionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                if (snapshot.hasData) {
                  final promotions = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(promotions.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? KonektoBrand.gold : KonektoBrand.sand,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
