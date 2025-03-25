import 'package:flutter/material.dart';
import 'package:galleryimage/galleryimage.dart';

class ImageGalleryWidget extends StatelessWidget {
  final List<String> imageUrls;

  const ImageGalleryWidget({Key? key, required this.imageUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return _buildPlaceholder(); // Show placeholder if no images exist
    }

    return GalleryImage(
      imageUrls: imageUrls,
      numOfShowImages: imageUrls.length >= 3 ? 3 : imageUrls.length, // Ensure safe number
      imageRadius: 12,
      closeWhenSwipeDown: true,
    );
  }

  /// Placeholder for when no images are available
  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    );
  }
}
