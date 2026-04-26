import 'package:ccc_ojt_schedule/components/dialogue_helpers.dart';
import 'package:ccc_ojt_schedule/components/theme_manager.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';
import 'package:ccc_ojt_schedule/store/member_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EditMemberDialog extends StatefulWidget {
  final Member member;
  final ValueChanged<Member> onConfirm;
  const EditMemberDialog({super.key, required this.member, required this.onConfirm});

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  late TextEditingController _firstName;
  late TextEditingController _middleName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _profileLink;
  late TextEditingController _targetHours;
  late TextEditingController _customId;
  String? _selectedCourse;
  final LoginStore _loginStore = LoginStore();
  final _formKey = GlobalKey<FormState>();

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
  void initState() {
    super.initState();
    final m = widget.member;
    _firstName = TextEditingController(text: m.firstName);
    _middleName = TextEditingController(text: m.middleName ?? '');
    _lastName = TextEditingController(text: m.lastName);
    _email = TextEditingController(text: m.email);
    _profileLink = TextEditingController(text: m.profileLink ?? '');
    _targetHours = TextEditingController(text: m.targetHours?.toString() ?? '');
    _customId = TextEditingController(text: m.customId ?? '');
    _selectedCourse = _courses.contains(m.course) ? m.course : null;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _middleName, _lastName, _email, _profileLink, _targetHours, _customId]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isSupervisorEditingOther =>
      _loginStore.user.value['role'] == 'supervisor' && _loginStore.user.value['ccc_id'] != widget.member.cccId;

  String? _validateName(String val) {
    if (val.isEmpty) return 'Required';
    if (val.length < 2) return 'Too short';
    if (!RegExp(r"^[a-zA-ZñÑ\s\-']+$").hasMatch(val)) return 'Letters only';
    return null;
  }

  String? _validateEmail(String val) {
    if (val.isEmpty) return 'Required';
    if (!RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(val)) return 'Invalid email';
    return null;
  }

  String? _validateCustomId(String val) {
    if (val.isEmpty) return 'Required';
    if (val.length < 2) return 'Too short';
    return null;
  }

  String? _validateTargetHours(String val) {
    if (val.isEmpty) return 'Required';
    final n = int.tryParse(val);
    if (n == null) return 'Numbers only';
    if (n < 400) return 'Min is 400';
    if (n > 800) return 'Max is 800';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSupervisorEditingOther && _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a course')));
      return;
    }
    widget.onConfirm(
      Member(
        id: widget.member.id,
        firstName: _firstName.text.trim(),
        middleName: _middleName.text.trim().isEmpty ? null : _middleName.text.trim(),
        lastName: _lastName.text.trim(),
        cccId: widget.member.cccId,
        customId: _customId.text.trim().isEmpty ? null : _customId.text.trim(),
        email: _email.text.trim(),
        course: _selectedCourse,
        profileLink: _profileLink.text.trim().isEmpty ? null : _profileLink.text.trim(),
        targetHours: _targetHours.text.isEmpty ? null : int.tryParse(_targetHours.text),
        role: widget.member.role,
        isAdmin: widget.member.isAdmin,
        current_sy: widget.member.current_sy,
        createdAt: widget.member.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDark(context);
    return Center(
      child: Container(
        width: 480,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: ThemeManager.surfaceElevated(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeManager.border(context)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3769).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Color(0xFF1B3769), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit member',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ThemeManager.primary(context),
                            ),
                          ),
                          Text(
                            widget.member.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(fontSize: 12, color: ThemeManager.muted(context)),
                          ),
                        ],
                      ),
                    ),
                    closeBtn(context, isDark),
                  ],
                ),
              ),

              Divider(height: 1, color: ThemeManager.dividerColor(context)),

              // Fields
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.60),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Personal information', Icons.person_outline_rounded, isDark),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _firstName,
                              'First name',
                              Icons.person_outline_rounded,
                              isDark,
                              validator: (v) => _validateName(v?.trim() ?? ''),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _lastName,
                              'Last name',
                              Icons.person_outline_rounded,
                              isDark,
                              validator: (v) => _validateName(v?.trim() ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _field(
                        _middleName,
                        'Middle name (optional)',
                        Icons.person_outline_rounded,
                        isDark,
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return null;
                          if (!RegExp(r"^[a-zA-ZñÑ\s\-']+$").hasMatch(val)) return 'Letters only';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Account information', Icons.badge_outlined, isDark),
                      if (_loginStore.user.value['role'] == 'supervisor') ...[
                        const SizedBox(height: 12),
                        _field(
                          _customId,
                          'Custom ID',
                          Icons.tag_rounded,
                          isDark,
                          validator: (v) => _validateCustomId(v?.trim() ?? ''),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _field(
                        _email,
                        'Email',
                        Icons.email_outlined,
                        isDark,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => _validateEmail(v?.trim() ?? ''),
                      ),
                      if (_isSupervisorEditingOther) ...[
                        const SizedBox(height: 20),
                        _sectionLabel('Academic information', Icons.school_rounded, isDark),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _courseDropdown(isDark)),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _field(
                                _targetHours,
                                'Target hours',
                                Icons.timer_outlined,
                                isDark,
                                hint: '400–800',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => _validateTargetHours(v?.trim() ?? ''),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: ThemeManager.dividerColor(context)),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(child: cancelBtn(context, isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                        label: Text(
                          'Save changes',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3769),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B3769).withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: const Color(0xFF1B3769)),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: ThemeManager.primary(context)),
        ),
      ],
    );
  }

  Widget _courseDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedCourse,
      isExpanded: true,
      menuMaxHeight: 320,
      dropdownColor: ThemeManager.surfaceElevated(context),
      style: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.primary(context)),
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: ThemeManager.muted(context)),
      decoration: _inputDeco('Course', Icons.school_outlined, isDark),
      validator: _isSupervisorEditingOther ? (v) => v == null ? 'Required' : null : null,
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

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        color: readOnly ? ThemeManager.muted(context) : ThemeManager.primary(context),
      ),
      decoration: _inputDeco(label, icon, isDark, hint: hint, readOnly: readOnly),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, bool isDark, {String? hint, bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.muted(context)),
      hintStyle: GoogleFonts.dmSans(fontSize: 13, color: ThemeManager.faint(context)),
      prefixIcon: Icon(icon, size: 15, color: ThemeManager.muted(context)),
      filled: true,
      fillColor: readOnly ? ThemeManager.surfaceTint(context) : ThemeManager.inputFillColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ThemeManager.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ThemeManager.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: readOnly ? ThemeManager.border(context) : const Color(0xFF1B3769),
          width: readOnly ? 1 : 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ThemeManager.errorTextColor(context)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ThemeManager.errorTextColor(context), width: 1.5),
      ),
      errorStyle: GoogleFonts.dmSans(fontSize: 11, color: ThemeManager.errorTextColor(context)),
    );
  }
}
