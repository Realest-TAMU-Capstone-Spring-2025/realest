import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:realest/src/views/realtor/widgets/property_card/cashflow_badge.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_sheet.dart';

import '../../../../util/property_fetch_helpers.dart';

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
  bool _noRealtorAssigned = true;
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
      //grab collection from investors, grab the document by userid, and then grab the collection of recommended properties from that document
      final snapshot = await _db
          .collection('investors')
          .doc(userId)
          .collection('recommended_properties')
          .limit(20)
          .get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _noMoreProperties = true;
          _noRealtorAssigned = true; // No realtor assigned
        });
        return;
      }
      //for each document in the snapshot, get the property id and then get the property from the listings collection
      //need to make a call to the listings collection for each document in the snapshot
      final propertyIds = snapshot.docs.map((doc) => doc['property_id'] as String).toList();
      final propertySnapshots = await Future.wait(propertyIds.map((id) => _db.collection('listings').doc(id).get()));
      if (propertySnapshots.isEmpty) {
        setState(() {
          _noMoreProperties = true;
          _noRealtorAssigned = true; // No realtor assigned
        });
        return;
      }
      
      setState(() {
        _properties = propertySnapshots
            .where((doc) => doc.exists)
            .map((doc) => Property.fromFirestore(doc))
            .toList();
        _noRealtorAssigned = false; // Realtor assigned
        _noMoreProperties = false; // Reset noMoreProperties state
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
          return PropertyCard(property: property, controller: _controller);
        },
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Property property;
  final CardSwiperController controller;

  const PropertyCard({super.key, required this.property, required this.controller});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600; // Define mobile screen size threshold
    return LayoutBuilder(
      builder: (context, constraints) {
        final double imageHeight = constraints.maxHeight * 0.75;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDarkMode ? Colors.black : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image + Address/Price Overlay
              Stack(
                children: [
                  // Your main image or content
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: property.primaryPhoto != null
                          ? (kDebugMode
                          ? 'http://localhost:8080/${property.primaryPhoto}'
                          : property.primaryPhoto!)
                          : 'https://placehold.co/600x400',
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),

                  // Positioned Price
                  Positioned(
                    left: 10,
                    bottom: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        property.listPrice != null
                            ? "\$ ${NumberFormat("#,##0").format(property.listPrice)}"
                            : "N/A",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),

                  // Positioned NOI badge
                  Positioned(
                    right: 10,
                    bottom: 60,
                    child: CashFlowBadge(propertyId: property.id),
                  ),

                  // Address + Price Overlay
                  Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: Colors.black.withOpacity(0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.street ?? "Unknown Address",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Info icon
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Tooltip(
                      message: "Click for more information",
                      child: InkWell(
                        onTap: () => _navigateToPropertyView(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            size: isMobile ? 20 : 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Section (details + buttons)
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    color: isDarkMode ? Colors.black : Colors.white,
                  ),
                  child: Column(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black54.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStat(icon: Icons.king_bed, label: "${property.beds} Beds", theme: theme),
                              _verticalDivider(),
                              _buildStat(
                                icon: Icons.bathtub,
                                label: "${(property.fullBaths! + (property.halfBaths ?? 0) / 2)} Baths",
                                theme: theme,
                              ),
                              _verticalDivider(),
                              _buildStat(
                                icon: Icons.square_foot,
                                label: "${currencyFormat.format(property.sqft)} sqft",
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (!isMobile)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSwipeButton(
                              icon: Icons.thumb_down,
                              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                              tooltip: "Dislike",
                              onPressed: () => controller.swipe(CardSwiperDirection.left),
                              isMobile: isMobile,
                            ),
                            _buildSwipeButton(
                              icon: Icons.favorite,
                              color: isDarkMode ? Colors.red[400]! : Colors.red[200]!,
                              tooltip: "Like",
                              onPressed: () => controller.swipe(CardSwiperDirection.right),
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        );
      },
    );
  }
  Widget _verticalDivider() => Container(
    width: 1,
    height: 20,
    color: Colors.grey[400],
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );
  Widget _buildStat({required IconData icon, required String label, required ThemeData theme}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }


  Widget _buildDetailRow(String leftText, IconData leftIcon, String rightText, IconData rightIcon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left-aligned item
          Row(
            children: [
              Icon(leftIcon, size: 16, color: isDarkMode ? Colors.white : Colors.black),
              const SizedBox(width: 8),
              Text(
                leftText,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Right-aligned item
          Row(
            children: [
              Text(
                rightText,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              Icon(rightIcon, size: 16, color: isDarkMode ? Colors.white : Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Tooltip(
      message: tooltip,
      child: CircleAvatar(
        radius: isMobile ? 20 : 28,
        backgroundColor: color,
        child: IconButton(
          icon: Icon(icon, size: isMobile ? 20 : 24),
          color: Colors.white,
          onPressed: onPressed,
        ),
      ),
    );
  }

  Future<void> _navigateToPropertyView(BuildContext context) async {
    final propertyData = await fetchPropertyData(property.id);
    showModalBottomSheet(
      context: context,
      constraints: BoxConstraints(
        maxWidth:  1000,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropertyDetailSheet(property: propertyData),
      //disable swipe to close
      enableDrag: false,

    );
  }
}

class Property {
  final String id;
  final String? primaryPhoto;
  final double? listPrice;
  final int? beds;
  final int? fullBaths;
  final int? halfBaths;
  final String? street;
  final int? sqft;
  final double? tax;

  Property({
    required this.id,
    this.primaryPhoto,
    this.listPrice,
    this.beds,
    this.fullBaths,
    this.halfBaths,
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
      halfBaths: data['half_baths'] as int?,
      street: data['street'],
      sqft: data['sqft'] as int?,
      tax: (data['tax'] as num?)?.toDouble(),
    );
  }
}
