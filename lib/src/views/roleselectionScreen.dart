import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Role'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              'Are you a Realtor or Investor?',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Realtor login screen.
                Navigator.pushReplacementNamed(context, '/realtorLogin');
              },
              child: Text('Realtor'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Investor login screen.
                Navigator.pushReplacementNamed(context, '/investorLogin');
              },
              child: Text('Investor'),
            ),
          ],
        ),
      ),
    );
  }
}
