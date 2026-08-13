import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyCertificateScreen extends StatelessWidget {
  final String userId;

  const MyCertificateScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Certificate'), backgroundColor: Colors.purple),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('certificates').where('userId', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Dummy display card for FYP demo if snapshot is empty
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 4),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.amber.shade50,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium, size: 60, color: Colors.amber),
                      const SizedBox(height: 10),
                      const Text('Certificate of Completion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                      const SizedBox(height: 8),
                      const Text('This is to certify that', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('Hira', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('has successfully completed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('Full Stack Web Development Course', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Download Certificate', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloading Certificate PDF...')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, color: Colors.purple),
                        label: const Text('Share', style: TextStyle(color: Colors.purple)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sharing Certificate...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}