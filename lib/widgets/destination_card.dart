import 'dart:io';
import 'package:flutter/material.dart';
import '../models/destination_model.dart';

class DestinationCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF016B61);
    const Color secondaryColor = Color(0xFF70B2B2);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Hero(
                  tag: 'img-${destination.id ?? destination.name}',
                  child: destination.imagePaths.isNotEmpty
                      ? Image.file(
                          File(destination.imagePaths[0]),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          destination.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 20, color: Colors.red[400]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: secondaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination.address,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // SHOW OPEN - CLOSE TIME
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '${destination.openTime} - ${destination.closeTime}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF9ECFD4).withOpacity(0.3),
      child: const Center(
          child:
              Icon(Icons.image_outlined, size: 50, color: Color(0xFF70B2B2))),
    );
  }
}
