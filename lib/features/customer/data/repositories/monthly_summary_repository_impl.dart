import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/monthly_summary_entity.dart';
import '../../domain/repositories/monthly_summary_repository.dart';
import '../models/monthly_summary_model.dart';

/// Implementation of MonthlySummaryRepository
class MonthlySummaryRepositoryImpl implements MonthlySummaryRepository {
  final FirebaseFirestore _firestore;

  MonthlySummaryRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<MonthlySummaryEntity>> getAllSummaries() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('monthly_summaries')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('year', descending: true)
          .orderBy('monthNumber', descending: true)
          .get();

      final summaries = snapshot.docs
          .map(
            (doc) => MonthlySummaryModel.fromFirestore(
              doc.data(),
              doc.id,
            ).toEntity(),
          )
          .toList();

      debugPrint('✅ Found ${summaries.length} monthly summaries');
      return summaries;
    } catch (e) {
      debugPrint('❌ Error getting summaries: $e');
      throw Exception('Failed to get summaries: $e');
    }
  }

  @override
  Future<MonthlySummaryEntity?> getSummaryByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final monthStr = '$year-${month.toString().padLeft(2, '0')}';

      final snapshot = await _firestore
          .collection('monthly_summaries')
          .where('userId', isEqualTo: currentUser.uid)
          .where('month', isEqualTo: monthStr)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return MonthlySummaryModel.fromFirestore(doc.data(), doc.id).toEntity();
    } catch (e) {
      debugPrint('❌ Error getting summary for $year-$month: $e');
      throw Exception('Failed to get summary: $e');
    }
  }

  @override
  Future<void> createSummary(MonthlySummaryEntity summary) async {
    try {
      debugPrint('📊 Creating monthly summary for ${summary.month}');

      final model = MonthlySummaryModel.fromEntity(summary);

      await _firestore
          .collection('monthly_summaries')
          .doc(summary.id)
          .set(model.toFirestore());

      debugPrint('✅ Monthly summary created successfully');
    } catch (e) {
      debugPrint('❌ Error creating summary: $e');
      throw Exception('Failed to create summary: $e');
    }
  }

  @override
  Future<void> deleteSummary(String summaryId) async {
    try {
      await _firestore.collection('monthly_summaries').doc(summaryId).delete();
      debugPrint('✅ Deleted summary: $summaryId');
    } catch (e) {
      debugPrint('❌ Error deleting summary: $e');
      throw Exception('Failed to delete summary: $e');
    }
  }

  @override
  Future<bool> isMonthArchived({required int year, required int month}) async {
    final summary = await getSummaryByMonth(year: year, month: month);
    return summary != null;
  }
}
