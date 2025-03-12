import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

// email_service.dart
class EmailService {
  static const String sendGridApiKey = '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';
  static const String senderEmail = 'eshwarreddygadi@gmail.com';

  static Future<void> sendInviteEmail(
      String clientEmail,
      String invitationCode,
      BuildContext context,
      ) async {
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');

    final body = jsonEncode({
      'personalizations': [
        {
          'to': [
            {'email': clientEmail}
          ]
        }
      ],
      'from': {'email': senderEmail, 'name': 'Realtor App'},
      'subject': 'Invitation to Join Realtor App',
      'content': [
        {
          'type': 'text/plain',
          'value': '''
Dear Client,

You have been invited to join the Realtor App! Please follow these steps to get started:

1. Download and install the Realtor App from the Google Play Store or Apple App Store.
2. Create an account using your email address.
3. Enter the following invitation code to log in and access all features:

Invitation Code: $invitationCode

We look forward to having you on board!

Best regards,
The Realtor App Team
'''
        }
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 202) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite successfully sent to $clientEmail')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invite: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invite: $e')),
      );
    }
  }
}