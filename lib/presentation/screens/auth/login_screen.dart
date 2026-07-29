import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Telefon sekmesi
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _rememberMe = true;

  // E-posta sekmesi
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _emailRememberMe = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshBiometricAvailability();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Telefon ile giriş ─────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.requestOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      context.push('/otp-dogrulama',
          extra: {'rememberMe': _rememberMe, 'loginMode': 'phone'});
    }
  }

  // ── E-posta + şifre ile giriş ─────────────────────────────────────────────

  Future<void> _loginWithEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithEmailRequestOtp(
        _emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (success) {
      context.push('/otp-dogrulama',
          extra: {'rememberMe': _emailRememberMe, 'loginMode': 'email'});
    }
  }

  // ── Parmak izi ile giriş ──────────────────────────────────────────────────

  Future<void> _loginWithBiometric() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithBiometric();
    if (!mounted) return;
    if (success) {
      context.go('/panel');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parmak izi doğrulaması başarısız.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ── Gizlilik politikası ───────────────────────────────────────────────────

  void _openPrivacyPolicy() {
    context.push('/gizlilik-politikasi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ünye Belediyesi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Çözüm Merkezi',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),

              // Kart
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                    // Tab bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textSecondary,
                          labelStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          unselectedLabelStyle:
                              const TextStyle(fontSize: 13),
                          indicator: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.phone_android_rounded, size: 18),
                              text: 'Telefon ile',
                            ),
                            Tab(
                              icon: Icon(Icons.email_outlined, size: 18),
                              text: 'E-posta ile',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab içerikleri
                    SizedBox(
                      height: 320,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _PhoneTab(
                            formKey: _phoneFormKey,
                            phoneCtrl: _phoneCtrl,
                            rememberMe: _rememberMe,
                            onRememberMeChanged: (v) =>
                                setState(() => _rememberMe = v),
                            onSendOtp: _sendOtp,
                          ),
                          _EmailTab(
                            formKey: _emailFormKey,
                            emailCtrl: _emailCtrl,
                            passwordCtrl: _passwordCtrl,
                            passwordVisible: _passwordVisible,
                            onTogglePassword: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                            rememberMe: _emailRememberMe,
                            onRememberMeChanged: (v) =>
                                setState(() => _emailRememberMe = v),
                            onLogin: _loginWithEmail,
                          ),
                        ],
                      ),
                    ),

                    // Hata mesajı
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) {
                        if (auth.error == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.errorColor
                                    .withValues(alpha: 0.3)),
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
                                    color: AppTheme.errorColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Parmak izi butonu
                    Consumer<AuthProvider>(
                      builder: (_, auth, __) {
                        if (!auth.biometricEnabled ||
                            !auth.biometricAvailable) {
                          return const SizedBox(height: 8);
                        }
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: OutlinedButton.icon(
                            onPressed:
                                auth.loading ? null : _loginWithBiometric,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.6)),
                            ),
                            icon: const Icon(Icons.fingerprint,
                                color: AppTheme.primaryGreen, size: 24),
                            label: const Text(
                              'Parmak İzi ile Giriş',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Gizlilik politikası linki
              TextButton.icon(
                onPressed: _openPrivacyPolicy,
                icon: const Icon(Icons.privacy_tip_outlined,
                    color: Colors.white70, size: 16),
                label: const Text(
                  'Gizlilik Politikası',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white54, size: 16),
                label: const Text(
                  'Vatandaş Portalına Dön',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
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

// ─── Telefon Sekmesi ─────────────────────────────────────────────────────────

class _PhoneTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onSendOtp;

  const _PhoneTab({
    required this.formKey,
    required this.phoneCtrl,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onSendOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Telefon Numarası',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              onFieldSubmitted: (_) => onSendOtp(),
              decoration: const InputDecoration(
                hintText: '05XX XXX XX XX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Telefon numarası gerekli';
                }
                if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                  return 'Geçerli bir telefon numarası girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _RememberMeRow(
                value: rememberMe, onChanged: onRememberMeChanged),
            const Spacer(),
            Consumer<AuthProvider>(
              builder: (_, auth, __) => ElevatedButton.icon(
                onPressed: auth.loading ? null : onSendOtp,
                icon: auth.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.sms_outlined),
                label: Text(
                  auth.loading ? 'Gönderiliyor...' : 'Kod Gönder',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── E-posta Sekmesi ─────────────────────────────────────────────────────────

class _EmailTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onLogin;

  const _EmailTab({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordCtrl,
              obscureText: !passwordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Şifre gerekli' : null,
            ),
            const SizedBox(height: 8),
            _RememberMeRow(
                value: rememberMe, onChanged: onRememberMeChanged),
            const Spacer(),
            Consumer<AuthProvider>(
              builder: (_, auth, __) => ElevatedButton.icon(
                onPressed: auth.loading ? null : onLogin,
                icon: auth.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.login_rounded),
                label: Text(
                  auth.loading ? 'Devam ediliyor...' : 'Devam Et',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Beni Hatırla satırı ─────────────────────────────────────────────────────

class _RememberMeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RememberMeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? true),
              activeColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Beni hatırla (30 gün)',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
