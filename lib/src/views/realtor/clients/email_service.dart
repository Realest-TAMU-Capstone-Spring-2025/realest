import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class EmailService {
  static Future<void> sendInviteEmail(
      String clientEmail,
      String invitationCode,
      BuildContext context,
      ) async {
    // Use the Vercel production URL instead of localhost
    final url = Uri.parse('https://imap-server-f5z6xeiyv-eshwars-projects-8d469d55.vercel.app/send-email');

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
          SnackBar(content: Text('Failed to send invite: $errorMessage (Status: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invite: $e')),
      );
    }
  }
}