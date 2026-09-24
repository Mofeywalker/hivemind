import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../providers/hivemind_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      String? inviteCode;

      // Check if it matches hivemind://join?code=XYZ or is raw 6-character code
      if (rawValue.startsWith('hivemind://join?code=')) {
        final uri = Uri.tryParse(rawValue);
        inviteCode = uri?.queryParameters['code'];
      } else if (rawValue.trim().length == 6) {
        inviteCode = rawValue.trim();
      }

      if (inviteCode != null && inviteCode.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        try {
          final joined = await ref
              .read(hivemindRepositoryProvider)
              .joinByInviteCode(inviteCode);
          await ref.read(activeHivemindProvider.notifier).refresh();
          ref.read(activeHivemindProvider.notifier).setActive(joined);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.joinedHivemind(joined.name))),
            );
            context.pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.failedToJoinHivemind(e.toString())),
              ),
            );
            setState(() {
              _isProcessing = false;
            });
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanHivemindQr),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined, size: 24),
            tooltip: 'Toggle flashlight',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => _controller.toggleTorch(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2.5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                l10n.qrScannerGuide,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
