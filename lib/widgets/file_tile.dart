import 'package:flutter/material.dart';

import '../app.dart';
import '../services/file_service.dart';

class FileTile extends StatelessWidget {
  const FileTile({
    required this.name,
    required this.bytes,
    this.subtitle,
    this.icon = Icons.insert_drive_file_outlined,
    super.key,
  });

  final String name;
  final int bytes;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: oneSendLime.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(15),
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
              const SizedBox(height: 3),
              Text(
                subtitle ?? formatBytes(bytes),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (subtitle == null) ...[
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
      ],
    );
  }
}
