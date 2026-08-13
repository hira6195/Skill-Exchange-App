import 'package:flutter/material.dart';
import 'package:skill_exchange/models/plan_model.dart';
import 'package:skill_exchange/services/plan_service.dart';
import 'payment_screen.dart';

class PricingPlansScreen extends StatefulWidget {
  const PricingPlansScreen({super.key});

  @override
  State<PricingPlansScreen> createState() => _PricingPlansScreenState();
}

class _PricingPlansScreenState extends State<PricingPlansScreen> {
  final PlanService _planService = PlanService();
  bool isYearly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Premium Plan'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle Switch: Monthly vs Yearly
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: isYearly,
                  // FIX 1: 'activeColor' deprecation resolved using modern parameters
                  activeThumbColor: Colors.purple,
                  activeTrackColor: Colors.purple.shade200,
                  onChanged: (val) {
                    setState(() {
                      isYearly = val;
                    });
                  },
                ),
                const Text('Yearly (Save 20%)', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            // Firestore Dynamic Plans Stream/Future
            FutureBuilder<List<PlanModel>>(
              future: _planService.fetchPlans(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading plans: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No plans found'));
                }

                final plans = snapshot.data!;
                return Column(
                  children: plans.map((plan) {
                    final int price = isYearly
                        ? (plan.price * 12 * 0.8).round()
                        : plan.price.round();
                    final isPopular = plan.id == 'pro';

                    return Card(
                      elevation: isPopular ? 6 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isPopular
                            ? const BorderSide(color: Colors.purple, width: 2)
                            : BorderSide.none,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPopular)
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Most Popular',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            Text(
                              plan.name.toUpperCase(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'PKR $price / ${isYearly ? "Year" : "Month"}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 24),
                            ...plan.features.map((feature) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(feature)),
                                ],
                              ),
                            )),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPopular ? Colors.purple : Colors.grey[800],
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        planName: plan.name,
                                        // FIX 2: Passed int instead of double
                                        amount: price,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Choose Plan', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}