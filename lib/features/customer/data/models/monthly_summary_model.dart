import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monthly_summary_entity.dart';

/// Data model for monthly summary
class MonthlySummaryModel {
  final String id;
  final String userId;
  final String month;
  final int year;
  final int monthNumber;
  final List<Map<String, dynamic>> categories;
  final double grandTotal;
  final int totalReceipts;
  final int archivedCount;
  final int keptCount;
  final double? budgetLimit;
  final double? budgetDifference;
  final Timestamp createdAt;

  MonthlySummaryModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.monthNumber,
    required this.categories,
    required this.grandTotal,
    required this.totalReceipts,
    required this.archivedCount,
    required this.keptCount,
    this.budgetLimit,
    this.budgetDifference,
    required this.createdAt,
  });

  // From Firestore
  factory MonthlySummaryModel.fromFirestore(
    Map<String, dynamic> json,
    String docId,
  ) {
    final categoriesList =
        (json['categories'] as List<dynamic>?)
            ?.map((item) => item as Map<String, dynamic>)
            .toList() ??
        [];

    return MonthlySummaryModel(
      id: docId,
      userId: json['userId'] as String,
      month: json['month'] as String,
      year: json['year'] as int,
      monthNumber: json['monthNumber'] as int,
      categories: categoriesList,
      grandTotal: (json['grandTotal'] as num).toDouble(),
      totalReceipts: json['totalReceipts'] as int,
      archivedCount: json['archivedCount'] as int,
      keptCount: json['keptCount'] as int,
      budgetLimit: json['budgetLimit'] != null
          ? (json['budgetLimit'] as num).toDouble()
          : null,
      budgetDifference: json['budgetDifference'] != null
          ? (json['budgetDifference'] as num).toDouble()
          : null,
      createdAt: json['createdAt'] as Timestamp,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'month': month,
      'year': year,
      'monthNumber': monthNumber,
      'categories': categories,
      'grandTotal': grandTotal,
      'totalReceipts': totalReceipts,
      'archivedCount': archivedCount,
      'keptCount': keptCount,
      'budgetLimit': budgetLimit,
      'budgetDifference': budgetDifference,
      'createdAt': createdAt,
    };
  }

  // To Entity
  MonthlySummaryEntity toEntity() {
    return MonthlySummaryEntity(
      id: id,
      userId: userId,
      month: month,
      year: year,
      monthNumber: monthNumber,
      categories: categories
          .map((cat) => CategorySummary.fromMap(cat))
          .toList(),
      grandTotal: grandTotal,
      totalReceipts: totalReceipts,
      archivedCount: archivedCount,
      keptCount: keptCount,
      budgetLimit: budgetLimit,
      budgetDifference: budgetDifference,
      createdAt: createdAt.toDate(),
    );
  }

  // From Entity
  factory MonthlySummaryModel.fromEntity(MonthlySummaryEntity entity) {
    return MonthlySummaryModel(
      id: entity.id,
      userId: entity.userId,
      month: entity.month,
      year: entity.year,
      monthNumber: entity.monthNumber,
      categories: entity.categories.map((cat) => cat.toMap()).toList(),
      grandTotal: entity.grandTotal,
      totalReceipts: entity.totalReceipts,
      archivedCount: entity.archivedCount,
      keptCount: entity.keptCount,
      budgetLimit: entity.budgetLimit,
      budgetDifference: entity.budgetDifference,
      createdAt: Timestamp.fromDate(entity.createdAt),
    );
  }
}
