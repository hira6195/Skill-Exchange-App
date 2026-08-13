import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'premium_dashboard_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String planName;
  final int amount;

  const PaymentScreen({Key? key, required this.planName, required this.amount}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = 'Credit/Debit Card';
  bool isLoading = false;

  Future<void> _processPayment() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 1. Save payment entry
      await FirebaseFirestore.instance.collection('payments').add({
        'uid': user.uid,
        'amount': widget.amount,
        'plan': widget.planName,
        'method': selectedMethod,
        'status': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update user premium status
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isPremium': true,
        'subscriptionPlan': widget.planName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() => isLoading = false);

    // 3. Navigate to Premium Dashboard
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PremiumDashboardScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details'), backgroundColor: Colors.purple),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Selected Plan:'),
                        Text(widget.planName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:'),
                        Text('PKR ${widget.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Methods
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            RadioListTile(
              title: const Text('Credit/Debit Card'),
              value: 'Credit/Debit Card',
              groupValue: selectedMethod,
              onChanged: (val) => setState(() => selectedMethod = val.toString()),
            ),
            RadioListTile(
              title: const Text('PayPal'),
              value: 'PayPal',
              groupValue: selectedMethod,
              onChanged: (val) => setState(() => selectedMethod = val.toString()),
            ),
            RadioListTile(
              title: const Text('JazzCash / EasyPaisa'),
              value: 'JazzCash/EasyPaisa',
              groupValue: selectedMethod,
              onChanged: (val) => setState(() => selectedMethod = val.toString()),
            ),
            const Spacer(),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: isLoading ? null : _processPayment,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Pay PKR ${widget.amount} Securely', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}