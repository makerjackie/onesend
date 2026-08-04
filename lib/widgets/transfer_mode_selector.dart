import 'package:flutter/material.dart';

import '../app.dart';
import '../core/optical_transfer.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/file_service.dart';

/// A compact, shared mode entry used by send, receive, and settings.
///
/// QR profiles are shown as individual choices when [showQrProfiles] is true;
/// receive can hide those profiles because the first received frame declares
/// its profile. The color-code transport remains a peer choice in both cases.
class TransferModeSelector extends StatelessWidget {
  const TransferModeSelector({
    required this.algorithm,
    required this.mode,
    required this.enabled,
    required this.onQrModeSelected,
    required this.onCimbarSelected,
    this.showLabel = true,
    this.showQrProfiles = true,
    this.dense = false,
    this.keyPrefix = 'transfer-mode',
    super.key,
  });

  final TransferAlgorithm algorithm;
  final TransferMode mode;
  final bool enabled;
  final ValueChanged<TransferMode> onQrModeSelected;
  final VoidCallback onCimbarSelected;
  final bool showLabel;
  final bool showQrProfiles;
  final bool dense;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <Widget>[
      if (showQrProfiles)
        for (final qrMode in TransferMode.values)
          _buildChip(
            context,
            label: _modeLabel(l10n, qrMode),
            semanticLabel: l10n.modeAccessibilityLabel(
              _modeLabel(l10n, qrMode),
              formatTransferSpeed(qrMode.usefulBytesPerSecond),
            ),
            icon: Icons.qr_code_2_rounded,
            selected: algorithm == TransferAlgorithm.qr && mode == qrMode,
            onSelected: () => onQrModeSelected(qrMode),
            key: ValueKey<String>('$keyPrefix-${qrMode.name}'),
          )
      else
        _buildChip(
          context,
          label: l10n.modeQr,
          semanticLabel: l10n.modeQr,
          icon: Icons.qr_code_2_rounded,
          selected: algorithm == TransferAlgorithm.qr,
          onSelected: () => onQrModeSelected(mode),
          key: ValueKey<String>('$keyPrefix-qr'),
        ),
      _buildChip(
        context,
        label: l10n.modeCimbar,
        semanticLabel: l10n.modeCimbar,
        icon: Icons.palette_outlined,
        selected: algorithm == TransferAlgorithm.cimbar,
        onSelected: onCimbarSelected,
        key: ValueKey<String>('$keyPrefix-cimbar'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            l10n.transferModeLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: dense ? 6 : 10),
        ],
        Wrap(
          spacing: dense ? 6 : 8,
          runSpacing: dense ? 6 : 8,
          children: chips,
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required String semanticLabel,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
    required Key key,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      child: ChoiceChip(
        key: key,
        label: Text(label),
        avatar: Icon(icon, size: dense ? 16 : 18),
        selected: selected,
        onSelected: enabled ? (_) => onSelected() : null,
        selectedColor: oneSendLime,
        side: const BorderSide(color: oneSendInk, width: 1.5),
        labelStyle: TextStyle(
          color: oneSendInk,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
        visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 6),
      ),
    );
  }

  String _modeLabel(AppLocalizations l10n, TransferMode mode) {
    return switch (mode) {
      TransferMode.reliable => l10n.modeReliable,
      TransferMode.fast => l10n.modeFast,
      TransferMode.turbo => l10n.modeTurboQr,
    };
  }
}
