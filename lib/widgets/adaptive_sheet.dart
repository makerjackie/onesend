import 'package:flutter/material.dart';

import '../app.dart';

/// Desktop uses a centered dialog; phones keep the bottom sheet.
///
/// Shared by settings pickers and file-action sheets so Flutter stays close
/// to the website's dense desktop workbench and the mobile touch shell.
Future<T?> showOneSendSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = false,
  double maxDialogWidth = 440,
}) {
  final wide = MediaQuery.sizeOf(context).width >= oneSendWideBreakpoint;
  if (wide) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxDialogWidth),
            child: builder(dialogContext),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: builder,
  );
}
