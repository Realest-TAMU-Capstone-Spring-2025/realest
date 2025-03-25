import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class EmailService {
  static Future<void> sendInviteEmail(
      String clientEmail,
      String invitationCode,
      BuildContext context,
      ) async {
    final url = Uri.parse('http://localhost:3000/send-email'); // Node.js server URL

    final body = jsonEncode({
      'clientEmail': clientEmail,
      'invitationCode': invitationCode,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 202) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite successfully sent to $clientEmail')),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invite: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invite: $e')),
      );
    }
  }
}