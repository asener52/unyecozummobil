import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/drawer_leading_button.dart';

class DialScreen extends StatefulWidget {
  const DialScreen({super.key});

  @override
  State<DialScreen> createState() => _DialScreenState();
}

class _DialScreenState extends State<DialScreen> {
  String _number = '';
  bool _calling = false;

  void _onKey(String key) {
    if (_number.length >= 15) return;
    setState(() => _number += key);
  }

  void _onBackspace() {
    if (_number.isEmpty) return;
    setState(() => _number = _number.substring(0, _number.length - 1));
  }

  void _onBackspaceLong() {
    if (_number.isEmpty) return;
    setState(() => _number = '');
  }

  String _formatDisplay(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    if (digits.length <= 7) return '${digits.substring(0, 4)} ${digits.substring(4)}';
    if (digits.length <= 9) return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    if (digits.length <= 11) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9)}';
    }
    return digits;
  }

  Future<void> _callViaPbx() async {
    final phone = _number.trim();
    if (phone.isEmpty) return;

    final clean = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    final phoneRegex = RegExp(r'^(\+90|0)?[5][0-9]{9}$');
    if (!phoneRegex.hasMatch(clean)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçersiz numara. Lütfen 05XX XXX XX XX formatında bir GSM girin.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _calling = true);
    try {
      final api = ApiService();
      await api.post(ApiConstants.pbxCallAndConnect, data: {'citizen_phone': clean});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Arama başlatıldı! Önce kendi telefonunuz çalacak, '
            'ardından karşı tarafa bağlanacaksınız.',
          ),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 5),
        ),
      );
      setState(() => _number = '');
    } catch (e) {
      if (!mounted) return;
      String msg = 'Arama başlatılamadı';
      try {
        final errMsg = (e as dynamic).response?.data?['error'] as String?;
        if (errMsg != null && errMsg.isNotEmpty) msg = errMsg;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  Widget _buildDialKey(String label, {String? sublabel}) {
    return _DialKey(
      label: label,
      sublabel: sublabel,
      onTap: () => _onKey(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final hasPhone = user?.phone != null && (user?.phone?.isNotEmpty ?? false);
    final canCall = _number.isNotEmpty && !_calling && hasPhone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Numara Çevir'),
        leading: const DrawerLeadingButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // GSM uyarısı
            if (!hasPhone)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF7E6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFA8C16), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Santral araması için profilinizde GSM numarası tanımlı olmalı. '
                        'Profil sayfasından telefon numaranızı ekleyin.',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF874D00)),
                      ),
                    ),
                  ],
                ),
              ),

            // Numara göstergesi
            Expanded(
              flex: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _number.isEmpty
                        ? 'Numara girin'
                        : _formatDisplay(_number),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _number.isEmpty ? 20 : 34,
                      fontWeight: FontWeight.w300,
                      color: _number.isEmpty
                          ? AppTheme.textHint
                          : AppTheme.textPrimary,
                      letterSpacing: _number.isEmpty ? 0 : 2,
                    ),
                  ),
                ),
              ),
            ),

            // Tuş takımı
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('1'),
                        _buildDialKey('2', sublabel: 'ABC'),
                        _buildDialKey('3', sublabel: 'DEF'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('4', sublabel: 'GHI'),
                        _buildDialKey('5', sublabel: 'JKL'),
                        _buildDialKey('6', sublabel: 'MNO'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('7', sublabel: 'PQRS'),
                        _buildDialKey('8', sublabel: 'TUV'),
                        _buildDialKey('9', sublabel: 'WXYZ'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('*'),
                        _buildDialKey('0', sublabel: '+'),
                        _buildDialKey('#'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Alt alan: sil + ara butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Silme butonu (sadece numara varsa)
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: _number.isNotEmpty
                        ? _DialBackspaceKey(
                            onTap: _onBackspace,
                            onLongPress: _onBackspaceLong,
                          )
                        : const SizedBox(),
                  ),

                  const SizedBox(width: 20),

                  // Ara butonu
                  GestureDetector(
                    onTap: canCall ? _callViaPbx : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: canCall
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                        boxShadow: canCall
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: _calling
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.call_rounded,
                              color: Colors.white, size: 32),
                    ),
                  ),

                  const SizedBox(width: 20),
                  const SizedBox(width: 72), // simetri için
                ],
              ),
            ),

            // Açıklama
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Santral üzerinden arama — önce GSM\'iniz çalar',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textHint),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dial Key Widget ──────────────────────────────────────────────────────────

class _DialKey extends StatelessWidget {
  final String label;
  final String? sublabel;
  final VoidCallback onTap;

  const _DialKey({
    required this.label,
    required this.onTap,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (sublabel != null && sublabel!.isNotEmpty)
                Text(
                  sublabel!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textHint,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Backspace Key Widget ─────────────────────────────────────────────────────

class _DialBackspaceKey extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DialBackspaceKey({
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(
            Icons.backspace_outlined,
            size: 24,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
