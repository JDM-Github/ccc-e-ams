import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStudentSheet extends StatefulWidget {
  final Function() onSuccess;
  const AddStudentSheet({super.key, required this.onSuccess});

  @override
  State<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<AddStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final LoginStore _loginStore = LoginStore();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _extensionController = TextEditingController();
  final _cccIdController = TextEditingController();
  final _customIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _targetHoursController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedCourse;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useCustomPassword = false;
  String? _errorMessage;
  String? _selectedSuffix;
  static const List<String> _suffixes = ['Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];
  static const List<String> _courses = [
    'AB Communication',
    'AB English Language Studies',
    'AB Filipino',
    'AB Political Science',
    'AB Psychology',
    'AB Sociology',
    'BS Accountancy',
    'BS Accounting Information Systems',
    'BS Architecture',
    'BS Biology',
    'BS Business Administration',
    'BS Chemical Engineering',
    'BS Chemistry',
    'BS Civil Engineering',
    'BS Computer Engineering',
    'BS Computer Science',
    'BS Criminology',
    'BS Customs Administration',
    'BS Data Science',
    'BS Electrical Engineering',
    'BS Electronics Engineering',
    'BS Elementary Education',
    'BS Entrepreneurship',
    'BS Environmental Science',
    'BS Finance',
    'BS Food Technology',
    'BS Forestry',
    'BS Geodetic Engineering',
    'BS Hospitality Management',
    'BS Hotel and Restaurant Management',
    'BS Industrial Engineering',
    'BS Information Systems',
    'BS Information Technology',
    'BS Interior Design',
    'BS Landscape Architecture',
    'BS Management Accounting',
    'BS Marine Biology',
    'BS Marine Engineering',
    'BS Marine Transportation',
    'BS Mathematics',
    'BS Mechanical Engineering',
    'BS Medical Laboratory Science',
    'BS Midwifery',
    'BS Mining Engineering',
    'BS Nursing',
    'BS Nutrition and Dietetics',
    'BS Occupational Therapy',
    'BS Pharmacy',
    'BS Physical Education',
    'BS Physical Therapy',
    'BS Physics',
    'BS Psychology',
    'BS Public Administration',
    'BS Radiologic Technology',
    'BS Real Estate Management',
    'BS Secondary Education',
    'BS Social Work',
    'BS Statistics',
    'BS Tourism Management',
    'Doctor of Medicine',
    'Doctor of Veterinary Medicine',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _extensionController.dispose();
    _cccIdController.dispose();
    _customIdController.dispose();
    _emailController.dispose();
    _targetHoursController.dispose();
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
        'user/register-student',
        method: 'POST',
        body: {
          'supervisor_ccc_id': _loginStore.user.value['ccc_id'],
          'first_name': _firstNameController.text.trim(),
          'middle_name': _middleNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'suffix_name': _selectedSuffix?.trim(),
          'extension_name': _extensionController.text.trim().isEmpty ? null : _extensionController.text.trim(),
          'ccc_id': _cccIdController.text.trim(),
          'custom_id': _customIdController.text.trim(),
          'email': _emailController.text.trim(),
          'course': _selectedCourse ?? '',
          'target_hours': int.parse(_targetHoursController.text.trim()),
          'password': password,
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, 'Student account created successfully');
          widget.onSuccess();
          Navigator.pop(context);
        }
      } else {
        setState(() => _errorMessage = response['message'] ?? 'Failed to create student account');
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
              : [BoxShadow(color: Colors.black.withAlpha((0.12*255).floor()), blurRadius: 24, offset: const Offset(0, 8))],
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
          _headerIcon(Icons.person_add_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Member Account',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ThemeManager.primary(context),
                  ),
                ),
                Text(
                  'Create a new member account',
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
        _headerIcon(Icons.person_add_rounded),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Student Account',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeManager.primary(context),
              ),
            ),
            Text(
              'Create a new student account',
              style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.secondary(context)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _suffixDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSuffix,
      isExpanded: true,
      dropdownColor: ThemeManager.surfaceElevated(context),
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ThemeManager.muted(context)),
      decoration: InputDecoration(
        labelText: 'Suffix (Optional)',
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.inputLabelColor(context)),
        prefixIcon: Icon(Icons.text_fields_rounded, size: 16, color: ThemeManager.inputIconColor(context)),
        filled: true,
        fillColor: ThemeManager.inputFillColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ThemeManager.inputBorderColor(context))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ThemeManager.inputBorderColor(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ThemeManager.inputFocusedColor(context), width: 1.5)),
      ),
      onChanged: (val) => setState(() => _selectedSuffix = val),
      items: [
        DropdownMenuItem<String>(value: null, child: Text('None', style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.muted(context)))),
        ..._suffixes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.dmSans(fontSize: 13)))),
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
          // AFTER
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline_rounded,
                  validator: _nameValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _suffixDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          _field(
            controller: _extensionController,
            label: 'Extension (e.g., PhD, MD)',
            icon: Icons.emoji_objects_outlined,
            hint: 'Optional',
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return null;
              if (!RegExp(r"^[a-zA-Z0-9\s\.]+$").hasMatch(val)) return 'Letters, numbers, dot, space only';
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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _courseDropdown()),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _field(
                  controller: _targetHoursController,
                  label: 'Target Hours',
                  hint: '1-99999',
                  icon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Required';
                    final parsed = int.tryParse(val);
                    if (parsed == null) return 'Numbers only';
                    if (parsed < 1) return 'Min 1';
                    if (parsed > 99999) return 'Max 99999';
                    return null;
                  },
                ),
              ),
            ],
          ),

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
          : const Icon(Icons.person_add_rounded, size: 17),
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

  Widget _courseDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCourse,
      isExpanded: true,
      menuMaxHeight: 320,
      dropdownColor: ThemeManager.surfaceElevated(context),
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ThemeManager.muted(context)),
      decoration: InputDecoration(
        labelText: 'Course',
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.inputLabelColor(context)),
        prefixIcon: Icon(Icons.school_outlined, size: 16, color: ThemeManager.inputIconColor(context)),
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
      validator: (v) => v == null ? 'Required' : null,
      onChanged: (val) => setState(() => _selectedCourse = val),
      items: _courses
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c, style: GoogleFonts.dmSans(fontSize: 13)),
            ),
          )
          .toList(),
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
