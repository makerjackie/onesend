import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TransferDirection { sent, received }

class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.direction,
    required this.fileName,
    required this.bytes,
    required this.createdAt,
    required this.status,
    this.path,
    this.verified = false,
  });

  final String id;
  final TransferDirection direction;
  final String fileName;
  final int bytes;
  final DateTime createdAt;
  final String status;
  final String? path;
  final bool verified;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'direction': direction.name,
    'fileName': fileName,
    'bytes': bytes,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'path': path,
    'verified': verified,
  };

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      direction: json['direction'] == TransferDirection.sent.name
          ? TransferDirection.sent
          : TransferDirection.received,
      fileName: json['fileName'] as String? ?? 'received.bin',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'completed',
      path: json['path'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }
}

/// Local transfer history. Notifies listeners when records change so shell tabs
/// can refresh without a full route rebuild.
class TransferStore extends ChangeNotifier {
  static const _preferenceKey = 'onesend.transfer-history';

  late SharedPreferences _preferences;
  List<TransferRecord> _records = <TransferRecord>[];
  bool _ready = false;

  List<TransferRecord> get records => List.unmodifiable(_records);
  bool get isReady => _ready;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    final values = _preferences.getStringList(_preferenceKey) ?? <String>[];
    _records = <TransferRecord>[];
    for (final value in values) {
      try {
        _records.add(
          TransferRecord.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } catch (_) {
        // Ignore a single corrupt history item rather than blocking the app.
      }
    }
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _ready = true;
    notifyListeners();
  }

  Future<void> add(TransferRecord record) async {
    _records = <TransferRecord>[
      record,
      ..._records,
    ].take(30).toList(growable: false);
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _records = <TransferRecord>[];
    await _preferences.remove(_preferenceKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    await _preferences.setStringList(
      _preferenceKey,
      _records.map((record) => jsonEncode(record.toJson())).toList(),
    );
  }
}
