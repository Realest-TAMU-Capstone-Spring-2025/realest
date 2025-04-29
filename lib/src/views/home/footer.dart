import 'package:flutter/material.dart';

/// A footer widget with branding, quick links, and a newsletter signup form.
class Footer extends StatelessWidget {
  /// Neon purple color used for styling borders and buttons.
  static const Color neonPurple = Color(0xFFD500F9);

  const Footer({super.key});

  /// Builds a text button for footer navigation links.
  ///
  /// [title] The text displayed on the button.
  /// [isMobile] Determines font size for mobile or desktop.
  /// Returns a [Widget] representing the footer link button.
  Widget _footerLink(String title, {required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: TextButton(
        onPressed: () {},
        child: Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 12 : 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determines if the screen is mobile based on width
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Builds the footer with a responsive layout for branding, links, and newsletter
    return Container(
      color: const Color(0xFFa78cde),
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.real_estate_agent,
                  color: Colors.white,
                  size: isMobile ? 40 : 54,
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Text(
                  'RealEst',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Text(
                  '© 2025 RealEst',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Links',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                _footerLink('Overview', isMobile: isMobile),
                _footerLink('Policies', isMobile: isMobile),
                _footerLink('Terms of Use', isMobile: isMobile),
                _footerLink('Contact Us', isMobile: isMobile),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign Up for Newsletter',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 20),
                SizedBox(
                  width: isMobile ? 200 : null,
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12 : 16,
                      ),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: neonPurple),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: neonPurple,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 30,
                        vertical: isMobile ? 5 : 15,
                      ),
                    ),
                    child: Text(
                      'Subscribe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}