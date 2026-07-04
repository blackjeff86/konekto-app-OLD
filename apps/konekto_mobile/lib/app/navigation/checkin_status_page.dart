import 'package:flutter/material.dart';
import 'package:konekto/app/tenants/tenant_home_page.dart';
import 'package:konekto/theme/konekto_brand.dart';

class CheckinStatusPage extends StatefulWidget {
  final String tenantId;

  const CheckinStatusPage({super.key, required this.tenantId});

  @override
  State<CheckinStatusPage> createState() => _CheckinStatusPageState();
}

class _CheckinStatusPageState extends State<CheckinStatusPage> {
  bool _isLoading = true;
  bool _isCheckedIn = false;
  String _tenantName = "";

  @override
  void initState() {
    super.initState();
    _fetchCheckinStatus();
  }

  void _fetchCheckinStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    const bool checkinResult = true;

    if (!mounted) return;
    setState(() {
      _isCheckedIn = checkinResult;
      _isLoading = false;
      _tenantName = "Hotel 1";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KonektoBrand.cream,
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: KonektoBrand.gold),
                  const SizedBox(height: 20),
                  Text('Verificando seu status de check-in...', style: KonektoBrand.body(fontSize: 15)),
                ],
              )
            : _isCheckedIn
                ? _buildCheckedInUI()
                : _buildPendingCheckinUI(),
      ),
    );
  }

  Widget _buildCheckedInUI() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StatusBadge(icon: Icons.check_rounded, color: Color(0xFF3E8E5E)),
          const SizedBox(height: 28),
          Text('Bem-vindo(a)!', textAlign: TextAlign.center, style: KonektoBrand.display(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            'Seu check-in no $_tenantName foi realizado com sucesso. Aproveite sua estadia!',
            textAlign: TextAlign.center,
            style: KonektoBrand.body(fontSize: 15),
          ),
          const SizedBox(height: 40),
          KonektoPrimaryButton(
            label: 'ACESSAR SERVIÇOS DO HOTEL',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TenantHomePage(tenantId: widget.tenantId)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCheckinUI() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StatusBadge(icon: Icons.priority_high_rounded, color: Color(0xFFC97A2B)),
          const SizedBox(height: 28),
          Text('Atenção!', textAlign: TextAlign.center, style: KonektoBrand.display(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            'Seu check-in ainda não foi realizado. Por favor, entre em contato com a recepção para finalizar o processo.',
            textAlign: TextAlign.center,
            style: KonektoBrand.body(fontSize: 15),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: _PendingActionButton(
                  icon: Icons.phone_rounded,
                  label: 'Ligar',
                  onPressed: () {
                    // Lógica para ligar para a recepção (ex: url_launcher)
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PendingActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onPressed: () {
                    // Lógica para abrir o chat com a recepção
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TenantHomePage(tenantId: widget.tenantId)),
              );
            },
            child: Text(
              'Acessar alguns serviços do Hotel',
              style: KonektoBrand.body(fontSize: 14, color: KonektoBrand.gold, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      child: Icon(icon, color: color, size: 44),
    );
  }
}

class _PendingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PendingActionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: KonektoBrand.body(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: KonektoBrand.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
