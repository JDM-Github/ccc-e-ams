import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvanceSYDialog extends StatelessWidget {
  final int step;
  final String activeSYLabel;
  final String nextSYLabel;

  const AdvanceSYDialog({super.key, required this.step, required this.activeSYLabel, required this.nextSYLabel});

  @override
  Widget build(BuildContext context) {
    final isStep2 = step == 2;
    final isStep3 = step == 3;

    final Color accentColor = isStep3
        ? const Color(0xFF34D399)
        : isStep2
        ? Colors.red
        : const Color(0xFFFBBF24);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.15), blurRadius: 32)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: accentColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(
                  isStep3
                      ? Icons.cloud_download_rounded
                      : isStep2
                      ? Icons.warning_rounded
                      : Icons.info_outline_rounded,
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isStep3
                    ? 'Backup Before Advancing'
                    : isStep2
                    ? 'Final Warning'
                    : 'Advance School Year?',
                style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: accentColor),
              ),
              const SizedBox(height: 12),

              // Step dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepDot(1, step, accentColor),
                  const SizedBox(width: 6),
                  _stepDot(2, step, accentColor),
                  const SizedBox(width: 6),
                  _stepDot(3, step, accentColor),
                ],
              ),
              const SizedBox(height: 16),

              // Info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Column(
                  children: [
                    _infoRow('Current AY', 'AY $activeSYLabel', const Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    _infoRow('Will advance to', 'AY $nextSYLabel', const Color(0xFF60A5FA)),
                    if (isStep3) ...[
                      const SizedBox(height: 8),
                      _infoRow('Backup', 'Required', const Color(0xFF34D399)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Body text
              Text(
                isStep3
                    ? 'A backup of this office will be downloaded to your device before advancing. This ensures you can restore the data if anything goes wrong.'
                    : isStep2
                    ? 'This is your FINAL confirmation. Advancing the school year cannot be undone. All students on AY $activeSYLabel will be marked inactive.'
                    : 'You are about to advance the school year from AY $activeSYLabel to AY $nextSYLabel. This action cannot be reversed.',
                style: GoogleFonts.dmSans(fontSize: 12.5, color: Colors.white.withOpacity(0.6), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isStep3
                              ? const Color(0xFF34D399).withOpacity(0.9)
                              : isStep2
                              ? Colors.red.withOpacity(0.85)
                              : const Color(0xFFFBBF24).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            isStep3
                                ? 'Backup & Advance'
                                : isStep2
                                ? 'Yes, Advance'
                                : 'Continue',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isStep3
                                  ? const Color(0xFF0F172A)
                                  : isStep2
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int dotStep, int currentStep, Color accentColor) {
    final isActive = dotStep <= currentStep;
    return Container(
      width: dotStep == currentStep ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? accentColor : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white54)),
        Text(
          value,
          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}
