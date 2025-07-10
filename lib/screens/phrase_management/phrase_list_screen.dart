import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/phrase.dart';
import '../../providers/auth_provider.dart';
import '../../providers/phrase_provider.dart';
import '../../utils/async_helper.dart'; // Tambahkan import
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
  bool _isLoadingData = false;
  bool _isShowingFavorites =
      false; // Tambahkan state untuk melacak filter favorit
  DateTime _lastRefreshTime =
      DateTime.now().subtract(const Duration(minutes: 5));

  @override
  void initState() {
    super.initState();
    // Jadwalkan loading setelah widget dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _throttledLoadPhrases();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk throttle load data
  void _throttledLoadPhrases() {
    final now = DateTime.now();
    final difference = now.difference(_lastRefreshTime);

    // Hanya reload jika sudah lewat 30 detik dari load terakhir
    if (difference.inSeconds > 30 && !_isLoadingData) {
      _loadPhrases();
      _lastRefreshTime = now;
    }
  }

  // Fungsi untuk memuat frasa
  Future<void> _loadPhrases() async {
    // Hindari loading berulang
    if (_isLoadingData) return;
    _isLoadingData = true;

    // Set loading state di awal
    setState(() {
      _isLoading = true;
    });

    // Gunakan AsyncHelper untuk operasi aman
    AsyncHelper.runWithMounted(
      state: this,
      operation: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final phraseProvider =
            Provider.of<PhraseProvider>(context, listen: false);

        // PERBAIKAN: Validasi bahwa user benar-benar login
        final userId = authProvider.userId;

        // PERBAIKAN: Cek status autentikasi terlebih dahulu dan refresh session jika perlu
        if (!authProvider.isAuthenticated || userId.isEmpty) {
          print("Warning: User session invalid, attempting to refresh");
          final sessionRefreshed = await authProvider.checkAndFixSession();

          if (!sessionRefreshed || authProvider.userId.isEmpty) {
            throw Exception("Anda harus login untuk melihat frasa");
          }
        }

        // Pastikan menggunakan userId terbaru setelah refresh
        final currentUserId = authProvider.userId;
        print('Loading phrases for user: $currentUserId');

        // Muat frasa milik user yang login - hapus forceRefresh untuk mengurangi request network
        await phraseProvider.loadPhrases(userId: currentUserId);

        // PERBAIKAN: Validasi hasil query untuk pastikan hanya frasa milik user
        final loadedPhrases = phraseProvider.phrases;
        List<String> nonUserPhraseIds = [];

        for (var phrase in loadedPhrases) {
          if (phrase.userId != currentUserId && phrase.userId != 'universal') {
            print(
                "Warning: Found phrase from another user: ${phrase.id}, user: ${phrase.userId}");
            nonUserPhraseIds.add(phrase.id);
          }
        }

        // Hapus frasa yang bukan milik user dari list lokal
        if (nonUserPhraseIds.isNotEmpty) {
          print('Removing ${nonUserPhraseIds.length} non-user phrases');
          for (var id in nonUserPhraseIds) {
            phraseProvider.removeNonUserPhrase(id);
          }
        }

        return true; // Operasi berhasil
      },
      onComplete: (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingData = false;
          });
        }
      },
      onError: (e) {
        print('Error loading phrases: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
            _isLoadingData = false;
          });
        }
      },
    );
  }

  // Fungsi untuk pencarian
  void _searchPhrases(String query) {
    if (_isSearching) return; // Hindari pencarian berulang

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phraseProvider = Provider.of<PhraseProvider>(context, listen: false);

    // Set loading state di awal tanpa async
    setState(() {
      _isSearching = true;
    });

    // Gunakan AsyncHelper untuk memastikan operasi async aman
    AsyncHelper.runWithMounted(
      state: this,
      operation: () async {
        // Jika query kosong, muat semua frasa
        if (query.trim().isEmpty) {
          await phraseProvider.loadPhrases(userId: authProvider.userId);
        } else {
          // Cari frasa berdasarkan query
          await phraseProvider.searchPhrases(query,
              userId: authProvider.userId);
        }
        return true; // Operasi berhasil
      },
      onComplete: (_) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      },
      onError: (e) {
        print('Error searching phrases: $e');
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      },
    );
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

  // Menampilkan semua frasa (pembatalan filter)
  void _showAllPhrases() {
    setState(() {
      _isShowingFavorites = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phraseProvider = Provider.of<PhraseProvider>(context, listen: false);

    // Set loading state untuk menunjukkan proses sedang berjalan
    setState(() {
      _isLoadingData = true;
    });

    // Gunakan AsyncHelper untuk operasi aman
    AsyncHelper.runWithMounted(
      state: this,
      operation: () async {
        // Muat semua frasa dengan force refresh untuk memastikan data terbaru
        await phraseProvider.loadPhrases(
          userId: authProvider.userId,
          isFavorite: null, // Set null untuk menampilkan semua frasa
          forceRefresh: true, // Paksa refresh untuk memastikan data akurat
        );
        return true;
      },
      onComplete: (_) {
        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
        }
      },
      onError: (e) {
        print('Error showing all phrases: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingData = false;
          });
        }
      },
    );
  }

  // Menampilkan hanya frasa favorit
  void _showFavoritePhrases() {
    setState(() {
      _isShowingFavorites = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phraseProvider = Provider.of<PhraseProvider>(context, listen: false);

    // Set loading state untuk menunjukkan proses sedang berjalan
    setState(() {
      _isLoadingData = true;
    });

    // Gunakan AsyncHelper untuk operasi aman
    AsyncHelper.runWithMounted(
      state: this,
      operation: () async {
        // Muat frasa favorit dengan force refresh untuk memastikan data terbaru
        await phraseProvider.loadPhrases(
          userId: authProvider.userId,
          isFavorite: true, // Filter hanya frasa favorit
          forceRefresh: true, // Paksa refresh untuk memastikan data akurat
        );

        // Validasi hasil - pastikan hanya frasa favorit yang tampil
        final loadedPhrases = phraseProvider.phrases;
        final nonFavoritePhrases =
            loadedPhrases.where((p) => !p.isFavorite).toList();

        if (nonFavoritePhrases.isNotEmpty) {
          print(
              "Warning: Found ${nonFavoritePhrases.length} non-favorite phrases after filtering");
          // Filter lagi di sisi klien untuk memastikan
          final filteredPhrases =
              loadedPhrases.where((p) => p.isFavorite).toList();

          // Update list phrases secara manual jika perlu
          if (filteredPhrases.length != loadedPhrases.length) {
            print(
                "Manually filtering to ${filteredPhrases.length} favorite phrases");
            // Ini akan memanggil metode internal di PhraseProvider
            await phraseProvider.setFilteredPhrases(filteredPhrases);
          }
        }

        return true;
      },
      onComplete: (_) {
        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
        }
      },
      onError: (e) {
        print('Error showing favorite phrases: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingData = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final phraseProvider = Provider.of<PhraseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isShowingFavorites ? 'Frasa Favorit' : 'Frasa Saya'),
        actions: [
          // Tombol filter favorit dengan indikator status aktif
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: _isShowingFavorites ? Colors.red : null,
            ),
            onPressed: _isLoadingData
                ? null
                : () {
                    // Toggle status filter favorit
                    _isShowingFavorites
                        ? _showAllPhrases()
                        : _showFavoritePhrases();
                  },
            tooltip:
                _isShowingFavorites ? 'Tampilkan Semua' : 'Tampilkan Favorit',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingData
                ? null
                : () {
                    // Hanya refresh jika tidak sedang loading
                    _loadPhrases();
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
                // Tunggu pengguna selesai mengetik dengan debounce yang lebih lama
                Future.delayed(const Duration(milliseconds: 500), () {
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
              onRefresh: () async {
                // Hindari refresh jika sudah sedang loading
                if (!_isLoadingData) {
                  await phraseProvider.refreshPhrases(
                    userId: authProvider.userId,
                    isFavorite: _isShowingFavorites
                        ? true
                        : null, // Pertahankan filter favorit saat refresh
                  );
                }
              },
              child: phraseProvider.phrases.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: phraseProvider.phrases.length,
                      itemBuilder: (context, index) {
                        final phrase = phraseProvider.phrases[index];

                        // Skip frasa yang tidak favorit jika filter favorit aktif
                        if (_isShowingFavorites && !phrase.isFavorite) {
                          return const SizedBox.shrink(); // Widget kosong
                        }

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
