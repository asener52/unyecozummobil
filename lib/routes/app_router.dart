import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/otp_screen.dart';
import '../presentation/screens/citizen/citizen_home_screen.dart';
import '../presentation/screens/citizen/citizen_form_screen.dart';
import '../presentation/screens/citizen/citizen_track_screen.dart';
import '../presentation/screens/admin/admin_shell.dart';
import '../presentation/screens/admin/admin_create_request_screen.dart';
import '../presentation/screens/admin/dashboard_screen.dart';
import '../presentation/screens/admin/request_list_screen.dart';
import '../presentation/screens/admin/request_detail_screen.dart';
import '../presentation/screens/admin/my_tasks_screen.dart';
import '../presentation/screens/admin/profile_screen.dart';
import '../presentation/screens/admin/reports_screen.dart';
import '../presentation/screens/admin/users_screen.dart';
import '../presentation/screens/admin/units_screen.dart';
import '../presentation/screens/admin/topics_screen.dart';
import '../presentation/screens/admin/delegations_screen.dart';
import '../presentation/screens/admin/external_messages_screen.dart';
import '../presentation/screens/admin/citizens_screen.dart';
import '../presentation/screens/admin/audit_screen.dart';
import '../presentation/screens/admin/surveys_screen.dart';
import '../presentation/screens/admin/sla_screen.dart';
import '../presentation/screens/admin/feedback_screen.dart';
import '../presentation/screens/admin/notification_settings_screen.dart';
import '../presentation/screens/privacy_policy_screen.dart';
import '../presentation/screens/admin/knowledge_base_screen.dart';
import '../presentation/screens/admin/user_groups_screen.dart';
import '../presentation/screens/admin/phone_directory_screen.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/units_provider.dart';
import '../presentation/providers/topics_provider.dart';
import '../presentation/providers/users_provider.dart';
import '../presentation/providers/citizens_provider.dart';
import '../presentation/providers/delegations_provider.dart';
import '../presentation/providers/external_messages_provider.dart';
import '../presentation/providers/audit_provider.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final loc = state.matchedLocation;

    if (loc == '/splash') return null;
    if (loc.startsWith('/panel') && !auth.isAuthenticated) return '/giris';

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (_, __) => const CitizenHomeScreen(),
    ),
    GoRoute(
      path: '/giris',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/gizlilik-politikasi',
      builder: (_, __) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/otp-dogrulama',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final rememberMe = extra?['rememberMe'] as bool? ?? true;
        final loginMode = extra?['loginMode'] as String? ?? 'phone';
        return OtpScreen(rememberMe: rememberMe, loginMode: loginMode);
      },
    ),
    GoRoute(
      path: '/form/genel',
      builder: (_, __) => const CitizenFormScreen(formId: null),
    ),
    GoRoute(
      path: '/form/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return CitizenFormScreen(formId: id);
      },
    ),
    GoRoute(
      path: '/taleptakip',
      builder: (_, __) => const CitizenTrackScreen(),
    ),
    GoRoute(
      path: '/taleptakip/:tracking',
      builder: (context, state) {
        final tracking = state.pathParameters['tracking'];
        return CitizenTrackScreen(initialTracking: tracking);
      },
    ),

    // Admin panel shell (bottom nav)
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/panel',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/panel/talepler',
          builder: (_, __) => const RequestListScreen(),
        ),
        GoRoute(
          path: '/panel/gorevlerim',
          builder: (_, __) => const MyTasksScreen(),
        ),
        GoRoute(
          path: '/panel/profil',
          builder: (_, __) => const ProfileScreen(),
        ),
      ],
    ),

    // Full-screen routes (outside shell)
    GoRoute(
      path: '/panel/talep/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RequestDetailScreen(requestId: id);
      },
    ),
    GoRoute(
      path: '/panel/talep-olustur',
      builder: (_, __) => const AdminCreateRequestScreen(),
    ),
    GoRoute(
      path: '/panel/raporlar',
      builder: (_, __) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/panel/kullanicilar',
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => UsersProvider(),
        child: const UsersScreen(),
      ),
    ),
    GoRoute(
      path: '/panel/birimler',
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => UnitsProvider(),
        child: const UnitsScreen(),
      ),
    ),
    GoRoute(
      path: '/panel/konular',
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => TopicsProvider(),
        child: const TopicsScreen(),
      ),
    ),
    GoRoute(
      path: '/panel/delegasyonlar',
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => DelegationsProvider(),
        child: const DelegationsScreen(),
      ),
    ),
    GoRoute(
      path: '/panel/dis-mesajlar',
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => ExternalMessagesProvider(),
        child: const ExternalMessagesScreen(),
      ),
    ),
    GoRoute(
      path: '/panel/vatandaslar',
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => CitizensProvider(),
        child: const CitizensScreen(),
      ),
    ),
    GoRoute(
      path: '/panel/denetim',
      builder: (_, __) => ChangeNotifierProvider(
        create: (_) => AuditProvider(),
        child: const AuditScreen(),
      ),
    ),
    GoRoute(
      path: '/panel/memnuniyet',
      builder: (_, __) => const SurveysScreen(),
    ),
    GoRoute(
      path: '/panel/sla',
      builder: (_, __) => const SlaScreen(),
    ),
    GoRoute(
      path: '/panel/geri-bildirim',
      builder: (_, __) => const FeedbackScreen(),
    ),
    GoRoute(
      path: '/panel/bildirim-ayarlari',
      builder: (_, __) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/panel/bilgi-bankasi',
      builder: (_, __) => const KnowledgeBaseScreen(),
    ),
    GoRoute(
      path: '/panel/kullanici-gruplari',
      builder: (_, __) => const UserGroupsScreen(),
    ),
    GoRoute(
      path: '/panel/telefon-rehberi',
      builder: (_, __) => const PhoneDirectoryScreen(),
    ),
  ],
);
