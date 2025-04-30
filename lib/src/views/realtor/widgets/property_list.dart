import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

/// A generic widget to display a paginated grid/list of properties
/// fetched from Firestore using `FirestoreQueryBuilder`.
///
/// Requires:
/// - A `query` to fetch property documents.
/// - A `buildPropertyCard` callback to render each card.
///
/// This widget supports infinite scrolling and dynamically adjusts
/// layout for different screen sizes.
class PropertyList extends StatelessWidget {
  final Query<Map<String, dynamic>> query;

  /// Builder function to render each property card.
  final Widget Function(Map<String, dynamic>) buildPropertyCard;

  const PropertyList({
    super.key,
    required this.query,
    required this.buildPropertyCard,
  });

  @override
  Widget build(BuildContext context) {
    return FirestoreQueryBuilder<Map<String, dynamic>>(
      query: query,
      pageSize: 20,
      builder: (context, snapshot, _) {
        // Show loading indicator when fetching first page
        if (snapshot.isFetching && snapshot.docs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error message if Firestore query fails
        if (snapshot.hasError) {
          return Center(child: SelectableText('Error: ${snapshot.error}'));
        }

        // Infinite scroll: fetch more when near the bottom
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 300 &&
                snapshot.hasMore &&
                !snapshot.isFetching) {
              snapshot.fetchMore();
            }
            return false;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: List.generate(snapshot.docs.length, (index) {
                  final doc = snapshot.docs[index];
                  final property = doc.data();

                  // Extract and clean the relevant fields
                  return RepaintBoundary(
                    child: SizedBox(
                      width: _getCardWidth(context),
                      child: buildPropertyCard({
                        "id": doc.id,
                        "latitude": property["latitude"],
                        "longitude": property["longitude"],
                        "address": property["full_street_line"],
                        "price": property["list_price"],
                        "beds": property["beds"],
                        "baths": property["full_baths"],
                        "sqft": property["sqft"],
                        "mls_id": property["mls_id"],
                        "status": property["status"],
                        "image": (property["primary_photo"] != null &&
                            property["primary_photo"] != "")
                            ? property["primary_photo"]
                            .toString()
                            .replaceAll("http://", "https://")
                            : "https://bearhomes.com/wp-content/uploads/2019/01/default-featured.png",
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dynamically calculate card width based on screen size
  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1600) return 350; // 3+ cards
    if (screenWidth >= 1000) return 350; // 2 cards
    if (screenWidth >= 740) return 350;  // 1.5 cards
    return screenWidth - 32;             // full width for mobile
  }
}
