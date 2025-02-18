import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';


class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFf2f6fc),
      // appBar: AppBar(
      //   title: Text('Select Your Role'),
      // ),
      body: Stack(

        children: [
          Positioned(
            left: screenWidth * 0.03, // 20% from the left
            top: screenHeight * 0.05, // 10% from the top
            child: Image.asset(
              'assets/images/logo.png',
              width: 50,
              height: 50,
            ),
          ),
          // Custom position for the text
          Positioned(
              left: screenWidth * 0.08, // 10% from the right
              bottom: screenHeight * 0.50, // 50% from the top,
              child: Lottie.asset('assets/lottie/building.json',
                width: 350,
                height: 400,
              )
          ),
          Positioned(
            left: screenWidth * 0.065, // 10% from the left
            top: screenHeight * 0.4, // 35% from the top
            child: Text(
                'Welcome to RealEst',
                style: GoogleFonts.roboto(fontSize: 40, fontWeight: FontWeight.bold)
            ),
          ),
          Positioned(
            left: screenWidth * 0.15, // 10% from the left
            top: screenHeight * 0.45, // 35% from the top
            child: Text(
              'Are you a Realtor or Investor?',
              style: GoogleFonts.roboto(fontSize: 22,color: Colors.grey)
            ),
          ),
          // Custom position for the Realtor button
          Positioned(
            left: screenWidth * 0.1,// 10% from the left
            top: screenHeight * 0.65, // 50% from the top
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/realtorLogin');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey, // Background color
                foregroundColor: Colors.white, // Text color
                padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                textStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text('Realtor'),
            )
          ),
          // Custom position for the Investor button
          Positioned(
            left: screenWidth * 0.1, // 10% from the right
            top: screenHeight * 0.75, // 50% from the top
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/investorLogin');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey, // Background color
                foregroundColor: Colors.white, // Text color
                padding: EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                textStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text('Investor'),
            ),
          ),
        ],
      ),
    );
  }
}
