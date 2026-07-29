import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drawer_provider.dart';
import '../../providers/request_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user.dart';
import 'calls_screen.dart';
import 'dial_screen.dart';
import 'dashboard_screen.dart';
import 'request_list_screen.dart';
import 'my_tasks_screen.dart';
import 'profile_screen.dart';

class AdminShell extends StatefulWidget {
  final Widget? child;

  const AdminShell({super.key, this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  int _lastNotifiedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<RequestProvider>();
      prov.startPolling();
      prov.addListener(_onProviderChanged);
    });
  }

  @override
  void dispose() {
    final prov = context.read<RequestProvider>();
    prov.removeListener(_onProviderChanged);
    prov.stopPolling();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final count = context.read<RequestProvider>().newRequestCount;
    if (count > _lastNotifiedCount) {
      _lastNotifiedCount = count;
      final role = context.read<AuthProvider>().user?.role ?? '';
      final taleperTab = _showDashboard(role) ? 1 : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count yeni talep geldi'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Gör',
            onPressed: () {
              setState(() => _selectedIndex = taleperTab);
              context.read<RequestProvider>().clearNewCount();
              _lastNotifiedCount = 0;
            },
          ),
        ),
      );
    }
  }

  bool _showDashboard(String role) =>
      role == 'superadmin' || role == 'admin' || role == 'unit_manager';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.role ?? 'unit_user';
    final hasDashboard = _showDashboard(role);
    final hasCalls = (user?.hasPermission('calls:read') ?? false) ||
        (user?.hasPermission('calls:use') ?? false);
    final hasDialOut = user?.hasPermission('calls:use') ?? false;
    final newCount = context.watch<RequestProvider>().newRequestCount;

    final List<Widget> screens = [];
    final List<BottomNavigationBarItem> items = [];

    if (hasDashboard) {
      screens.add(const DashboardScreen());
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard_rounded),
        label: 'Panel',
      ));
    }

    screens.add(const RequestListScreen());
    items.add(BottomNavigationBarItem(
      icon: _BadgeIcon(icon: const Icon(Icons.list_alt_outlined), count: newCount),
      activeIcon: _BadgeIcon(icon: const Icon(Icons.list_alt_rounded), count: newCount),
      label: 'Talepler',
    ));

    screens.add(
      ChangeNotifierProvider<RequestProvider>(
        create: (_) => RequestProvider(
          storagePrefix: 'my_tasks',
          defaultAssignedToMe: true,
        ),
        child: const MyTasksScreen(),
      ),
    );
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.task_alt_outlined),
      activeIcon: Icon(Icons.task_alt_rounded),
      label: 'Görevlerim',
    ));

    if (hasCalls) {
      screens.add(const CallsScreen());
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.phone_outlined),
        activeIcon: Icon(Icons.phone_rounded),
        label: 'Çağrılar',
      ));
    }

    if (hasDialOut) {
      screens.add(const DialScreen());
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.dialpad_outlined),
        activeIcon: Icon(Icons.dialpad_rounded),
        label: 'Ara',
      ));
    }

    screens.add(const ProfileScreen());
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ));

    final clampedIndex = _selectedIndex.clamp(0, screens.length - 1);
    final taleperTab = hasDashboard ? 1 : 0;

    final drawerProv = context.read<DrawerProvider>();

    return Scaffold(
      key: drawerProv.scaffoldKey,
      drawer: _buildDrawer(context, user),
      body: IndexedStack(
        index: clampedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: clampedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == taleperTab && newCount > 0) {
            context.read<RequestProvider>().clearNewCount();
            _lastNotifiedCount = 0;
          }
        },
        items: items,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    final role = user?.role ?? '';
    final isAdmin = user?.isAdmin ?? false;
    final isManager = user?.isManager ?? false;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryGreen),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            accountName: Text(
              user?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? ''),
            otherAccountsPictures: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _roleLabel(role),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // TALEPLER
                _drawerSection('Talepler'),
                _drawerItem(
                  context,
                  icon: Icons.list_alt_rounded,
                  label: 'Tüm Talepler',
                  route: '/panel/talepler',
                ),
                _drawerItem(
                  context,
                  icon: Icons.task_alt_rounded,
                  label: 'Görevlerim',
                  route: '/panel/gorevlerim',
                ),
                _drawerItem(
                  context,
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Yeni Talep',
                  route: '/panel/talep-olustur',
                  pushRoute: true,
                ),

                if (isManager || isAdmin) ...[
                  const Divider(height: 1),
                  _drawerSection('Raporlar & Analiz'),
                  _drawerItem(
                    context,
                    icon: Icons.analytics_rounded,
                    label: 'Raporlar & Analitik',
                    route: '/panel/raporlar',
                    pushRoute: true,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.sentiment_satisfied_rounded,
                    label: 'Memnuniyet Anketleri',
                    route: '/panel/memnuniyet',
                    pushRoute: true,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.rate_review_rounded,
                    label: 'Geri Bildirim',
                    route: '/panel/geri-bildirim',
                    pushRoute: true,
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.timer_rounded,
                    label: 'SLA Paneli',
                    route: '/panel/sla',
                    pushRoute: true,
                  ),
                ],

                // MESAJLAR
                const Divider(height: 1),
                _drawerSection('İletişim'),
                _drawerItem(
                  context,
                  icon: Icons.inbox_rounded,
                  label: 'Dış Mesajlar',
                  route: '/panel/dis-mesajlar',
                  pushRoute: true,
                ),
                if (user?.hasPermission('calls:read') ?? false)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.phone_rounded, size: 20, color: AppTheme.primaryGreen),
                    title: const Text('Çağrı Merkezi', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = _showDashboard(role) ? 3 : 2);
                    },
                  ),
                if (user?.hasPermission('calls:use') ?? false)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.dialpad_rounded, size: 20, color: AppTheme.primaryGreen),
                    title: const Text('Numara Çevir', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      // Ara sekmesinin indexini hesapla
                      int idx = _showDashboard(role) ? 1 : 0; // talepler
                      idx += 2; // görevlerim
                      if ((user?.hasPermission('calls:read') ?? false) ||
                          (user?.hasPermission('calls:use') ?? false)) idx++;
                      setState(() => _selectedIndex = idx);
                    },
                  ),

                // YETKİ
                const Divider(height: 1),
                _drawerSection('Yetki Yönetimi'),
                _drawerItem(
                  context,
                  icon: Icons.transfer_within_a_station_rounded,
                  label: 'Delegasyonlar',
                  route: '/panel/delegasyonlar',
                  pushRoute: true,
                ),

                // YÖNETİM (Admin/Manager)
                if (isManager || isAdmin) ...[
                  const Divider(height: 1),
                  _drawerSection('Yönetim'),
                  if (isAdmin)
                    _drawerItem(
                      context,
                      icon: Icons.people_rounded,
                      label: 'Kullanıcılar',
                      route: '/panel/kullanicilar',
                      pushRoute: true,
                    ),
                  if (isAdmin)
                    _drawerItem(
                      context,
                      icon: Icons.business_rounded,
                      label: 'Birimler',
                      route: '/panel/birimler',
                      pushRoute: true,
                    ),
                  _drawerItem(
                    context,
                    icon: Icons.label_rounded,
                    label: 'Konular',
                    route: '/panel/konular',
                    pushRoute: true,
                  ),
                  if (isAdmin)
                    _drawerItem(
                      context,
                      icon: Icons.people_alt_rounded,
                      label: 'Vatandaşlar',
                      route: '/panel/vatandaslar',
                      pushRoute: true,
                    ),
                  if (user?.isSuperAdmin ?? false)
                    _drawerItem(
                      context,
                      icon: Icons.history_rounded,
                      label: 'Denetim Kaydı',
                      route: '/panel/denetim',
                      pushRoute: true,
                    ),
                  if (isAdmin)
                    _drawerItem(
                      context,
                      icon: Icons.notifications_active_rounded,
                      label: 'Bildirim Ayarları',
                      route: '/panel/bildirim-ayarlari',
                      pushRoute: true,
                    ),
                  if (isAdmin)
                    _drawerItem(
                      context,
                      icon: Icons.group_work_rounded,
                      label: 'Kullanıcı Grupları',
                      route: '/panel/kullanici-gruplari',
                      pushRoute: true,
                    ),
                ],

                // TELEFON REHBERİ
                const Divider(height: 1),
                _drawerSection('Telefon Rehberi'),
                _drawerItem(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'Dahili & Kurumsal Hatlar',
                  route: '/panel/telefon-rehberi',
                  pushRoute: true,
                ),

                // BİLGİ BANKASI
                const Divider(height: 1),
                _drawerSection('Yardım'),
                _drawerItem(
                  context,
                  icon: Icons.library_books_rounded,
                  label: 'Bilgi Bankası',
                  route: '/panel/bilgi-bankasi',
                  pushRoute: true,
                ),

                const Divider(height: 1),
                _drawerItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'Profilim',
                  route: '/panel/profil',
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.privacy_tip_outlined,
                      size: 20, color: AppTheme.textSecondary),
                  title: const Text('Gizlilik Politikası',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/gizlilik-politikasi');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: AppTheme.errorColor),
                  title: const Text('Çıkış Yap',
                      style: TextStyle(color: AppTheme.errorColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.textHint,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    bool pushRoute = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppTheme.primaryGreen),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        if (pushRoute) {
          context.push(route);
        } else {
          context.go(route);
        }
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              context.go('/giris');
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'superadmin':
        return 'Süper Admin';
      case 'admin':
        return 'Admin';
      case 'unit_manager':
        return 'Birim Yöneticisi';
      case 'unit_user':
        return 'Personel';
      case 'viewer':
        return 'İzleyici';
      default:
        return role;
    }
  }
}

class _BadgeIcon extends StatelessWidget {
  final Widget icon;
  final int count;

  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
