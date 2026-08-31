import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String planName;
  final int amount;
  final String billingCycle;
  final String planId;

  const PaymentScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.billingCycle,
    required this.planId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMethod = 'Card'; // Default: Card, JazzCash, EasyPaisa, Bank
  bool _isLoading = false;

  // Controllers for Card Payment
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  // Gateway Simulation & Firestore Subscription Handler
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Simulate Payment Gateway Processing API Delay
      await Future.delayed(const Duration(seconds: 2));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. Calculate Expiry Date (Monthly / Yearly)
        final DateTime now = DateTime.now();
        final DateTime expiryDate = widget.billingCycle == "Yearly"
            ? DateTime(now.year + 1, now.month, now.day)
            : DateTime(now.year, now.month + 1, now.day);

        // 3. Save Transaction Log to Firestore
        final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
        await transactionRef.set({
          'transactionId': transactionRef.id,
          'userId': user.uid,
          'planId': widget.planId,
          'planName': widget.planName,
          'amount': widget.amount,
          'billingCycle': widget.billingCycle,
          'paymentMethod': _selectedMethod,
          'status': 'SUCCESS',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Upgrade User Plan in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isPremium': true,
          'subscriptionPlan': widget.planName,
          'planId': widget.planId,
          'subscriptionExpiry': expiryDate.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 5. Show Success Dialog
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment Failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Payment Successful! 🎉",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "You are now subscribed to ${widget.planName} Plan (${widget.billingCycle}).",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6A1B9A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // Dismiss Dialog
              Navigator.pop(context); // Return to Screen
            },
            child: const Text("Done", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F5F9),
      appBar: AppBar(
        title: const Text('Checkout & Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff4A148C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xff8E24AA), Color(0xff4A148C)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.planName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("${widget.billingCycle}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const Divider(color: Colors.white30, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Payable Amount:", style: TextStyle(color: Colors.white70)),
                        Text("PKR ${widget.amount}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("Select Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Payment Gateway Selectors
              Row(
                children: [
                  _buildMethodTile("Card", Icons.credit_card_rounded),
                  const SizedBox(width: 8),
                  _buildMethodTile("JazzCash", Icons.account_balance_wallet_rounded),
                  const SizedBox(width: 8),
                  _buildMethodTile("EasyPaisa", Icons.account_balance_wallet_outlined),
                ],
              ),
              const SizedBox(height: 24),

              // Input Fields Dynamic based on selected Gateway
              if (_selectedMethod == 'Card') ...[
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration("Card Number", Icons.credit_card),
                  validator: (val) => val == null || val.length < 16 ? "Enter valid 16-digit card number" : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: _buildInputDecoration("MM/YY", Icons.date_range),
                        validator: (val) => val == null || val.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration("CVV", Icons.lock),
                        validator: (val) => val == null || val.length < 3 ? "Invalid CVV" : null,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration("$_selectedMethod Mobile Number", Icons.phone_android),
                  validator: (val) => val == null || val.length < 11 ? "Enter valid 11-digit mobile number" : null,
                ),
              ],

              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff6A1B9A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _processPayment,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Pay PKR ${widget.amount} Now",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTile(String method, IconData icon) {
    bool isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff6A1B9A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xff6A1B9A) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade700, size: 22),
              const SizedBox(height: 4),
              Text(
                method,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff6A1B9A)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff6A1B9A), width: 2)),
    );
  }
}