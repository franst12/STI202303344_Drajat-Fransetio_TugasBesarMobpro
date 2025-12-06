import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/destination_model.dart';
import '../db/database_helper.dart';
import 'map_picker_screen.dart';

class AddEditScreen extends StatefulWidget {
  final Destination? destination;

  const AddEditScreen({super.key, this.destination});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;

  String _openTime = '08:00';
  String _closeTime = '17:00'; // Variable Jam Tutup
  List<String> _imagePaths = [];
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLocationPicked = false;

  List<dynamic> _addressSuggestions = [];
  Timer? _debounce;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.destination?.name ?? '');
    _descController =
        TextEditingController(text: widget.destination?.description ?? '');
    _addressController =
        TextEditingController(text: widget.destination?.address ?? '');
    _openTime = widget.destination?.openTime ?? '08:00';
    _closeTime = widget.destination?.closeTime ?? '17:00'; // Load Jam Tutup
    _imagePaths = List.from(widget.destination?.imagePaths ?? []);
    _latitude = widget.destination?.latitude ?? 0.0;
    _longitude = widget.destination?.longitude ?? 0.0;

    if (widget.destination != null) {
      _isLocationPicked = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    if (query.length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=id');
    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'com.example.wisatalokal'});
      if (response.statusCode == 200) {
        setState(() {
          _addressSuggestions = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    setState(() => _isLoadingAddress = true);
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'com.example.wisatalokal'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          setState(() {
            _addressController.text = data['display_name'];
            _addressSuggestions = [];
          });
          if (_nameController.text.isEmpty) {
            String placeName = data['address']['tourism'] ??
                data['address']['leisure'] ??
                data['address']['building'] ??
                data['address']['amenity'] ??
                "";
            if (placeName.isNotEmpty) _nameController.text = placeName;
          }
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _pickTime(bool isOpening) async {
    final initial = isOpening ? _openTime : _closeTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.parse(initial.split(':')[0]),
          minute: int.parse(initial.split(':')[1])),
    );
    if (picked != null) {
      setState(() {
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        final formatted = '$hour:$minute';
        if (isOpening) {
          _openTime = formatted;
        } else {
          _closeTime = formatted;
        }
      });
    }
  }

  Future<void> _pickImages() async {
    if (_imagePaths.length >= 7) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Maksimal 7 foto!')));
      return;
    }
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if (_imagePaths.length < 7) _imagePaths.add(img.path);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Aktifkan GPS')));
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _pickLocation() async {
    double initLat = _latitude;
    double initLong = _longitude;
    if (!_isLocationPicked || (initLat == 0.0 && initLong == 0.0)) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()));
      try {
        final position = await _determinePosition();
        if (mounted) Navigator.pop(context);
        if (position != null) {
          initLat = position.latitude;
          initLong = position.longitude;
        } else {
          initLat = -6.200000;
          initLong = 106.816666;
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
      }
    }
    if (!mounted) return;
    final LatLng? result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) =>
                MapPickerScreen(initialLat: initLat, initialLong: initLong)));
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _isLocationPicked = true;
      });
      _getAddressFromLatLng(result.latitude, result.longitude);
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      final destination = Destination(
        id: widget.destination?.id,
        name: _nameController.text,
        description: _descController.text,
        address: _addressController.text,
        openTime: _openTime,
        closeTime: _closeTime, // Simpan jam tutup
        imagePaths: _imagePaths,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (widget.destination == null) {
        await DatabaseHelper.instance.create(destination);
      } else {
        await DatabaseHelper.instance.update(destination);
      }

      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Data Berhasil Disimpan!'),
            backgroundColor: Colors.green));
        setState(() {
          _nameController.clear();
          _descController.clear();
          _addressController.clear();
          _imagePaths.clear();
          _isLocationPicked = false;
          _latitude = 0.0;
          _longitude = 0.0;
          _openTime = '08:00';
          _closeTime = '17:00';
          _addressSuggestions = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFE5E9C5),
      appBar: AppBar(
        title:
            Text(widget.destination == null ? 'Tambah Wisata' : 'Edit Wisata'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveData)
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Foto Wisata (Max 7)",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: _imagePaths.isEmpty
                      ? GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade400)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded,
                                      size: 40, color: Colors.grey.shade600),
                                  const SizedBox(height: 8),
                                  Text("Ketuk untuk upload foto",
                                      style: TextStyle(
                                          color: Colors.grey.shade600))
                                ]),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._imagePaths.asMap().entries.map((entry) {
                              return Stack(children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(entry.value),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover)),
                                Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                        onTap: () => _removeImage(entry.key),
                                        child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.close,
                                                size: 16,
                                                color: Colors.white)))),
                              ]);
                            }),
                            if (_imagePaths.length < 7)
                              GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(Icons.add,
                                          color: Colors.grey))),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'Nama Destinasi',
                        prefixIcon: Icon(Icons.place, color: primaryColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white),
                    validator: (value) =>
                        value!.isEmpty ? 'Nama tidak boleh kosong' : null),
                const SizedBox(height: 16),
                Column(
                  children: [
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                          labelText: 'Alamat',
                          prefixIcon: Icon(Icons.map, color: primaryColor),
                          suffixIcon: _isLoadingAddress
                              ? Transform.scale(
                                  scale: 0.5,
                                  child: const CircularProgressIndicator())
                              : (_addressSuggestions.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(
                                          () => _addressSuggestions = []))
                                  : null),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white),
                      validator: (value) =>
                          value!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 1000), () {
                          _fetchAddressSuggestions(value);
                        });
                      },
                    ),
                    if (_addressSuggestions.isNotEmpty)
                      Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 5)
                              ]),
                          child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _addressSuggestions.length,
                              itemBuilder: (context, index) {
                                final item = _addressSuggestions[index];
                                return ListTile(
                                    leading: const Icon(
                                        Icons.location_on_outlined,
                                        size: 20),
                                    title: Text(item['display_name'] ?? '',
                                        style: const TextStyle(fontSize: 13)),
                                    onTap: () {
                                      setState(() {
                                        _addressController.text =
                                            item['display_name'];
                                        _latitude = double.parse(item['lat']);
                                        _longitude = double.parse(item['lon']);
                                        _isLocationPicked = true;
                                        _addressSuggestions = [];
                                      });
                                      FocusScope.of(context).unfocus();
                                    });
                              }))
                  ],
                ),
                const SizedBox(height: 16),

                // ROW JAM BUKA & TUTUP
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(true),
                        child: InputDecorator(
                            decoration: InputDecoration(
                                labelText: 'Jam Buka',
                                prefixIcon: Icon(Icons.wb_sunny_outlined,
                                    color: primaryColor),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white),
                            child: Text(_openTime)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(false),
                        child: InputDecorator(
                            decoration: InputDecoration(
                                labelText: 'Jam Tutup',
                                prefixIcon: Icon(Icons.nightlight_round,
                                    color: primaryColor),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white),
                            child: Text(_closeTime)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // TOMBOL PETA
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: Icon(Icons.pin_drop,
                        color: _isLocationPicked ? Colors.green : Colors.grey),
                    label: Text(
                        _isLocationPicked
                            ? 'Lokasi Tersimpan'
                            : 'Pilih di Peta',
                        style: TextStyle(
                            color: _isLocationPicked
                                ? Colors.green
                                : Colors.grey[700])),
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: _isLocationPicked
                                ? Colors.green
                                : Colors.grey)),
                  ),
                ),

                const SizedBox(height: 16),
                TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                        labelText: 'Deskripsi Singkat',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 30),
                SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('SIMPAN DATA',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
