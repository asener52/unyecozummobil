import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage.dart';

class OtpScreen extends StatefulWidget {
  final bool rememberMe;
  /// 'phone' veya 'email' — geri butonunun metnini belirler
  final String loginMode;

  const OtpScreen({super.key, this.rememberMe = true, this.loginMode = 'phone'});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _maxAttempts = 5;
  static const _attemptsKey = 'otp_attempts';
  static const _lockUntilKey = 'otp_lock_until';

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;
  int _attempts = 0;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _loadAttempts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _loadAttempts() {
    _attempts = int.tryParse(LocalStorage.getString(_attemptsKey) ?? '0') ?? 0;
    final lockUntilMs = int.tryParse(LocalStorage.getString(_lockUntilKey) ?? '0') ?? 0;
    if (lockUntilMs > DateTime.now().millisecondsSinceEpoch) {
      setState(() => _locked = true);
    }
  }

  Future<void> _recordFailedAttempt() async {
    _attempts++;
    await LocalStorage.setString(_attemptsKey, _attempts.toString());
    if (_attempts >= _maxAttempts) {
      // 15 dakika kilitle
      final until = DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch;
      await LocalStorage.setString(_lockUntilKey, until.toString());
      if (mounted) setState(() => _locked = true);
    }
  }

  Future<void> _clearAttempts() async {
    await LocalStorage.remove(_attemptsKey);
    await LocalStorage.remove(_lockUntilKey);
    _attempts = 0;
    _locked = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çok fazla hatalı deneme. 15 dakika bekleyin.')),
      );
      return;
    }
    final code = _otpCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 6 haneli kodu girin')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(code, rememberMe: widget.rememberMe);
    if (!mounted) return;
    if (success) {
      await _clearAttempts();
      if (auth.biometricAvailable && !auth.biometricEnabled) {
        await _offerBiometric(auth);
      } else {
        context.go('/panel');
      }
    } else {
      await _recordFailedAttempt();
    }
  }

  Future<void> _offerBiometric(AuthProvider auth) async {
    if (!mounted) return;
    final enable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: AppTheme.primaryGreen, size: 28),
            SizedBox(width: 8),
            Text('Parmak İzi Girişi'),
          ],
        ),
        content: const Text(
          'Bir sonraki açılışta parmak izi ile hızlı giriş yapmak ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen),
            child: const Text('Evet, Etkinleştir'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (enable == true) await auth.enableBiometric();
    context.go('/panel');
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;
    context.pop(); // Geri git → telefon numarası ekranı
  }

  void _onDigitInput(int index, String value) {
    if (value.length == 6) {
      // Tüm kodu yapıştırdı
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      _verify();
      return;
    }
    if (value.isNotEmpty) {
      _controllers[index].text = value[value.length - 1];
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verify();
      }
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final phoneMasked = auth.pendingPhoneMasked ?? '***';

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.sms_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SMS Doğrulama',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$phoneMasked numarasına gönderilen\n6 haneli kodu girin',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 6 Kutu OTP input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 44,
                          height: 54,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) => _onKeyDown(i, event),
                            child: TextFormField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: i == 0 ? 6 : 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppTheme.primaryGreen, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              onChanged: (v) => _onDigitInput(i, v),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    if (auth.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.errorColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: const TextStyle(
                                    color: AppTheme.errorColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    ElevatedButton(
                      onPressed: auth.loading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: auth.loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Doğrula ve Giriş Yap',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _resendCountdown == 0 ? _resendCode : null,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Kodu tekrar gönder ($_resendCountdown sn)'
                            : 'Kodu tekrar gönder',
                        style: TextStyle(
                          color: _resendCountdown == 0
                              ? AppTheme.primaryGreen
                              : AppTheme.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().clearOtpState();
                  context.pop();
                },
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white70, size: 16),
                label: Text(
                  widget.loginMode == 'email'
                      ? 'Geri dön'
                      : 'Telefon numarasını değiştir',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
