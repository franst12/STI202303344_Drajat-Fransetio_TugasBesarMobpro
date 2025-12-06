import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLong;

  const MapPickerScreen({
    super.key,
    this.initialLat = -6.200000, // Default Jakarta
    this.initialLong = 106.816666,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _pickedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pickedLocation = LatLng(widget.initialLat, widget.initialLong);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          // --- FITUR BARU: TOMBOL REFRESH ---
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh / Reset Posisi',
            onPressed: () {
              setState(() {
                // 1. Kembalikan variabel ke koordinat awal
                _pickedLocation = LatLng(widget.initialLat, widget.initialLong);
              });
              // 2. Pindahkan kamera peta kembali ke awal
              _mapController.move(_pickedLocation, 15.0);

              // 3. Beri notifikasi kecil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Peta di-refresh ke posisi awal'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Simpan Lokasi',
            onPressed: () {
              // Kembalikan data LatLng terakhir ke halaman sebelumnya
              Navigator.pop(context, _pickedLocation);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // PERBAIKAN: Menggunakan 'center' dan 'zoom' (Untuk Flutter Map versi 5 ke bawah)
              // Jika error 'initialCenter' muncul, berarti Anda pakai versi lama. Kode ini solusinya.
              center: LatLng(widget.initialLat, widget.initialLong),
              zoom: 15.0,

              // 1. Logika saat peta DIGESER (Drag)
              onPositionChanged: (position, hasGesture) {
                // Update variabel lokasi secara real-time mengikuti tengah peta
                // Di versi lama, position.center bisa null, jadi kita cek dulu
                if (position.center != null) {
                  setState(() {
                    _pickedLocation = position.center!;
                  });
                }
              },

              // 2. Logika saat peta DIKETUK (Tap)
              onTap: (tapPosition, point) {
                // Pindahkan kamera peta agar titik yang diketuk lari ke tengah (ke bawah pin)
                // Di versi lama, _mapController.zoom mengembalikan double, bukan properti camera
                _mapController.move(point, _mapController.zoom);
                setState(() {
                  _pickedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.aplikasi_travel_wisata_lokal',
              ),
            ],
          ),

          // --- PIN STATIS DI TENGAH LAYAR ---
          // Pin ini tidak bergerak, Peta-nya yang bergerak di bawah pin ini.
          const Center(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 40,
              ), // Mengangkat pin agar ujung bawahnya pas di tengah
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black26,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),

          // Info Box di bawah
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(blurRadius: 5, color: Colors.black26),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lokasi Terpilih:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_pickedLocation.latitude.toStringAsFixed(5)}\n'
                    'Lng: ${_pickedLocation.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Geser peta atau ketuk lokasi tujuan',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
