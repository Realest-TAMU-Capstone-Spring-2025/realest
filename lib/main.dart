import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate Tinder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Map<String, String>> _properties = [
    {
      'title': 'Modern Apartment',
      'image': 'https://picsum.photos/200/300',
      'description': 'A modern apartment in the city center with 2 bedrooms and 2 bathrooms.',
    },
    {
      'title': 'Cozy Cottage',
      'image': 'https://picsum.photos/200/300',
      'description': 'A cozy cottage in the countryside with a beautiful garden.',
    },
    {
      'title': 'Luxury Villa',
      'image': 'https://picsum.photos/200/300',
      'description': 'A luxury villa with a private pool and stunning sea views.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Estate Listings'),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 400,
            child: CardSwiper(
              cardsCount: _properties.length,
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                return Card(
                  child: Column(
                    children: [
                      Image.asset(
                        _properties[index]['image']!,
                        fit: BoxFit.cover,
                        height: 300,
                        width: double.infinity,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _properties[index]['title']!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true, vertical: false),
              onSwipe: (previousIndex, currentIndex, direction) {
                setState(() {
                  _currentIndex = currentIndex ?? 0;
                });
                return true;
              },
              onEnd: () {
                debugPrint('No more cards to swipe.');
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
      ),
    );
  }
}
