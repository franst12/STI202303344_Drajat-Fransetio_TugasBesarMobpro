import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/destination_model.dart';
import '../widgets/destination_card.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Destination>> _destinationsFuture;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Warna sesuai palet
  final Color _primaryColor = const Color(0xFF016B61);

  @override
  void initState() {
    super.initState();
    _refreshDestinations();
  }

  // ... (Logika _refreshDestinations & _deleteDestination TETAP SAMA seperti sebelumnya) ...
  Future<void> _refreshDestinations({String? query}) async {
    setState(() {
      if (query != null && query.isNotEmpty) {
        _isSearching = true;
        _destinationsFuture = DatabaseHelper.instance.searchDestinations(query);
      } else {
        _isSearching = false;
        _destinationsFuture = DatabaseHelper.instance.readAllDestinations();
      }
    });
    await _destinationsFuture;
  }

  Future<void> _deleteDestination(int id) async {
    await DatabaseHelper.instance.delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destinasi berhasil dihapus!')),
      );
    }
    _refreshDestinations(query: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background diambil dari tema (Cream)
      appBar: AppBar(
        title: const Text('Wisata Lokal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: _primaryColor),
              decoration: InputDecoration(
                hintText: 'Cari destinasi wisata...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search_rounded, color: _primaryColor),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _refreshDestinations();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onChanged: (value) => _refreshDestinations(query: value),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Destination>>(
        future: _destinationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching
                        ? Icons.search_off_rounded
                        : Icons.photo_library_outlined,
                    size: 80,
                    color: const Color(
                      0xFF70B2B2,
                    ).withOpacity(0.5), // Secondary color faded
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? 'Tidak ditemukan.'
                        : 'Belum ada data wisata.\nTekan + untuk menambah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _primaryColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final destinations = snapshot.data!;
          return RefreshIndicator(
            color: _primaryColor,
            onRefresh: () =>
                _refreshDestinations(query: _searchController.text),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80, top: 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                return DestinationCard(
                  destination: item,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(destination: item),
                      ),
                    );
                    _refreshDestinations(query: _searchController.text);
                  },
                  onDelete: () => _showDeleteDialog(item.id!),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Dialog Hapus tetap sama...
  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Data?'),
        content: const Text('Data yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteDestination(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
