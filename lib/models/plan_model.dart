class PlanModel {
  final String id;
  final String name;
  final int price;
  final String duration;
  final List<String> features;

  PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
  });

  factory PlanModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return PlanModel(
      id: docId,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      duration: data['duration'] ?? '',
      features: List<String>.from(data['features'] ?? []),
    );
  }
}