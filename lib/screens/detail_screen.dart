import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/destination_model.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final Destination destination;

  const DetailScreen({super.key, required this.destination});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _currentImageIndex = 0;
  final Color _primaryColor = const Color(0xFF016B61);
  final Color _secondaryColor = const Color(0xFF70B2B2);

  Future<void> _launchMaps() async {
    final lat = widget.destination.latitude;
    final long = widget.destination.longitude;
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$long");
    try {
      if (!await launchUrl(googleMapsUrl,
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch maps';
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal membuka peta: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchMaps,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.directions, color: Colors.white),
        label: const Text("Petunjuk Arah",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: _primaryColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Colors.black26, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.destination.imagePaths.isNotEmpty
                  ? Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        PageView.builder(
                          itemCount: widget.destination.imagePaths.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (ctx, index) {
                            if (index == 0) {
                              return Hero(
                                tag:
                                    'img-${widget.destination.id ?? widget.destination.name}',
                                child: Image.file(
                                    File(widget.destination.imagePaths[index]),
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        Container(color: _secondaryColor)),
                              );
                            }
                            return Image.file(
                                File(widget.destination.imagePaths[index]),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    Container(color: _secondaryColor));
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                              '${_currentImageIndex + 1} / ${widget.destination.imagePaths.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  : Container(
                      color: _secondaryColor,
                      child: const Center(
                          child: Icon(Icons.image,
                              size: 80, color: Colors.white54))),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                    color: Colors.black26, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddEditScreen(
                                destination: widget.destination)));
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2)))),
                  Text(widget.destination.name,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                  const SizedBox(height: 16),

                  // INFO JAM BUKA - TUTUP
                  Row(children: [
                    _buildInfoChip(Icons.access_time_filled_rounded,
                        '${widget.destination.openTime} - ${widget.destination.closeTime}'),
                  ]),
                  const SizedBox(height: 12),
                  // INFO ALAMAT
                  Row(children: [
                    Expanded(
                        child: _buildInfoChip(Icons.location_on_rounded,
                            widget.destination.address)),
                  ]),

                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider()),
                  Text('Tentang Destinasi',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                  const SizedBox(height: 8),
                  Text(widget.destination.description,
                      style: TextStyle(
                          fontSize: 15, height: 1.6, color: Colors.grey[800])),
                  const SizedBox(height: 32),
                  Text('Lokasi Peta',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                  const SizedBox(height: 12),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5))
                        ]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FlutterMap(
                        options: MapOptions(
                            initialCenter: LatLng(widget.destination.latitude,
                                widget.destination.longitude),
                            initialZoom: 15.0),
                        children: [
                          TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.aplikasi_travel_wisata_lokal'),
                          MarkerLayer(markers: [
                            Marker(
                                point: LatLng(widget.destination.latitude,
                                    widget.destination.longitude),
                                width: 50,
                                height: 50,
                                child: Icon(Icons.location_on,
                                    color: Colors.red[600], size: 45))
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFE5E9C5),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
