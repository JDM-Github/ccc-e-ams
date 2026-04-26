import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/context/theme_notifier.dart';
import 'package:ccc_ojt_schedule/layout/body.dart';
import 'package:ccc_ojt_schedule/screen/login.dart';
import 'package:ccc_ojt_schedule/screen/super_admin.dart';
import 'package:ccc_ojt_schedule/store/ar_store.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:ccc_ojt_schedule/store/logs_store.dart';
import 'package:ccc_ojt_schedule/store/schedule_store.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeModeNotifier = ThemeModeNotifier();
  final loginStore = LoginStore();
  await loginStore.loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleStore()),
        ChangeNotifierProvider(create: (_) => ARStore()),
        ChangeNotifierProvider(create: (_) => LogsStore()),
        Provider<LoginStore>.value(value: loginStore),
        ChangeNotifierProvider<ThemeModeNotifier>.value(value: themeModeNotifier),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeModeNotifier>();
    return MaterialApp(
      title: 'e-AMS',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.value,
      theme: ThemeManager.lightTheme,
      darkTheme: ThemeManager.darkTheme,
      navigatorKey: AppSnackBar.navigatorKey,
      home: const LoginOrHomePage(isResetted: false, isLogout: false),
    );
  }
}

class LoginOrHomePage extends StatefulWidget {
  final bool isResetted;
  final bool isLogout;
  const LoginOrHomePage({super.key, required this.isResetted, required this.isLogout});

  @override
  State<LoginOrHomePage> createState() => _LoginOrHomePageState();
}

class _LoginOrHomePageState extends State<LoginOrHomePage> {
  late final LoginStore _loginStore;
  bool _isLoggedIn = false;
  bool _isSuperAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loginStore = Provider.of<LoginStore>(context, listen: false);
    if (widget.isResetted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackBar.success(context, 'Office restored successfully. Logout is necessary to take effect.');
      });
    }
    if (widget.isLogout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackBar.success(context, 'Logout successfully!');
      });
    }
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final isSuperAdmin = _loginStore.superAdmin.value.isNotEmpty;
    setState(() {
      _isSuperAdmin = isSuperAdmin;
      _isLoggedIn = !isSuperAdmin && _loginStore.user.value.isNotEmpty;
      _isLoading = false;
    });
  }

  void _handleLogout() {
    _loginStore.logout();
    Provider.of<ScheduleStore>(context, listen: false).clearAll();
    setState(() {
      _isLoggedIn = false;
      _isSuperAdmin = false;
    });
  }

  void _handleLoginSuccess() {
    setState(() => _isLoggedIn = true);
    final cccId = _loginStore.user.value['ccc_id'];
    if (cccId != null) {
      Provider.of<ScheduleStore>(context, listen: false).fetchSchedules(cccId);
    }
  }

  void _handleSuperAdminLoginSuccess() {
    setState(() => _isSuperAdmin = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeManager.bg(context),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(ThemeManager.brand))),
      );
    }

    if (_isSuperAdmin) return SuperAdminPage(onLogout: _handleLogout);
    if (_isLoggedIn) return CustomAppBar(onLogout: _handleLogout);

    return LoginPage(onLoginSuccess: _handleLoginSuccess, onSuperAdminLoginSuccess: _handleSuperAdminLoginSuccess);
  }
}
