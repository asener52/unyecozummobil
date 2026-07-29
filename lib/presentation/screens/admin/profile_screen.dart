import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/common/drawer_leading_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _delegations = [];
  bool _delegLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDelegations();
  }

  Future<void> _loadDelegations() async {
    setState(() => _delegLoading = true);
    try {
      final api = ApiService();
      final res = await api.get('/delegations/my');
      final data = res.data;
      if (data is List) {
        setState(() => _delegations = List<Map<String, dynamic>>.from(data));
      } else if (data is Map && data['delegations'] is List) {
        setState(() => _delegations = List<Map<String, dynamic>>.from(data['delegations'] as List));
      }
    } catch (_) {}
    setState(() => _delegLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        leading: const DrawerLeadingButton(),
      ),
      body: ListView(
        children: [
          // Avatar ve isim
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _roleLabel(user.role),
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bilgiler
          _SectionTitle('Hesap Bilgileri'),
          _InfoTile(
            icon: Icons.business_outlined,
            label: 'Birim',
            value: user.unitName ?? '-',
          ),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: user.phone ?? '-',
          ),
          _InfoTile(
            icon: Icons.shield_outlined,
            label: 'Rol',
            value: _roleLabel(user.role),
          ),

          const SizedBox(height: 16),

          // Aktif Vekâletler
          _SectionTitle('Bana Verilen Vekâletler'),
          if (_delegLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_delegations.isEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'Aktif vekâlet yok',
                style: TextStyle(color: AppTheme.textHint, fontSize: 13),
              ),
            )
          else
            ..._delegations.map((d) => _DelegationTile(delegation: d)),

          const SizedBox(height: 16),

          // Ayarlar
          _SectionTitle('Ayarlar'),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.lock_outline),
            title: const Text('Şifre Değiştir'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.info_outline),
            title: const Text('Uygulama Hakkında'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 16),

          // Çıkış
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, color: AppTheme.errorColor),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Gerekli';
                  if (v.length < 6) return 'En az 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
                validator: (v) => v != newCtrl.text
                    ? 'Şifreler eşleşmiyor'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              currentCtrl.dispose();
              newCtrl.dispose();
              confirmCtrl.dispose();
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final ok = await context.read<AuthProvider>().changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
              currentCtrl.dispose();
              newCtrl.dispose();
              confirmCtrl.dispose();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      ok ? 'Şifre değiştirildi' : 'Şifre değiştirilemedi'),
                  backgroundColor:
                      ok ? AppTheme.successColor : AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Ünye Çözüm Merkezi',
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationLegalese: '© 2026 Ünye Belediyesi',
      children: [
        const SizedBox(height: 12),
        const Text(
          'Ünye Belediyesi Vatandaş Çözüm Merkezi mobil uygulaması. '
          'Şikayet, talep ve önerilerinizi iletmek için kullanabilirsiniz.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/gizlilik-politikasi');
          },
          child: const Text('Gizlilik Politikası'),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              GoRouter.of(context).go('/');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    const labels = {
      'superadmin': 'Süper Admin',
      'admin': 'Yönetici',
      'unit_manager': 'Birim Müdürü',
      'unit_user': 'Birim Personeli',
      'viewer': 'İzleyici',
    };
    return labels[role] ?? role;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textHint),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DelegationTile extends StatelessWidget {
  final Map<String, dynamic> delegation;

  const _DelegationTile({required this.delegation});

  @override
  Widget build(BuildContext context) {
    final delegatorName = delegation['delegator_name'] ??
        '${delegation['delegator_first_name'] ?? ''} ${delegation['delegator_last_name'] ?? ''}'.trim();
    final unitName = delegation['unit_name'] as String?;
    final endDate = delegation['end_date'] as String?;
    final isActive = delegation['is_active'] as bool? ?? false;

    String dateLabel = '';
    if (endDate != null) {
      try {
        final dt = DateTime.parse(endDate);
        dateLabel = 'Bitiş: ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      } catch (_) {}
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.people_alt_outlined,
              size: 18,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delegatorName.isNotEmpty ? delegatorName : 'Bilinmiyor',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (unitName != null)
                  Text(
                    unitName,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Aktif' : 'Pasif',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppTheme.successColor : AppTheme.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
