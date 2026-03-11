import 'package:cloud_firestore/cloud_firestore.dart';

class ComparisonModel {
  final String? id;
  final String item1;
  final String item2;
  final String result;
  final String userId;
  final DateTime createdAt;
  final String? comparisonType;

  ComparisonModel({
    this.id,
    required this.item1,
    required this.item2,
    required this.result,
    required this.userId,
    required this.createdAt,
    this.comparisonType,
  });

  Map<String, dynamic> toMap() {
    return {
      'item1': item1,
      'item2': item2,
      'result': result,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (comparisonType != null) 'comparisonType': comparisonType,
    };
  }

  factory ComparisonModel.fromMap(String id, Map<String, dynamic> map) {
    return ComparisonModel(
      id: id,
      // Geriye dönük uyumluluk: eski 'product1/product2' alanlarını da destekle
      item1: map['item1'] ?? map['product1'] ?? '',
      item2: map['item2'] ?? map['product2'] ?? '',
      result: map['result'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      comparisonType: map['comparisonType'] as String?,
    );
  }
}
