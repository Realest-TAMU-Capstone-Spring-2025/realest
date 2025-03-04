import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedProperties extends StatelessWidget {
  const SavedProperties({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Properties')),
        body: Center(child: const Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Properties')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('saved')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text(doc['address']),
                subtitle: Text('\$${doc['price']}'),
                leading: Image.network(doc['primaryPhoto']),
              );
            },
          );
        },
      ),
    );
  }
}