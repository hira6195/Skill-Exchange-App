import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_model.dart';

class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<PlanModel>> fetchPlans() async {
    final snapshot = await _db.collection('plans').get();
    return snapshot.docs
        .map((doc) => PlanModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}