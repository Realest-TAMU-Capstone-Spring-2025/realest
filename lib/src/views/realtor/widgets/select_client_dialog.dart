import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectClientDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final realtorId = FirebaseAuth.instance.currentUser?.uid;

    return AlertDialog(
      title: const Text('Select Client'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(realtorId)
              .collection('clients')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final clients = snapshot.data!.docs;

            if (clients.isEmpty) {
              return const Text("No clients available.");
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: clients.length,
              itemBuilder: (_, index) {
                final client = clients[index];
                return ListTile(
                  title: Text(client['name'] ?? 'Unnamed Client'),
                  subtitle: Text(client['email']),
                  onTap: () {
                    Navigator.of(context).pop(client.id);
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
