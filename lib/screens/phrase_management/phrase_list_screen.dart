import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/auth_provider.dart';
import '../../providers/phrase_provider.dart';
import '../../widgets/phrase/phrase_card.dart';
import 'add_phrase_screen.dart';

class PhraseListScreen extends StatefulWidget {
  static const routeName = '/phrase-list';

  const PhraseListScreen({Key? key}) : super(key: key);

  @override
  State<PhraseListScreen> createState() => _PhraseListScreenState();
}

class _PhraseListScreenState extends State<PhraseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhrases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat frasa
  Future<void> _loadPhrases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phraseProvider =
          Provider.of<PhraseProvider>(context, listen: false);

      // Muat frasa milik user yang login
      await phraseProvider.loadPhrases(userId: authProvider.userId);
    } catch (e) {
      print('Error loading phrases: $e');
      // Error akan ditangani oleh provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk pencarian
  void _searchPhrases(String query) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phraseProvider = Provider.of<PhraseProvider>(context, listen: false);

    setState(() {
      _isSearching = true;
    });

    // Jika query kosong, muat semua frasa
    if (query.trim().isEmpty) {
      phraseProvider.loadPhrases(userId: authProvider.userId);
    } else {
      // Cari frasa berdasarkan query
      phraseProvider.searchPhrases(query, userId: authProvider.userId);
    }

    setState(() {
      _isSearching = false;
    });
  }

  // Navigasi ke halaman tambah frasa
  void _navigateToAddPhrase() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPhraseScreen()),
    );

    // Refresh jika ada perubahan
    if (result == true) {
      _loadPhrases();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final phraseProvider = Provider.of<PhraseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frasa Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              // Filter frasa favorit
              phraseProvider.loadPhrases(
                userId: authProvider.userId,
                isFavorite: true,
              );
            },
            tooltip: 'Tampilkan Favorit',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh frasa
              phraseProvider.refreshPhrases(userId: authProvider.userId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari frasa...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchPhrases('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Tunggu pengguna selesai mengetik
                Future.delayed(const Duration(milliseconds: 300), () {
                  // Pastikan value masih sama (pengguna tidak mengetik lagi)
                  if (_searchController.text == value) {
                    _searchPhrases(value);
                  }
                });
              },
            ),
          ),

          // Loading indicator
          if (phraseProvider.isLoading || _isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // Error message
          if (phraseProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                phraseProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // List frasa
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => phraseProvider.refreshPhrases(
                userId: authProvider.userId,
              ),
              child: phraseProvider.phrases.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: phraseProvider.phrases.length,
                      itemBuilder: (context, index) {
                        final phrase = phraseProvider.phrases[index];
                        return PhraseCard(
                          phrase: phrase,
                          onDeleted: () {
                            // Auto refresh setelah hapus
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Frasa berhasil dihapus'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          onUpdated: () {
                            // Auto refresh setelah update
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Frasa berhasil diperbarui'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPhrase,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Frasa Baru',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada frasa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan frasa baru dengan menekan tombol + di bawah',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddPhrase,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Frasa Baru'),
          ),
        ],
      ),
    );
  }
}
