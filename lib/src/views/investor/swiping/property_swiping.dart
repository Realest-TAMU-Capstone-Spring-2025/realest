import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PropertySwipingView extends StatefulWidget {
  const PropertySwipingView({super.key});

  @override
  _PropertySwipingViewState createState() => _PropertySwipingViewState();
}

class _PropertySwipingViewState extends State<PropertySwipingView> {
  final CardSwiperController _controller = CardSwiperController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Property> _properties = [];
  // ignore: prefer_final_fields
  List<Property> _swipedProperties = [];
  bool _noMoreProperties = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }
  Future<void> _loadProperties() async {
    try {
      final snapshot = await _db.collection('listings')
          .where('status', isEqualTo: 'FOR_SALE')
          .limit(20)
          .get();

      if (mounted) {
      setState(() {
        _properties = snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
      });
    }
    } catch (e) {
      if (mounted) { // Handle errors gracefully
        setState(() {
          _properties = [];
        });
      }
      debugPrint('Error loading properties: $e');
    }
  }

  bool _handleSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final property = _properties[previousIndex];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return false;

    final isLiked = direction == CardSwiperDirection.right;

    // Save swipe decision to Firestore
    _db.collection('users').doc(userId).collection('decisions').doc(property.id).set({
      'liked': isLiked,
      'timestamp': FieldValue.serverTimestamp(),
      'propertyId': property.id,
    });

    if (mounted) {
      setState(() {
        _swipedProperties.add(property);
      });
    }

    return true; // Allow swipe action to proceed
  }



  Future<bool> _handleUndo() async {
    if (_swipedProperties.isEmpty) return false;
    
    final lastProperty = _swipedProperties.removeLast();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId != null) {
      await _db.collection('investors').doc(userId)
        .collection('decisions')
        .doc(lastProperty.id)
        .delete();
    }

    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipe Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () async {
              final success = await _handleUndo();
              if (success) {
                setState(() {
                  _noMoreProperties = false;
                });
              }
            },
          )
        ],
      ),
      body: _properties.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _noMoreProperties
              ? Center(child: Text('No more properties available.'))
              : CardSwiper(
                  controller: _controller,
                  cardsCount: _properties.length,
                  numberOfCardsDisplayed: 2,
                  backCardOffset: Offset(0, 40),
                  scale: 0.9,
                  padding: EdgeInsets.all(24),
                  allowedSwipeDirection: AllowedSwipeDirection.symmetric(
                    horizontal: true,
                    vertical: false,
                  ),
                  onSwipe: _handleSwipe,
                  onEnd: () {
                    setState(() {
                      _noMoreProperties = true;
                    });
                  },
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                    final property = _properties[index];
                    return PropertyCard(property: property);
                  },
                ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({required this.property, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: property.primaryPhoto ?? 'https://via.placeholder.com/150',
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.street ?? 'Unknown Address',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow('${property.beds ?? 0} beds', Icons.bed),
                _buildDetailRow('${property.fullBaths ?? 0} baths', Icons.bathtub),
                _buildDetailRow('${property.sqft ?? 0} sqft', Icons.square_foot),
                _buildDetailRow('\$${property.listPrice?.toStringAsFixed(2) ?? 'N/A'}', Icons.attach_money),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class Property {
  final String id;
  final String? primaryPhoto;
  final double? listPrice;
  final int? beds;
  final int? fullBaths;
  final String? street;
  final int? sqft;
  final double? tax;

  Property({
    required this.id,
    this.primaryPhoto,
    this.listPrice,
    this.beds,
    this.fullBaths,
    this.street,
    this.sqft,
    this.tax,
  });

  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Property(
      id: doc.id,
      primaryPhoto: data['primary_photo'],
      listPrice: (data['list_price'] as num?)?.toDouble(),
      beds: data['beds'] as int?,
      fullBaths: data['full_baths'] as int?,
      street: data['street'],
      sqft: data['sqft'] as int?,
      tax: (data['tax'] as num?)?.toDouble(),
    );
  }
}