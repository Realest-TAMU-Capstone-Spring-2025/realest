import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Displays detailed information about a specific property.
class PropertiesView extends StatefulWidget {
  /// The ID of the property to display.
  final String propertyId;

  /// Whether to show the save icon in the app bar.
  final bool showSaveIcon;

  const PropertiesView({
    super.key,
    required this.propertyId,
    this.showSaveIcon = true,
  });

  @override
  State<PropertiesView> createState() => _PropertiesViewState();
}

/// Manages property data and user interactions for [PropertiesView].
class _PropertiesViewState extends State<PropertiesView> {
  /// Current authenticated user, if any.
  late final User? _user = FirebaseAuth.instance.currentUser;

  /// Tracks if the property is saved (liked) by the user.
  bool _isSaved = false;

  /// Future for fetching property data from Firestore.
  late final Future<DocumentSnapshot> _propertyData;

  /// Formats numbers with commas for display (e.g., 1000 → 1,000).
  final NumberFormat currencyFormat = NumberFormat('#,##0', 'en_US');

  /// Tracks if the user is a realtor.
  bool _isRealtor = false;

  @override
  void initState() {
    super.initState();
    // Initialize data fetching and status checks
    _propertyData = _fetchPropertyData();
    _checkSavedStatus();
    _checkRealtorStatus();
  }

  /// Fetches property data from Firestore using the provided property ID.
  ///
  /// Returns a [Future] containing the [DocumentSnapshot] of the property.
  Future<DocumentSnapshot> _fetchPropertyData() async {
    return FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.propertyId)
        .get();
  }

  /// Adds the property to the user's curated list if they are a realtor.
  Future<void> _addToCuratedList() async {
    if (_user == null || !_isRealtor) return;

    final curatedListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('curated_listings');

    await curatedListRef.doc(widget.propertyId).set({
      'added_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to curated list')),
    );
  }

  /// Checks if the user has a realtor role in Firestore.
  ///
  /// Returns a [Future] indicating if the user is a realtor.
  Future<bool> _isUserRealtor() async {
    if (_user == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    return userDoc.data()?['role'] == 'realtor';
  }

  /// Updates the realtor status based on the user's role.
  Future<void> _checkRealtorStatus() async {
    final isRealtor = await _isUserRealtor();
    if (mounted) {
      setState(() => _isRealtor = isRealtor);
    }
  }

  /// Checks if the property is saved (liked) by the user.
  Future<void> _checkSavedStatus() async {
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user?.uid)
        .collection('decisions')
        .doc(widget.propertyId)
        .get();

    if (mounted) {
      setState(() => _isSaved = doc.exists && doc.data()?['liked'] == true);
    }
  }

  /// Toggles the saved (liked) status of the property in Firestore.
  Future<void> _toggleSave() async {
    if (_user == null) return;

    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user?.uid)
        .collection('decisions');

    // Update UI immediately
    setState(() => _isSaved = !_isSaved);

    // Update Firestore in the background
    if (_isSaved) {
      await collectionRef.doc(widget.propertyId).set({
        'liked': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await collectionRef.doc(widget.propertyId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Builds the UI with an app bar and property details
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        actions: widget.showSaveIcon
            ? [
          _isRealtor
              ? const Text('Add to Curated List')
              : const SizedBox.shrink(),
          IconButton(
            icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
            color: _isSaved ? Colors.red : Colors.green,
            onPressed: _toggleSave,
          ),
        ]
            : null,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _propertyData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Property not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildContent(data);
        },
      ),
    );
  }

  /// Builds the main content with a photo gallery and detail cards.
  ///
  /// [data] The property data from Firestore.
  /// Returns a [Widget] containing the content layout.
  Widget _buildContent(Map<String, dynamic> data) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoGallery(data['alt_photos']),
            const SizedBox(height: 24),
            _buildDetailCards(data),
          ],
        ),
      ),
    );
  }

  /// Builds a carousel slider for property photos.
  ///
  /// [altPhotos] A comma-separated string of photo URLs.
  /// Returns a [Widget] containing the photo gallery.
  Widget _buildPhotoGallery(String? altPhotos) {
    final photos = altPhotos?.split(', ') ?? [];
    return SizedBox(
      height: 250,
      child: photos.isNotEmpty
          ? CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 2),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          viewportFraction: 0.8,
          enableInfiniteScroll: true,
        ),
        items: photos.map((url) => _buildImageContainer(url)).toList(),
      )
          : const Center(child: Text('No photos available')),
    );
  }

  /// Builds a container for a single image in the photo gallery.
  ///
  /// [url] The URL of the image to display.
  /// Returns a [Widget] containing the image.
  Widget _buildImageContainer(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          // "http://localhost:3000/proxy-image?url=${Uri.encodeQueryComponent(url)}",
          "https://localhost:3000/proxy-image?url=${Uri.encodeQueryComponent(url)}",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 50),
          ),
        ),
      ),
    );
  }

  /// Builds detail cards for basic details, property info, and description.
  ///
  /// [data] The property data from Firestore.
  /// Returns a [Widget] containing the detail cards.
  Widget _buildDetailCards(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildDetailCard(
          'Basic Details',
          [
            _buildDetailRow('Address', data['street'] ?? 'N/A'),
            _buildDetailRow('City', data['city'] ?? 'N/A'),
            _buildDetailRow('State', data['state'] ?? 'N/A'),
            _buildDetailRow('Zip Code', data['zip_code'] ?? 'N/A'),
            _buildDetailRow('Neighborhood', data['neighborhoods'] ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailCard(
          'Property Information',
          [
            _buildDetailRow('Price', '\$${currencyFormat.format(data['list_price'])}' ?? 'N/A'),
            _buildDetailRow('Beds', data['beds']?.toString() ?? 'N/A'),
            _buildDetailRow('Baths',
                '${data['full_baths'] ?? 0} Full | ${data['half_baths'] ?? 0} Half'),
            _buildDetailRow('Square Footage', '${data['sqft']} sqft' ?? 'N/A'),
          ],
        ),
        if (data['text'] != null) ...[
          const SizedBox(height: 16),
          _buildDetailCard(
            'Description',
            [
              Text(data['text'], style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
          ),
        ],
      ],
    );
  }

  /// Builds a card containing a title and list of detail rows or text.
  ///
  /// [title] The title of the card.
  /// [children] The list of widgets to display in the card.
  /// Returns a [Widget] representing the detail card.
  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Builds a section title for detail cards.
  ///
  /// [title] The title text to display.
  /// Returns a [Widget] representing the section title.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  /// Builds a row displaying a label and value for property details.
  ///
  /// [label] The label for the detail.
  /// [value] The value to display.
  /// Returns a [Widget] representing the detail row.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}