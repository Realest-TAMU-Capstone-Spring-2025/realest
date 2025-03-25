import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../properties/properties_view.dart';

class PropertySwipingView extends StatefulWidget {
  const PropertySwipingView({super.key});

  @override
  _PropertySwipingViewState createState() => _PropertySwipingViewState();
}

class _PropertySwipingViewState extends State<PropertySwipingView> {
  final CardSwiperController _controller = CardSwiperController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Property> _properties = [];
  List<Property> _swipedProperties = [];
  bool _noMoreProperties = false;
  bool _noRealtorAssigned = false;
  bool _useRealtorDecisions = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _properties = [];
      _noMoreProperties = false;
    });

    if (_useRealtorDecisions) {
      await _loadRealtorProperties();
    } else {
      await _loadNormalProperties();
    }
  }
  Future<void> _loadRealtorProperties() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _noMoreProperties = true;
      });
      return;
    }

    try {
      // Get investor's realtor ID
      final investorDoc = await _db.collection('investors').doc(userId).get();
      if(investorDoc.data() == null) {
        setState(() {
          _noMoreProperties = true;
          _noRealtorAssigned = true;
        });
        return;
      }
      final realtorId = investorDoc.data()?['realtorId'] as String?;
      if (realtorId == null) {
        setState(() {
          _noMoreProperties = true;
          _noRealtorAssigned = true;
        });
        return;
      }

      final userLikedPropertiesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('decisions')
          .where('liked', isEqualTo: true)
          .get();

      final userLikedPropertyIds = userLikedPropertiesSnapshot.docs.map((doc) => doc.id).toSet();

      // Get realtor's decisions
      final decisionsSnapshot = await _db
          .collection('users')
          .doc(realtorId)
          .collection('decisions')
          .where('liked', isEqualTo: true)
          .get();

      final propertyIds = decisionsSnapshot.docs
          .map((doc) => doc.id)
          .where((id) => !userLikedPropertyIds.contains(id))
          .toList();

      if (propertyIds.isEmpty) {
        setState(() {
          _noMoreProperties = true;
        });
        return;
      }

      // Fetch properties based on filtered realtor's decisions
      final propertiesSnapshot = await _db
          .collection('listings')
          .where(FieldPath.documentId, whereIn: propertyIds)
          .get();

      setState(() {
        _properties = propertiesSnapshot.docs
            .map((doc) => Property.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error loading realtor properties: $e');
      setState(() {
        _noMoreProperties = true;
      });
    }
  }


  Future<void> _loadNormalProperties() async {
    try {
      final snapshot = await _db
          .collection('listings')
          .where('status', isEqualTo: 'FOR_SALE')
          .limit(20)
          .get();

      if (mounted) {
        setState(() {
          _properties =
              snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _properties = [];
        });
      }
      debugPrint('Error loading properties: $e');
    }
  }

  void _showSwipeAnimation(CardSwiperDirection direction) {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    final bool isRightSwipe = direction == CardSwiperDirection.right;
    final double startX = isRightSwipe
        ? screenSize.width * 0.75
        : screenSize.width * 0.15; // Start from the side
    final double startY = screenSize.height * 0.8; // Start from the bottom area

    final overlayEntry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 700),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            return Positioned(
              left: startX,
              top: startY - (value * 100), // Move up by 100 pixels
              child: Transform.scale(
                scale: value < 0.7
                    ? value * 1.5
                    : (1.5 - (value - 0.7) * 4), // Bubble up and explode
                child: AnimatedOpacity(
                  opacity: value < 0.8
                      ? 1
                      : (1 - (value - 0.8) * 5), // Fade out at the end
                  duration: const Duration(milliseconds: 200),
                  child: isRightSwipe
                      ? const Icon(Icons.favorite,
                          color: Colors.red,
                          size: 100) // ❤️ Heart for right swipe
                      : Image.network(
                          'https://emojicdn.elk.sh/🙅‍♂️', //there were issues with the background of certain emojis
                          width: 80,
                          height: 80,
                        ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 700), () {
      overlayEntry.remove();
    });
  }

  Future<bool> _handleSwipe(int previousIndex, int? currentIndex,
      CardSwiperDirection direction) async {
    final property = _properties[previousIndex];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return false;

    final isLiked = direction == CardSwiperDirection.right;

    if (isLiked || await _wasPropertyPreviouslyLiked(property.id)) {
      // Save swipe decision to Firestore only if it's a like or if it's undoing a previous like
      _db
          .collection('users')
          .doc(userId)
          .collection('decisions')
          .doc(property.id)
          .set({
        'liked': isLiked,
        'timestamp': FieldValue.serverTimestamp(),
        'propertyId': property.id,
      });
    }

    if (mounted) {
      setState(() {
        _swipedProperties.add(property);
      });
    }

    _showSwipeAnimation(direction);

    return true;
  }

  Future<bool> _wasPropertyPreviouslyLiked(String propertyId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('decisions')
        .doc(propertyId)
        .get();
    return doc.exists && doc.data()?['liked'] == true;
  }

  Future<bool> _handleUndo() async {
    if (_swipedProperties.isEmpty) return false;

    final lastProperty = _swipedProperties.removeLast();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final docRef = _db
          .collection('users')
          .doc(userId)
          .collection('decisions')
          .doc(lastProperty.id);
      final doc = await docRef.get();

      if (doc.exists && doc.data()?['liked'] == true) {
        await docRef.delete();
      }
    }

    if (mounted) {
      setState(() {
        _properties.insert(0, lastProperty);
        _noMoreProperties = false;
      });
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
        // title: const Text('Swipe Properties'),
        leading: IconButton(
          icon: Icon(_useRealtorDecisions ? Icons.real_estate_agent_outlined : Icons.public),
          onPressed: () {
            setState(() {
              _useRealtorDecisions = !_useRealtorDecisions;
               _properties = []; // Clear properties
              _noMoreProperties = false; // Reset noMoreProperties state
            });
            _loadProperties();
          },
          tooltip: _useRealtorDecisions ? 'Using Realtor Decisions' : 'Using All Properties',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Swipe right to like a property, swipe left to dislike a property. \n\n'
                            'You can undo your last swipe by pressing the undo button. \n\n'
                            'If you swipe through all the properties, you can reload the properties by pressing the reload button. \n\n'
                            'Tap on a property to view more details.',
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _swipedProperties.isNotEmpty
                ? () async {
                    final success = await _handleUndo();
                    if (success) {
                      setState(() {
                        _noMoreProperties = false;
                      });
                    }
                  }
                : null,
          )
        ],
      ),
      body: _properties.isEmpty
    ? Center(
        child: _noMoreProperties
            ? (_noRealtorAssigned && _useRealtorDecisions
                ? Text('No realtor assigned. Please contact support.')
                : Text('No more properties available.'))
            : CircularProgressIndicator(),
      )
    : CardSwiper(
        controller: _controller,
        cardsCount: _properties.length,
        numberOfCardsDisplayed: (_properties.length >= 2) ? 2 : 1, // Ensure valid card count
        backCardOffset: const Offset(0, 40),
        scale: 0.9,
        padding: const EdgeInsets.all(24),
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
    String imageUrl = (property.primaryPhoto != null)
        ? "${property.primaryPhoto}"
        : 'https://via.placeholder.com/150';

    return GestureDetector(
        onTap: () => _navigateToPropertyView(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
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
                    _buildDetailRow(
                        '${property.fullBaths ?? 0} baths', Icons.bathtub),
                    _buildDetailRow(
                        '${property.sqft ?? 0} sqft', Icons.square_foot),
                    _buildDetailRow(
                        '\$${property.listPrice?.toStringAsFixed(2) ?? 'N/A'}',
                        Icons.attach_money),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  void _navigateToPropertyView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertiesView(
          propertyId: property.id,
          showSaveIcon: false,
        ),
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
