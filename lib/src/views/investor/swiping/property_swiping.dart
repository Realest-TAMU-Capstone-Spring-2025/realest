import 'dart:async';
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
  DateTime? _cardViewStartTime;
  String? _currentPropertyId;
  Timer? _longActivityTimer;
  final int _longActivityThreshold = 50;
  bool _noMoreProperties = false;
  bool _noRealtorAssigned = true;
  bool _useRealtorDecisions = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }
  void _startCardViewTracking(String propertyId) {
    _cardViewStartTime = DateTime.now();
    _currentPropertyId = propertyId;
  }

  Future<void> _checkAndRecordLongActivity() async {
    if (_cardViewStartTime == null || _currentPropertyId == null) return;

    final duration = DateTime.now().difference(_cardViewStartTime!);
    if (duration.inSeconds < _longActivityThreshold) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final investorDoc = await _db.collection('investors').doc(userId).get();
      final realtorId = investorDoc.data()?['realtorId'] as String?;
      if (realtorId == null) return;

      await _db
          .collection('realtors')
          .doc(realtorId)
          .collection('long_activity')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'propertyId': _currentPropertyId,
        'clientId': userId,
        'duration': duration.inSeconds,
      });
    } catch (e) {
      print('Error recording long activity: $e');
    }
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
        _noRealtorAssigned = false;
      });
      return;
    }

    try {
      final investorDoc = await _db.collection('investors').doc(userId).get();
      final realtorId = investorDoc.data()?['realtorId'] as String?;

      if (realtorId == null) {
        setState(() {
          _noRealtorAssigned = true;
          _noMoreProperties = true;
        });
        return;
      }

      final interactionsRef = _db
          .collection('investors')
          .doc(userId)
          .collection('property_interactions');

      final likedDislikedSnapshot = await interactionsRef
          .where('status', whereIn: ['liked', 'disliked']).get();
      final excludedIds = likedDislikedSnapshot.docs
          .map((doc) => doc['propertyId'] as String)
          .toSet();

      // Try loading sent properties first
      final sentSnapshot =
          await interactionsRef.where('status', isEqualTo: 'sent').get();
      List<String> propertyIds = sentSnapshot.docs
          .where((doc) => !excludedIds.contains(doc['propertyId']))
          .map((doc) => doc['propertyId'] as String)
          .toList();

      if (propertyIds.isEmpty) {
        setState(() {
          _noMoreProperties = true;
          _noRealtorAssigned = false;
        });
        return;
      }

      final propertySnapshots = await Future.wait(
        propertyIds.map((id) => _db.collection('listings').doc(id).get()),
      );

      final properties = propertySnapshots
          .where((doc) => doc.exists)
          .map((doc) => Property.fromFirestore(doc))
          .toList();

      setState(() {
        _properties = properties;
        _noRealtorAssigned = false;
        _noMoreProperties = false;
      });
    } catch (e) {
      print('Error loading realtor properties: $e');
      setState(() {
        _noMoreProperties = true;
        _noRealtorAssigned = false;
      });
    }
  }

  Future<void> _loadNormalProperties() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Step 1: Fetch excluded property IDs from interactions
      final interactionsSnapshot = await _db
          .collection('investors')
          .doc(userId)
          .collection('property_interactions')
          .where('status', whereIn: ['liked', 'disliked', 'sent']).get();

      final excludedIds = interactionsSnapshot.docs
          .map((doc) => doc['propertyId'] as String)
          .toSet();

      // Step 2: Fetch recommended properties
      final listingsSnapshot = await _db
          .collection('listings')
          .where('status', isEqualTo: 'FOR_SALE')
          .limit(50) // fetch more since you'll filter some out
          .get();

      final allProperties = listingsSnapshot.docs
          .where((doc) => !excludedIds.contains(doc.id)) // filter out excluded
          .map((doc) => Property.fromFirestore(doc))
          .toList();

      setState(() {
        _properties = allProperties;
        _noMoreProperties = allProperties.isEmpty;
      });
    } catch (e) {
      debugPrint('Error loading recommended properties: $e');
      setState(() {
        _properties = [];
        _noMoreProperties = true;
      });
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
    await _checkAndRecordLongActivity();

    final property = _properties[previousIndex];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return false;

    if (currentIndex != null && currentIndex < _properties.length) {
      _startCardViewTracking(_properties[currentIndex].id);
    } else {
      _cardViewStartTime = null;
      _currentPropertyId = null;
    }

    final isLiked = direction == CardSwiperDirection.right;

    final investorDoc = await _db.collection('investors').doc(userId).get();
    final realtorId = investorDoc.data()?['realtorId'] as String?;
    if (realtorId != null) {
      final investorRef = _db
          .collection('investors')
          .doc(userId)
          .collection('property_interactions')
          .doc(property.id);

      final realtorRef = _db
          .collection('realtors')
          .doc(realtorId)
          .collection('interactions')
          .doc('${property.id}_$userId');

      final data = {
        'propertyId': property.id,
        'investorId': userId,
        'realtorId': realtorId,
        'status': isLiked ? 'liked' : 'disliked',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await Future.wait([
        investorRef.set(data),
        realtorRef.set(data),
      ]);
    }

    if (mounted) {
      setState(() {
        _swipedProperties.add(property);
        _properties.removeAt(previousIndex); // ✅ Remove swiped property
        if (_properties.isEmpty) {
          _noMoreProperties = true;
        }
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

  // Future<bool> _handleUndo() async {
  //   if (_swipedProperties.isEmpty) return false;
  //
  //   final last = _swipedProperties.removeLast();
  //   final Property lastProperty = last['property'];
  //   final bool fromRealtor = last['fromRealtor'] == true;
  //
  //
  //   final userId = FirebaseAuth.instance.currentUser?.uid;
  //   if (userId == null) return false;
  //
  //   try {
  //     final investorRef = _db
  //         .collection('investors')
  //         .doc(userId)
  //         .collection('property_interactions')
  //         .doc(lastProperty.id);
  //
  //     final investorDoc = await _db.collection('investors').doc(userId).get();
  //     final realtorId = investorDoc.data()?['realtorId'] as String?;
  //
  //     final batch = _db.batch();
  //
  //     if (fromRealtor) {
  //       // Restore status to "sent"
  //       batch.set(investorRef, {
  //         'propertyId': lastProperty.id,
  //         'investorId': userId,
  //         'status': 'sent',
  //         'timestamp': FieldValue.serverTimestamp(),
  //       });
  //
  //       if (realtorId != null) {
  //         final realtorRef = _db
  //             .collection('realtors')
  //             .doc(realtorId)
  //             .collection('interactions')
  //             .doc('${lastProperty.id}_$userId');
  //
  //         batch.set(realtorRef, {
  //           'propertyId': lastProperty.id,
  //           'investorId': userId,
  //           'realtorId': realtorId,
  //           'status': 'sent',
  //           'timestamp': FieldValue.serverTimestamp(),
  //         });
  //       }
  //     } else {
  //       // Not from realtor: just delete the like/dislike interaction
  //       batch.delete(investorRef);
  //       if (realtorId != null) {
  //         final realtorRef = _db
  //             .collection('realtors')
  //             .doc(realtorId)
  //             .collection('interactions')
  //             .doc('${lastProperty.id}_$userId');
  //         batch.delete(realtorRef);
  //       }
  //     }
  //
  //     await batch.commit();
  //
  //     if (mounted) {
  //       setState(() {
  //         _properties.insert(0, lastProperty);
  //         _noMoreProperties = false;
  //       });
  //     }
  //
  //     return true;
  //   } catch (e) {
  //     debugPrint('Undo failed: $e');
  //     return false;
  //   }
  // }

  @override
  void dispose() {
    _controller.dispose();
    _longActivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ToggleButtons(
          isSelected: [_useRealtorDecisions, !_useRealtorDecisions],
          onPressed: (index) {
            setState(() {
              _useRealtorDecisions = index == 0;
              _properties = [];
              _noMoreProperties = false;
            });
            _loadProperties();
          },
          borderRadius: BorderRadius.circular(8),
          constraints: const BoxConstraints(minHeight: 36, minWidth: 120),
          selectedColor: Colors.white,
          color: Colors.deepPurple,
          fillColor: Colors.deepPurple,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          children: const [
            Text("From Realtor"),
            Text("Recommended"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_rounded),
            onPressed: () {
              // your help dialog
            },
          ),
        ],
      ),
      body: _properties.isEmpty
          ? Center(
              child: _noMoreProperties
                  ? (_noRealtorAssigned && _useRealtorDecisions
                      ? Text('No realtor assigned. Please contact support.')
                      : Text(
                          'No more properties available. Your realtor is busy finding properties that you like.'))
                  : CircularProgressIndicator(),
            )
          : CardSwiper(
              controller: _controller,
              cardsCount: _properties.length,
              numberOfCardsDisplayed:
                  (_properties.length >= 2) ? 2 : 1, // Ensure valid card count
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
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                final property = _properties[index];
                if (index == 0) {
                  _startCardViewTracking(property.id);
                }

                // Determine if this was a "sent" property
                final wasSent =
                    _useRealtorDecisions; // You could refine this further

                return PropertySwipeCard(
                  property: property,
                  controller: _controller,
                );
              },
            ),
    );
  }
}

class PropertySwipeCard extends StatelessWidget {
  final Property property;
  final CardSwiperController controller;

  const PropertySwipeCard({
    super.key,
    required this.property,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final isDarkMode = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
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
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 👇 image section that takes remaining space
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: CachedNetworkImage(
                          imageUrl: property.image != null
                              ? (kDebugMode ? 'http://localhost:8080/${property.image}' : property.image!)
                              : 'https://placehold.co/600x400',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: ClipRRect(
                        child: CachedNetworkImage(
                          imageUrl: property.image != null
                              ? (kDebugMode ? 'http://localhost:8080/${property.image}' : property.image!)
                              : 'https://placehold.co/600x400',
                          width: double.infinity, // 👈 full width
                          fit: BoxFit.fill,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),


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
                          property.price != null
                              ? "\$ ${currencyFormat.format(property.price)}"
                              : "N/A",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 10,
                      bottom: 60,
                      child: CashFlowBadge(propertyId: property.id),
                    ),

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
                            child: Text(
                              property.address ?? "Unknown Address",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),

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
              ),

              // 👇 Bottom Section - height based on content
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(
                            icon: Icons.king_bed,
                            label: "${property.beds} Beds",
                            theme: theme,
                          ),
                          _verticalDivider(),
                          _buildStat(
                            icon: Icons.bathtub,
                            label: "${property.baths} Baths",
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
            ],
          ),
        ),
      ),
    );
  }


  Widget _verticalDivider() => Container(
        width: 1,
        height: 20,
        color: Colors.grey[400],
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
  Widget _buildStat(
      {required IconData icon,
      required String label,
      required ThemeData theme}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
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
        maxWidth: 1000,
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
  final String? image;
  final double? price;
  final int? beds;
  final int? baths;
  final String? address;
  final int? sqft;
  final double? tax;
  final String? status;

  Property({
    required this.id,
    this.image,
    this.price,
    this.beds,
    this.baths,
    this.address,
    this.sqft,
    this.tax,
    this.status,
  });

  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Property(
      id: doc.id,
      image: data['primary_photo'],
      price: (data['list_price'] as num?)?.toDouble(),
      beds: data['beds'] as int?,
      baths: data['full_baths'] as int? ??
          0 + (data['half_baths'] as int? ?? 0) ~/ 2,
      address: data['street'],
      sqft: data['sqft'] as int?,
      tax: (data['tax'] as num?)?.toDouble(),
      status: data['status'] as String?,
    );
  }

  @override
  String toString() {
    return 'Property{id: $id, image: $image, price: $price, beds: $beds, baths: $baths, address: $address, sqft: $sqft, tax: $tax, status: $status}';
  }

  // to Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': kDebugMode ? 'http://localhost:8080/$image' : image,
      'price': price,
      'beds': beds,
      'baths': baths,
      'address': address,
      'sqft': sqft,
      'tax': tax,
      'status': status,
    };
  }
}
