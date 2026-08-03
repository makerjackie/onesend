import 'package:flutter/material.dart';

import '../app.dart';
import '../services/file_service.dart';

class FileTile extends StatelessWidget {
  const FileTile({
    required this.name,
    required this.bytes,
    this.subtitle,
    this.icon = Icons.insert_drive_file_outlined,
    this.onTap,
    super.key,
  });

  final String name;
  final int bytes;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: oneSendLime.withValues(alpha: 0.45),
                border: Border.all(color: oneSendInk, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, color: oneSendInk),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: oneSendInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitleText != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitleText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (subtitleText == null) ...[
              const SizedBox(width: 12),
              Text(
                formatBytes(bytes),
                style: const TextStyle(
                  color: oneSendMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: oneSendMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
