import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/staff_invite_repository.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Tela "Convidar recepção" — só `gerente` acessa (gate feito em
/// [SettingsPage], igual às outras seções). Gera um código de convite e
/// mostra o link pronto pra compartilhar (`?invite=<code>` na própria URL
/// do portal), que [AcceptInvitePage] consome do outro lado.
class InviteStaffPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const InviteStaffPage({
    super.key,
    required this.session,
    required this.authRepository,
  });

  @override
  State<InviteStaffPage> createState() => _InviteStaffPageState();
}

class _InviteStaffPageState extends State<InviteStaffPage> {
  final _repository = StaffInviteRepository();

  bool _isGenerating = false;
  String? _errorMessage;
  String? _generatedCode;

  Future<void> _generateInvite() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(
        () => _errorMessage = 'Sessão expirada — saia e entre novamente.',
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    try {
      final code = await _repository.createInvite(token);
      setState(() => _generatedCode = code);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _inviteLink(String code) {
    return Uri.base.replace(queryParameters: {'invite': code}).toString();
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TeamListSection(
            session: widget.session,
            authRepository: widget.authRepository,
          ),
          const SizedBox(height: 32),
          Text('Convidar recepção', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Gere um link de cadastro — quem acessar vira automaticamente "Recepção" deste hotel.',
            style: KonektoBrand.body(fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1ADC2626),
                border: Border.all(color: const Color(0x4DDC2626)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: KonektoBrand.body(
                  fontSize: 12.5,
                  color: const Color(0xFFF1A6A0),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: KonektoBrand.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KonektoBrand.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_generatedCode == null)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateInvite,
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KonektoBrand.gold,
                        foregroundColor: KonektoBrand.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      label: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: KonektoBrand.ink,
                              ),
                            )
                          : Text(
                              'Gerar convite',
                              style: KonektoBrand.body(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: KonektoBrand.ink,
                              ),
                            ),
                    ),
                  )
                else ...[
                  Text(
                    'Link de cadastro',
                    style: KonektoBrand.body(
                      fontSize: 12,
                      color: KonektoBrand.slate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CopyableField(
                    value: _inviteLink(_generatedCode!),
                    onCopy: () =>
                        _copyToClipboard(_inviteLink(_generatedCode!)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Código',
                    style: KonektoBrand.body(
                      fontSize: 12,
                      color: KonektoBrand.slate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CopyableField(
                    value: _generatedCode!,
                    onCopy: () => _copyToClipboard(_generatedCode!),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => setState(() => _generatedCode = null),
                    child: Text(
                      'Gerar outro convite',
                      style: KonektoBrand.body(
                        fontSize: 12.5,
                        color: KonektoBrand.goldLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de quem já tem acesso ao portal desse hotel, com opção de
/// revogar — antes só dava pra gerar convite, não tinha como ver quem já
/// era da equipe nem tirar o acesso de alguém sem mexer direto no banco.
class _TeamListSection extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const _TeamListSection({required this.session, required this.authRepository});

  @override
  State<_TeamListSection> createState() => _TeamListSectionState();
}

class _TeamListSectionState extends State<_TeamListSection> {
  final _repository = StaffInviteRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<StaffMember> _members = const [];
  String? _revokingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Sessão expirada — saia e entre novamente.';
        _isLoading = false;
      });
      return;
    }
    try {
      final members = await _repository.listStaff(
        hotelId: widget.session.hotelId,
        token: token,
      );
      setState(() => _members = members);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revoke(StaffMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KonektoBrand.surface,
        title: Text(
          'Revogar acesso?',
          style: KonektoBrand.display(fontSize: 16),
        ),
        content: Text(
          '"${member.name}" não vai mais conseguir entrar no portal deste hotel.',
          style: KonektoBrand.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(
        () => _errorMessage = 'Sessão expirada — saia e entre novamente.',
      );
      return;
    }

    setState(() {
      _revokingId = member.id;
      _errorMessage = null;
    });
    try {
      await _repository.revokeStaff(
        hotelId: widget.session.hotelId,
        staffId: member.id,
        token: token,
      );
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _revokingId = null);
    }
  }

  String _roleLabel(String role) => role == 'gerente' ? 'Gerente' : 'Recepção';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KonektoBrand.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Equipe', style: KonektoBrand.display(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Quem já tem acesso ao portal deste hotel.',
            style: KonektoBrand.body(fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1ADC2626),
                border: Border.all(color: const Color(0x4DDC2626)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: KonektoBrand.body(
                  fontSize: 12.5,
                  color: const Color(0xFFF1A6A0),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: KonektoBrand.gold),
            )
          else if (_members.isEmpty)
            Text(
              'Ninguém cadastrado ainda.',
              style: KonektoBrand.body(fontSize: 13.5),
            )
          else
            for (final member in _members) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: KonektoBrand.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KonektoBrand.cream,
                          ),
                        ),
                        Text(
                          '${member.email} · ${_roleLabel(member.role)}',
                          style: KonektoBrand.body(
                            fontSize: 12,
                            color: KonektoBrand.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (member.id == widget.session.uid)
                    Text(
                      'Você',
                      style: KonektoBrand.body(
                        fontSize: 12,
                        color: KonektoBrand.slate,
                      ),
                    )
                  else if (_revokingId == member.id)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KonektoBrand.gold,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => _revoke(member),
                      child: Text(
                        'Revogar',
                        style: KonektoBrand.body(
                          fontSize: 12.5,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _CopyableField extends StatelessWidget {
  final String value;
  final VoidCallback onCopy;

  const _CopyableField({required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KonektoBrand.borderStrong),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: KonektoBrand.body(fontSize: 13, color: KonektoBrand.cream),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(
              Icons.copy_outlined,
              size: 18,
              color: KonektoBrand.slate,
            ),
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
