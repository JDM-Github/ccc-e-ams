import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteSpecialKeyDialog extends StatefulWidget {
  final Map<String, dynamic> keyData;
  final VoidCallback onDeleted;

  const DeleteSpecialKeyDialog({super.key, required this.keyData, required this.onDeleted});

  @override
  State<DeleteSpecialKeyDialog> createState() => _DeleteSpecialKeyDialogState();
}

class _DeleteSpecialKeyDialogState extends State<DeleteSpecialKeyDialog> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final response = await RequestHandler().handleRequest(
        'super-admin/special-keys/${widget.keyData['id']}',
        method: 'DELETE',
      );
      if (mounted) {
        if (response['success'] == true) {
          AppSnackBar.success(context, 'Key deleted.');
          Navigator.pop(context);
          widget.onDeleted();
        } else {
          AppSnackBar.error(context, response['message'] ?? 'Failed to delete key.');
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.keyData['key'] ?? '';
    final email = widget.keyData['email'];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Special Key',
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        'This action cannot be undone',
                        style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isDeleting ? null : () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white.withOpacity(0.45)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Container(height: 1, color: Colors.white.withOpacity(0.07)),
            const SizedBox(height: 24),

            // ── Key info ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4ADE80),
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 12, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(width: 6),
                        Text(email, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Warning note ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
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
                      'Deleting this key will immediately invalidate it. Any registration attempt using this key will fail.',
                      style: GoogleFonts.dmSans(fontSize: 11, color: Colors.amber.withOpacity(0.75), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(height: 1, color: Colors.white.withOpacity(0.07)),
            const SizedBox(height: 20),

            // ── Actions ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _cancelButton()),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _isDeleting ? null : _delete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDeleting ? Colors.white.withOpacity(0.05) : Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isDeleting ? Colors.white.withOpacity(0.08) : Colors.red.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isDeleting)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.38)),
                            )
                          else
                            const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 7),
                          Text(
                            _isDeleting ? 'Deleting...' : 'Delete Key',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isDeleting ? Colors.white38 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cancelButton() => GestureDetector(
    onTap: _isDeleting ? null : () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          'Cancel',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54),
        ),
      ),
    ),
  );
}
