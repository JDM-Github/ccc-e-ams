import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AddSupervisorSheet extends StatefulWidget {
  final bool addOfficeID;
  final Function() onSuccess;
  const AddSupervisorSheet({super.key, required this.onSuccess, required this.addOfficeID});

  @override
  State<AddSupervisorSheet> createState() => _AddSupervisorSheetState();
}

class _AddSupervisorSheetState extends State<AddSupervisorSheet> {
  final _formKey = GlobalKey<FormState>();
  final LoginStore _loginStore = LoginStore();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cccIdController = TextEditingController();
  final _customIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _officeIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useCustomPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _cccIdController.dispose();
    _customIdController.dispose();
    _emailController.dispose();
    _officeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    final fn = _firstNameController.text.trim();
    final mn = _middleNameController.text.trim();
    final ln = _lastNameController.text.trim();
    final id = _cccIdController.text.trim();
    String pw = fn.isNotEmpty ? fn[0] : '';
    if (mn.isNotEmpty) pw += mn[0];
    return pw + ln + id;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final password = _useCustomPassword && _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : _generatePassword();

      final response = await RequestHandler().handleRequest(
        'user/register-supervisor',
        method: 'POST',
        body: {
          'supervisor_ccc_id': _loginStore.user.value['ccc_id'],
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'ccc_id': _cccIdController.text.trim(),
          'custom_id': _customIdController.text.trim(),
          'email': _emailController.text.trim(),
          'office_id': _officeIdController.text.trim(),
          'password': password,
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, 'Supervisor account created successfully');
          widget.onSuccess();
          Navigator.pop(context);
        }
      } else {
        setState(() => _errorMessage = response['message'] ?? 'Failed to create supervisor account');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return isLandscape ? _buildPcDialog() : _buildMobileSheet();
  }

  // ── PC dialog ──────────────────────────────────────────────────────────────

  Widget _buildPcDialog() {
    return Center(
      child: Container(
        width: 560,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeManager.borderStrong(context)),
          boxShadow: ThemeManager.isDark(context)
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pcHeader(),
            Divider(height: 1, color: ThemeManager.dividerColor(context)),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
              child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _formBody()),
            ),
            Divider(height: 1, color: ThemeManager.dividerColor(context)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(child: _cancelButton()),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _submitButton()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile sheet ───────────────────────────────────────────────────────────

  Widget _buildMobileSheet() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: ThemeManager.surfaceElevated(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: ThemeManager.borderStrong(context))),
        boxShadow: ThemeManager.isDark(context)
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeManager.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _mobileHeader(),
              const SizedBox(height: 20),
              _formBody(),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: _submitButton()),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Headers ────────────────────────────────────────────────────────────────

  Widget _pcHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _headerIcon(Icons.manage_accounts_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Supervisor Account',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ThemeManager.primary(context),
                  ),
                ),
                Text(
                  'Create a new supervisor account',
                  style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
                ),
              ],
            ),
          ),
          _closeButton(),
        ],
      ),
    );
  }

  Widget _mobileHeader() {
    return Row(
      children: [
        _headerIcon(Icons.manage_accounts_rounded),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Supervisor Account',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeManager.primary(context),
              ),
            ),
            Text(
              'Create a new supervisor account',
              style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Form body ──────────────────────────────────────────────────────────────

  Widget _formBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[_errorBanner(_errorMessage!), const SizedBox(height: 16)],

          _sectionLabel('Personal Information', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline_rounded,
                  validator: _nameValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline_rounded,
                  validator: _nameValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            controller: _middleNameController,
            label: 'Middle Name (Optional)',
            icon: Icons.person_outline_rounded,
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return null;
              if (!RegExp(r"^[a-zA-ZñÑ\s\-']+$").hasMatch(val)) return 'Letters only';
              return null;
            },
          ),

          const SizedBox(height: 20),
          _sectionLabel('Account Information', Icons.badge_outlined),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _cccIdController,
                  label: 'CCC ID',
                  icon: Icons.badge_outlined,
                  validator: _idValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  controller: _customIdController,
                  label: 'Custom ID',
                  icon: Icons.tag_rounded,
                  validator: _shortIdValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
          ),

          if (widget.addOfficeID) ...[
            const SizedBox(height: 12),
            _field(
              controller: _officeIdController,
              label: 'Office ID',
              icon: Icons.business_outlined,
              validator: (v) {
                if (!widget.addOfficeID) return null;
                if (v?.trim().isEmpty ?? true) return 'Required';
                return null;
              },
            ),
          ],

          const SizedBox(height: 20),
          _sectionLabel('Password', Icons.lock_outline_rounded),
          const SizedBox(height: 12),
          _passwordToggle(),

          if (_useCustomPassword) ...[
            const SizedBox(height: 12),
            _passwordField(),
          ] else ...[
            const SizedBox(height: 8),
            _passwordHint(),
          ],
        ],
      ),
    );
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _nameValidator(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Required';
    if (val.length < 2) return 'Too short';
    if (!RegExp(r"^[a-zA-ZñÑ\s\-']+$").hasMatch(val)) return 'Letters only';
    return null;
  }

  String? _idValidator(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Required';
    if (val.length < 3) return 'Too short';
    return null;
  }

  String? _shortIdValidator(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Required';
    if (val.length < 2) return 'Too short';
    return null;
  }

  String? _emailValidator(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Required';
    if (!RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(val)) return 'Invalid email';
    return null;
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeManager.errorBgColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.errorBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: ThemeManager.errorTextColor(context), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: ThemeManager.errorTextColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ThemeManager.brand.withOpacity(ThemeManager.isDark(context) ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: ThemeManager.brand),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
        ),
      ],
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: ThemeManager.brand.withOpacity(ThemeManager.isDark(context) ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: ThemeManager.brand, size: 20),
    );
  }

  Widget _closeButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceTint(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ThemeManager.border(context)),
        ),
        child: Icon(Icons.close_rounded, size: 16, color: ThemeManager.secondary(context)),
      ),
    );
  }

  Widget _cancelButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: ThemeManager.secondary(context),
        side: BorderSide(color: ThemeManager.border(context)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _submitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleSubmit,
      icon: _isLoading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.manage_accounts_rounded, size: 17),
      label: Text(
        _isLoading ? 'Creating...' : 'Create Account',
        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeManager.brand,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        disabledBackgroundColor: ThemeManager.surfaceTint(context),
        disabledForegroundColor: ThemeManager.muted(context),
      ),
    );
  }

  Widget _passwordToggle() {
    final isDark = ThemeManager.isDark(context);
    return GestureDetector(
      onTap: () => setState(() {
        _useCustomPassword = !_useCustomPassword;
        if (!_useCustomPassword) _passwordController.clear();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _useCustomPassword
              ? ThemeManager.brand.withOpacity(isDark ? 0.12 : 0.06)
              : ThemeManager.inputFillColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _useCustomPassword ? ThemeManager.brand.withOpacity(0.35) : ThemeManager.inputBorderColor(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _useCustomPassword ? Icons.edit_rounded : Icons.auto_awesome_rounded,
              size: 16,
              color: _useCustomPassword ? ThemeManager.brand : ThemeManager.muted(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _useCustomPassword ? 'Custom Password' : 'Auto-generate Password',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _useCustomPassword ? ThemeManager.brand : ThemeManager.primary(context),
                    ),
                  ),
                  Text(
                    _useCustomPassword ? 'Enter a password manually' : 'Generated from name + CCC ID',
                    style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.muted(context)),
                  ),
                ],
              ),
            ),
            Switch(
              value: _useCustomPassword,
              onChanged: (val) => setState(() {
                _useCustomPassword = val;
                if (!_useCustomPassword) _passwordController.clear();
              }),
              activeColor: ThemeManager.brand,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
      validator: _useCustomPassword
          ? (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'Required when custom password is enabled';
              if (val.length < 6) return 'Minimum 6 characters';
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.inputLabelColor(context)),
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: ThemeManager.inputIconColor(context)),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 16,
            color: ThemeManager.inputIconColor(context),
          ),
        ),
        filled: true,
        fillColor: ThemeManager.inputFillColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.inputBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.inputBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.inputFocusedColor(context), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context), width: 1.5),
        ),
      ),
    );
  }

  Widget _passwordHint() {
    final isDark = ThemeManager.isDark(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? ThemeManager.blue(context).withOpacity(0.08) : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? ThemeManager.blue(context).withOpacity(0.2) : Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: ThemeManager.blue(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Password will be: [First initial][Middle initial?][Last name][CCC ID]',
              style: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.blue(context), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.inputLabelColor(context)),
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.inputHintColor(context)),
        prefixIcon: Icon(icon, size: 16, color: ThemeManager.inputIconColor(context)),
        filled: true,
        fillColor: ThemeManager.inputFillColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.inputBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.inputBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.inputFocusedColor(context), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ThemeManager.errorTextColor(context), width: 1.5),
        ),
      ),
    );
  }
}
