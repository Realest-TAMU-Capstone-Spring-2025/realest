import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'investor_home_screen.dart';

class EnterInvitationCodeScreen extends StatefulWidget {
  const EnterInvitationCodeScreen({Key? key}) : super(key: key);

  @override
  _EnterInvitationCodeScreenState createState() => _EnterInvitationCodeScreenState();
}

class _EnterInvitationCodeScreenState extends State<EnterInvitationCodeScreen> {
  bool _isLoading = false;

  void _onCodeCompleted(String code) {
    // For now, ignore the code and redirect to HomeScreen.
    Navigator.pushReplacementNamed(context, '/investorHome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Display the logo
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 60),
              Text(
                'Invitation Code',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                'Enter the invitation code sent by your realtor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Segmented invitation code input
              InvitationCodeInput(
                length: 6, // Change the length as needed
                onCompleted: _onCodeCompleted,
              ),
              const SizedBox(height: 20),
              // Optional: a submit button if you want to trigger navigation manually
              ElevatedButton(
                onPressed: () {
                  // In this example, we rely on the segmented input's completion.
                  // But you can also add manual submission logic here.
                  Navigator.pushReplacementNamed(context, '/investorHome');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF212834),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom widget that creates a segmented input for a code.
/// Each box accepts one digit. When all boxes are filled,
/// the complete code is sent to the [onCompleted] callback.
class InvitationCodeInput extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;

  const InvitationCodeInput({
    Key? key,
    required this.length,
    required this.onCompleted,
  }) : super(key: key);

  @override
  _InvitationCodeInputState createState() => _InvitationCodeInputState();
}

class _InvitationCodeInputState extends State<InvitationCodeInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    String code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length && !code.contains('')) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 50,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < widget.length - 1) {
                  _focusNodes[index].unfocus();
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                }
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }
              _onChanged();
            },
          ),
        );
      }),
    );
  }
}
