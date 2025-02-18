// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(automaticallyImplyLeading: false),
//       body: Center(
//         child: Column(
//           children: [
//             // Image.asset('logo.png'),
//             Text('Welcome to Realest!', style: Theme.of(context).textTheme.displaySmall),
//           //sign out button
//           //floating action button
//           FloatingActionButton(
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut();
//             },
//             child: const Icon(Icons.logout),
//           ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(automaticallyImplyLeading: false),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Image.asset('logo.png'),
//             Text(
//               'Welcome to Realest!',
//               style: Theme.of(context).textTheme.displaySmall,
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomAppBar(
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.archive),
//               onPressed: () {
//                 // Add saved section functionality here
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.logout),
//               onPressed: () async {
//                 await FirebaseAuth.instance.signOut();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isFirstTimeUser = true; // This would be determined dynamically
  int _currentIndex = 0;

  final List<Map<String, String>> _properties = [
    {
      'title': 'Modern Apartment',
      'image': 'https://picsum.photos/300/400',
      'description': 'A modern apartment in the city center with 2 bedrooms and 2 bathrooms.',
    },
    {
      'title': 'Cozy Cottage',
      'image': 'https://picsum.photos/300/400',
      'description': 'A cozy cottage in the countryside with a beautiful garden.',
    },
    {
      'title': 'Luxury Villa',
      'image': 'https://picsum.photos/300/400',
      'description': 'A luxury villa with a private pool and stunning sea views.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Realest'),
      ),
      body: _isFirstTimeUser ? _buildIntroView() : _buildCardSwiper(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildIntroView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to Realest!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isFirstTimeUser = false;
              });
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSwiper() {
    return Column(
      children: [
        SizedBox(
          height: 500,
          child: CardSwiper(
            cardsCount: _properties.length,
            cardBuilder: (context, index, percentX, percentY) {
              return PropertyCard(property: _properties[index]);
            },
            onSwipe: (prevIndex, currIndex, direction) {
              setState(() {
                _currentIndex = currIndex ?? 0;
              });
              return true;
            },
            onEnd: () {
              debugPrint('No more properties to swipe.');
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _properties[_currentIndex]['description']!,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Map<String, String> property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Image.network(
            property['image']!,
            fit: BoxFit.cover,
            height: 350,
            width: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              property['title']!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}