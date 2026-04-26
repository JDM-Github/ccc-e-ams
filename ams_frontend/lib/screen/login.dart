import 'dart:math';
import 'package:ccc_ojt_schedule/context/theme_notifier.dart';
import 'package:flutter/material.dart';

import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/forgot_password.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';

import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/components/login/login_widgets.dart';
import 'package:ccc_ojt_schedule/components/login/login_sign_in_form.dart';
import 'package:ccc_ojt_schedule/components/login/login_register_form.dart';
import 'package:ccc_ojt_schedule/components/login/login_otp_step.dart';
import 'package:ccc_ojt_schedule/components/login/login_branding_panel.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LoginPage
// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onSuperAdminLoginSuccess;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onSuperAdminLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  // ── Login form ────────────────────────────────────────────────
  final _loginFormKey   = GlobalKey<FormState>();
  final _cccIdController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginStore = LoginStore();
  bool _obscurePassword = true;
  bool _rememberMe      = false;
  String? _loginError;

  final _cccIdFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  // ── Register form ─────────────────────────────────────────────
  final _regFormKey                  = GlobalKey<FormState>();
  final _regFirstNameController      = TextEditingController();
  final _regMiddleNameController     = TextEditingController();
  final _regLastNameController       = TextEditingController();
  final _regCccIdController          = TextEditingController();
  final _regCustomIdController       = TextEditingController();
  final _regEmailController          = TextEditingController();
  final _regOfficeNameController     = TextEditingController();
  final _regPasswordController       = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _creatorPasswordController   = TextEditingController();

  bool _obscureRegPassword = true;
  bool _obscureRegConfirm  = true;
  bool _regIsLoading = false;
  String? _regError;

  // ── OTP ───────────────────────────────────────────────────────
  int    _regStep      = 0;
  String _generatedOtp = '';
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes  = List.generate(6, (_) => FocusNode());
  bool   _otpIsLoading  = false;
  String? _otpError;

  // ── Tab ───────────────────────────────────────────────────────
  late TabController _tabController;
  int _activeTab = 0; // track for dynamic card height

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _cccIdController.dispose();
    _passwordController.dispose();
    _regFirstNameController.dispose();
    _regMiddleNameController.dispose();
    _regLastNameController.dispose();
    _regCccIdController.dispose();
    _regCustomIdController.dispose();
    _regEmailController.dispose();
    _regOfficeNameController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _creatorPasswordController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes)  { f.dispose(); }
    _tabController.dispose();
    _cccIdFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Dynamic card height ───────────────────────────────────────
  // Sign-in tab is much shorter than register — no more wasted space.
  double get _tabHeight {
    if (_activeTab == 0) return 310.0;        // sign-in
    if (_regStep == 1)   return 400.0;        // OTP step
    return 500.0;                             // register form
  }

  // ─── Actions ─────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginError = null);

    final response = await _loginStore.login(
      _cccIdController.text.trim(),
      _passwordController.text,
      _rememberMe,
    );

    if (response['success'] == true) {
      if (response['is_super_admin'] == true) {
        widget.onSuperAdminLoginSuccess();
      } else {
        widget.onLoginSuccess();
      }
    } else {
      setState(() =>
        _loginError = response['message'] ?? 'Login failed. Please check your credentials.');
    }
  }

  Future<void> _handleRegisterSubmit() async {
    if (!_regFormKey.currentState!.validate()) return;
    setState(() { _regIsLoading = true; _regError = null; });

    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      _generatedOtp = otp;

      final emailResponse = await RequestHandler().handleRequest(
        'send-email',
        method: 'POST',
        body: {
          'to':      _regEmailController.text.trim(),
          'subject': 'CCC OJT — Verify your email',
          'html':    _buildOtpEmailHtml(otp),
        },
      );

      if (emailResponse['success'] == true) {
        setState(() => _regStep = 1);
        for (final c in _otpControllers) { c.clear(); }
        WidgetsBinding.instance.addPostFrameCallback((_) => _otpFocusNodes[0].requestFocus());
      } else {
        setState(() => _regError = 'Failed to send verification email. Try again.');
      }
    } catch (e) {
      setState(() => _regError = 'Network error: $e');
    } finally {
      setState(() => _regIsLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final entered  = _otpControllers.map((c) => c.text.trim()).join();
    final expected = _generatedOtp.trim();

    if (entered.length < 6) { setState(() => _otpError = 'Enter all 6 digits'); return; }
    if (entered != expected) { setState(() => _otpError = 'Incorrect code. Please try again.'); return; }

    setState(() { _otpIsLoading = true; _otpError = null; });

    try {
      final response = await RequestHandler().handleRequest(
        'user/register-admin',
        method: 'POST',
        body: {
          'first_name':  _regFirstNameController.text.trim(),
          'middle_name': _regMiddleNameController.text.trim(),
          'last_name':   _regLastNameController.text.trim(),
          'ccc_id':      _regCccIdController.text.trim(),
          'custom_id':   _regCustomIdController.text.trim(),
          'email':       _regEmailController.text.trim(),
          'office_name': _regOfficeNameController.text.trim(),
          'password':    _regPasswordController.text,
          'special_key': _creatorPasswordController.text.trim(),
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, 'Admin account created! You can now sign in.');
          _clearRegForm();
          _tabController.animateTo(0);
        }
      } else {
        setState(() => _otpError = response['message'] ?? 'Failed to create account');
      }
    } catch (e) {
      setState(() => _otpError = 'Network error: $e');
    } finally {
      setState(() => _otpIsLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() { _otpError = null; _otpIsLoading = true; });
    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      _generatedOtp = otp;

      await RequestHandler().handleRequest(
        'send-email',
        method: 'POST',
        body: {
          'to':      _regEmailController.text.trim(),
          'subject': 'CCC OJT — New verification code',
          'html':    _buildResendEmailHtml(otp),
        },
      );
      for (final c in _otpControllers) { c.clear(); }
      _otpFocusNodes[0].requestFocus();
      if (mounted) AppSnackBar.success(context, 'New code sent!');
    } catch (e) {
      setState(() => _otpError = 'Failed to resend: $e');
    } finally {
      setState(() => _otpIsLoading = false);
    }
  }

  void _clearRegForm() {
    setState(() { _regStep = 0; _generatedOtp = ''; });
    _regFirstNameController.clear();
    _regMiddleNameController.clear();
    _regLastNameController.clear();
    _regCccIdController.clear();
    _regCustomIdController.clear();
    _regEmailController.clear();
    _regOfficeNameController.clear();
    _regPasswordController.clear();
    _regConfirmPasswordController.clear();
    _creatorPasswordController.clear();
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: const ForgotPasswordDialog(),
      ),
    );
  }

  // ─── Email HTML ───────────────────────────────────────────────

  String _buildOtpEmailHtml(String otp) => '''
    <div style="font-family:sans-serif;max-width:480px;margin:auto">
      <h2 style="color:#1B3769">Verify your email</h2>
      <p>Hi ${_regFirstNameController.text.trim()},</p>
      <p>Use the code below to complete your Admin registration:</p>
      <div style="font-size:36px;font-weight:bold;letter-spacing:12px;
                  text-align:center;padding:24px;background:#F1F5F9;
                  border-radius:8px;color:#1B3769;margin:24px 0">$otp</div>
      <p style="color:#64748B;font-size:13px">
        This code expires after you close the app.
        If you did not request this, ignore this email.
      </p>
    </div>
  ''';

  String _buildResendEmailHtml(String otp) => '''
    <div style="font-family:sans-serif;max-width:480px;margin:auto">
      <h2 style="color:#1B3769">New verification code</h2>
      <div style="font-size:36px;font-weight:bold;letter-spacing:12px;
                  text-align:center;padding:24px;background:#F1F5F9;
                  border-radius:8px;color:#1B3769;margin:24px 0">$otp</div>
    </div>
  ''';

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size        = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: ThemeManager.bg(context),
      body: Stack(
        children: [
          SafeArea(
            child: isLandscape
                ? _buildLandscapeLayout()
                : _buildPortraitLayout(),
          ),
          // Theme toggle — top-right corner
          Positioned(
            top: 12,
            right: 12,
            child: _ThemeToggleButton(),
          ),
        ],
      ),
    );
  }

  // ─── Portrait ─────────────────────────────────────────────────

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildPortraitHeader(),
        Expanded(
          child: Container(
            decoration: ThemeManager.tabPanelDeco(context),
            child: _buildTabContent(compact: true),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Image.asset('assets/icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 10),
          Text('A . M . S', style: ThemeManager.titleStyle(context)),
          const SizedBox(height: 6),
          Text('Sign in to your account to continue', style: ThemeManager.subtitleStyle(context)),
        ],
      ),
    );
  }

  // ─── Landscape ────────────────────────────────────────────────

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(flex: 5, child: LoginBrandingPanel()),
        Expanded(
          flex: 4,
          child: Container(
            color: ThemeManager.bg2(context),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: _buildFormCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Form Card (landscape) ────────────────────────────────────
  // Height is now driven by _tabHeight — sign-in is compact,
  // register expands, OTP sits in between.

  Widget _buildFormCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      width: 420,
      decoration: ThemeManager.formCardDeco(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              children: [
                Text('e-AMS', style: ThemeManager.titleStyle(context)),
                const SizedBox(height: 6),
                Text(
                  'Sign in to your account to continue',
                  style: ThemeManager.subtitleStyle(context),
                ),
                const SizedBox(height: 20),
                GlassTabBar(controller: _tabController),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            height: _tabHeight,
            child: _buildTabContent(compact: false),
          ),
        ],
      ),
    );
  }

  // ─── Shared Tab Content ───────────────────────────────────────

  Widget _buildTabContent({required bool compact}) {
    return Column(
      children: [
        if (compact) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GlassTabBar(controller: _tabController),
          ),
        ],
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildSignInTab(), _buildRegisterTab()],
          ),
        ),
      ],
    );
  }

  // ─── Sign In tab ──────────────────────────────────────────────

  Widget _buildSignInTab() {
    return LoginSignInForm(
      formKey: _loginFormKey,
      cccIdController: _cccIdController,
      passwordController: _passwordController,
      cccIdFocus: _cccIdFocus,
      passwordFocus: _passwordFocus,
      obscurePassword: _obscurePassword,
      rememberMe: _rememberMe,
      loginError: _loginError,
      isLoading: _loginStore.isLoading,
      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
      onRememberMeChanged: (v) => setState(() => _rememberMe = v ?? false),
      onForgotPassword: () => _showForgotPasswordDialog(context),
      onLogin: _handleLogin,
    );
  }

  // ─── Register tab ─────────────────────────────────────────────

  Widget _buildRegisterTab() {
    if (_regStep == 1) {
      return LoginOtpStep(
        email: _regEmailController.text.trim(),
        otpControllers: _otpControllers,
        otpFocusNodes: _otpFocusNodes,
        isLoading: _otpIsLoading,
        otpError: _otpError,
        onBack: () => setState(() { _regStep = 0; _otpError = null; }),
        onVerify: _handleVerifyOtp,
        onResend: _handleResendOtp,
      );
    }

    return LoginRegisterForm(
      formKey: _regFormKey,
      firstNameController: _regFirstNameController,
      middleNameController: _regMiddleNameController,
      lastNameController: _regLastNameController,
      cccIdController: _regCccIdController,
      customIdController: _regCustomIdController,
      emailController: _regEmailController,
      officeNameController: _regOfficeNameController,
      passwordController: _regPasswordController,
      confirmPasswordController: _regConfirmPasswordController,
      creatorPasswordController: _creatorPasswordController,
      obscurePassword: _obscureRegPassword,
      obscureConfirm: _obscureRegConfirm,
      isLoading: _regIsLoading,
      regError: _regError,
      onTogglePassword: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
      onToggleConfirm:  () => setState(() => _obscureRegConfirm  = !_obscureRegConfirm),
      onSubmit: _handleRegisterSubmit,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Toggle Button
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeModeNotifier>();
    final dark = notifier.value == ThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.surface(context),
        borderRadius: BorderRadius.circular(ThemeManager.radiusBtn),
        border: Border.all(color: ThemeManager.border(context)),
      ),
      child: IconButton(
        icon: Icon(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: ThemeManager.toggleIcon(context),
          size: 18,
        ),
        onPressed: notifier.toggle,
        tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}