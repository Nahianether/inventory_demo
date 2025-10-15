import 'dart:convert';
import 'package:hive/hive.dart';

part 'sync_operation.g.dart';

/// Represents an operation that needs to be synced with the server
@HiveType(typeId: 4)
class SyncOperation extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String type; // 'create_product', 'update_product', 'delete_product', 'adjust_stock', etc.

  @HiveField(2)
  late String dataJson; // The operation data as JSON string

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late String status; // 'pending', 'syncing', 'failed', 'completed'

  @HiveField(5)
  late String? errorMessage;

  @HiveField(6)
  late int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.dataJson,
    required this.createdAt,
    this.status = 'pending',
    this.errorMessage,
    this.retryCount = 0,
  });

  // Factory constructor for easier creation with Map data
  factory SyncOperation.fromData({
    required String id,
    required String type,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    String status = 'pending',
    String? errorMessage,
    int retryCount = 0,
  }) {
    return SyncOperation(
      id: id,
      type: type,
      dataJson: jsonEncode(data),
      createdAt: createdAt,
      status: status,
      errorMessage: errorMessage,
      retryCount: retryCount,
    );
  }

  // Getter to convert JSON string back to Map
  Map<String, dynamic> get data => jsonDecode(dataJson) as Map<String, dynamic>;

  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCompleted => status == 'completed';
  bool get isSyncing => status == 'syncing';

  SyncOperation copyWith({
    String? status,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncOperation(
      id: id,
      type: type,
      dataJson: dataJson,
      createdAt: createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  String toString() {
    return 'SyncOperation(id: $id, type: $type, status: $status, retryCount: $retryCount)';
  }
}
