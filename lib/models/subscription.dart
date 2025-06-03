import 'package:appwrite/models.dart';

class Subscription {
  final String id;
  final String userId;
  final String planType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'plan_type': planType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Subscription.fromDocument(Document document) {
    return Subscription(
      id: document.$id,
      userId: document.data['user_id'],
      planType: document.data['plan_type'],
      startDate: DateTime.parse(document.data['start_date']),
      endDate: DateTime.parse(document.data['end_date']),
      isActive: document.data['is_active'] ?? true,
      paymentMethod: document.data['payment_method'],
      createdAt: document.data['created_at'] != null
          ? DateTime.parse(document.data['created_at'])
          : DateTime.parse(document.$createdAt),
      updatedAt: document.data['updated_at'] != null
          ? DateTime.parse(document.data['updated_at'])
          : DateTime.parse(document.$updatedAt),
    );
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map.containsKey('\$id') ? map['\$id'] : map['id'],
      userId: map['user_id'],
      planType: map['plan_type'],
      startDate: map['start_date'] is String
          ? DateTime.parse(map['start_date'])
          : map['start_date'],
      endDate: map['end_date'] is String
          ? DateTime.parse(map['end_date'])
          : map['end_date'],
      isActive: map['is_active'] ?? true,
      paymentMethod: map['payment_method'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : map['created_at'],
      updatedAt: map['updated_at'] is String
          ? DateTime.parse(map['updated_at'])
          : map['updated_at'],
    );
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? planType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Memeriksa apakah langganan masih aktif
  bool get isValid => isActive && endDate.isAfter(DateTime.now());

  /// Menghitung sisa hari langganan
  int get daysRemaining {
    if (!isValid) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }
}
