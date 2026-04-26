import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreateSpecialKeyDialog extends StatefulWidget {
  const CreateSpecialKeyDialog({super.key});

  @override
  State<CreateSpecialKeyDialog> createState() => _CreateSpecialKeyDialogState();
}

class _CreateSpecialKeyDialogState extends State<CreateSpecialKeyDialog> {
  bool _isGenerating = false;
  String? _generatedKey;
  DateTime? _expiresAt;

  final _emailController = TextEditingController();
  final _expiryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _green = Color(0xFF4ADE80);
  static const _greenDk = Color(0xFF16A34A);

  @override
  void dispose() {
    _emailController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _generateKey() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isGenerating = true);
    try {
      final hours = int.tryParse(_expiryController.text.trim());
      final response = await RequestHandler().handleRequest(
        'super-admin/create-key',
        method: 'POST',
        body: {'email': _emailController.text.trim(), if (hours != null && hours > 0) 'expires_in_hours': hours},
      );
      if (response['success'] == true) {
        setState(() {
          _generatedKey = response['key'];
          _expiresAt = response['expires_at'] != null ? DateTime.tryParse(response['expires_at'].toString()) : null;
        });
      } else {
        if (mounted) AppSnackBar.error(context, response['message'] ?? 'Failed to generate key.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _copyKey() {
    if (_generatedKey == null) return;
    Clipboard.setData(ClipboardData(text: _generatedKey!));
    AppSnackBar.success(context, 'Key copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = _generatedKey != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: _greenDk.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _greenDk.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: _green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Special Key',
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          'One-time use · Tied to an email',
                          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  _closeButton(),
                ],
              ),

              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 24),

              // ── Form fields ───────────────────────────────────────────────
              if (!hasKey) ...[
                _field(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'admin@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _expiryController,
                  label: 'Expiry (hours)',
                  hint: 'Leave blank for default 3 hours',
                  icon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Enter a valid number of hours';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: Colors.white.withOpacity(0.07)),
                const SizedBox(height: 24),
              ],

              // ── Key result ────────────────────────────────────────────────
              if (hasKey) ...[
                _buildKeyResult(),
                const SizedBox(height: 24),
                Container(height: 1, color: Colors.white.withOpacity(0.07)),
                const SizedBox(height: 20),
              ],

              // ── Actions ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _cancelButton()),
                  if (!hasKey) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isGenerating ? null : _generateKey,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isGenerating ? Colors.white.withOpacity(0.05) : _greenDk.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isGenerating ? Colors.white.withOpacity(0.08) : _green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isGenerating)
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white.withOpacity(0.38),
                                  ),
                                )
                              else
                                const Icon(Icons.generating_tokens_rounded, size: 15, color: Colors.white),
                              const SizedBox(width: 7),
                              Text(
                                _isGenerating ? 'Generating...' : 'Generate Key',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _isGenerating ? Colors.white38 : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyResult() {
    final remaining = _expiresAt?.difference(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _greenDk.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _greenDk.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _generatedKey ?? '',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _green,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _copyKey,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _greenDk.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _greenDk.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 16, color: _green),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: _greenDk.withOpacity(0.2)),
          const SizedBox(height: 14),

          _resultRow(Icons.email_outlined, 'Assigned to', _emailController.text.trim()),
          const SizedBox(height: 6),
          _resultRow(
            Icons.timer_outlined,
            'Expires at',
            _expiresAt != null ? DateFormat('hh:mm a, MMM dd').format(_expiresAt!) : '—',
          ),
          const SizedBox(height: 6),
          _resultRow(
            Icons.hourglass_bottom_rounded,
            'Time remaining',
            remaining != null ? _formatRemaining(remaining) : '—',
            valueColor: _green,
          ),

          const SizedBox(height: 14),
          _warningNote('This key is single-use and will be destroyed once redeemed or expired. Share it carefully.'),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: _green),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withOpacity(0.4))),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? Colors.white70),
        ),
      ],
    );
  }

  Widget _warningNote(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.amber.withOpacity(0.8), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.2)),
            prefixIcon: Icon(icon, size: 16, color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            errorStyle: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFEF4444)),
          ),
        ),
      ],
    );
  }

  Widget _closeButton() => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Icon(Icons.close_rounded, size: 16, color: Colors.white.withOpacity(0.45)),
    ),
  );

  Widget _cancelButton() => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          'Close',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54),
        ),
      ),
    ),
  );

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'Expired';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m remaining';
  }
}
