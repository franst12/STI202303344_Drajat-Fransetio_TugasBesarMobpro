import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Import library ini
import '../db/database_helper.dart';
import '../models/destination_model.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Destination> _destinations = [];
  final MapController _mapController = MapController();
  final Color _primaryColor = const Color(0xFF016B61);

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final data = await DatabaseHelper.instance.readAllDestinations();
    setState(() {
      _destinations = data;
    });
  }

  // --- FUNGSI BUKA GOOGLE MAPS ---
  Future<void> _launchMaps(double lat, double long) async {
    // URL Scheme untuk Google Maps Navigation
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$long");

    try {
      if (!await launchUrl(googleMapsUrl,
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch maps';
      }
    } catch (e) {
      debugPrint("Error launching maps: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajah Peta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDestinations,
          ),
        ],
      ),
      body: _destinations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined,
                      size: 80, color: _primaryColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data lokasi wisata.',
                    style: TextStyle(color: _primaryColor, fontSize: 16),
                  ),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_destinations.first.latitude,
                    _destinations.first.longitude),
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.aplikasi_travel_wisata_lokal',
                ),
                MarkerLayer(
                  markers: _destinations.map((item) {
                    return Marker(
                      point: LatLng(item.latitude, item.longitude),
                      width: 70,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          _showPreviewDialog(item);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 4, color: Colors.black26)
                                ],
                                border:
                                    Border.all(color: _primaryColor, width: 1),
                              ),
                              child: Text(
                                item.name,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Icon(Icons.location_on_rounded,
                                color: _primaryColor, size: 40),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  void _showPreviewDialog(Destination item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: item.imagePaths.isNotEmpty
                      ? Image.file(
                          File(item.imagePaths[0]),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: const Color(0xFF9ECFD4),
                            child: const Center(
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.white)),
                          ),
                        )
                      : Container(
                          height: 150,
                          color: const Color(0xFF9ECFD4),
                          child: const Center(
                              child: Icon(Icons.image,
                                  size: 50, color: Colors.white)),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.black45, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: _primaryColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(item.address,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- ROW TOMBOL AKSI ---
                  Row(
                    children: [
                      // Tombol RUTE KE SINI (Google Maps)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue.shade600, // Warna khas Maps
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            _launchMaps(item.latitude, item.longitude);
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Rute'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol DETAIL
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(destination: item)),
                            );
                          },
                          child: Text('Detail',
                              style: TextStyle(color: _primaryColor)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
