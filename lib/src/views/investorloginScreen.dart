import 'package:flutter/material.dart';

class InvestorLoginScreen extends StatefulWidget {
  @override
  _InvestorLoginScreenState createState() => _InvestorLoginScreenState();
}

class _InvestorLoginScreenState extends State<InvestorLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    // Implement login logic here.
    // After successful login, navigate to the Investor Home Screen.
    Navigator.pushReplacementNamed(context, '/investor');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Investor Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
