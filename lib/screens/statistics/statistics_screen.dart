import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/study_session.dart';
import '../../providers/study_provider.dart';
import '../../providers/phrase_provider.dart';
import '../../providers/auth_provider.dart'; // Tambahkan import auth provider
import '../../utils/async_helper.dart'; // Tambahkan helper

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StudySession> _sessions = [];
  bool _isLoading = true;
  bool _isLoadingData = false; // Flag untuk mencegah multiple load
  String? _error;
  int _totalPhrases = 0;
  int _favoriteCount = 0;
  DateTime _lastLoadTime = DateTime.now().subtract(const Duration(minutes: 5));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Schedule loading after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _throttledLoadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi untuk throttle load data
  void _throttledLoadStatistics() {
    final now = DateTime.now();
    final difference = now.difference(_lastLoadTime);

    // Hanya reload jika sudah lewat 30 detik dari load terakhir
    if (difference.inSeconds > 30 && !_isLoadingData) {
      _loadStatistics();
      _lastLoadTime = now;
    }
  }

  Future<void> _loadStatistics() async {
    // Hindari multiple loading
    if (_isLoadingData) return;
    _isLoadingData = true;

    // PERBAIKAN: Gunakan AsyncHelper untuk operasi async yang lebih aman
    AsyncHelper.runWithMounted(
      state: this,
      operation: () async {
        // PERBAIKAN: Validasi user ID dan session
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Cek dan refresh session jika perlu
        if (!authProvider.isAuthenticated || authProvider.userId.isEmpty) {
          print(
              "Warning: User session invalid in StatisticsScreen, attempting to refresh");
          final refreshed = await authProvider.checkAndFixSession();
          if (!refreshed) {
            throw Exception("Sesi login tidak valid. Silakan login kembali.");
          }
        }

        final userId = authProvider.userId;

        if (userId.isEmpty) {
          throw Exception("Anda harus login untuk melihat statistik");
        }

        print('Loading statistics for user: $userId');

        // PERBAIKAN: Gunakan StudyProvider untuk mendapatkan sesi belajar
        final studyProvider =
            Provider.of<StudyProvider>(context, listen: false);
        await studyProvider.loadSessions(userId);
        _sessions = studyProvider.sessions;

        // Get total phrases and favorites
        final phraseProvider =
            Provider.of<PhraseProvider>(context, listen: false);
        await phraseProvider.loadPhrases(userId: userId);
        _totalPhrases = phraseProvider.phrases.length;
        _favoriteCount =
            phraseProvider.phrases.where((p) => p.isFavorite).length;

        print(
            'Statistics loaded: ${_sessions.length} sessions, $_totalPhrases phrases');
        return true;
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
        print('Error loading statistics: $e');
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
            _isLoadingData = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        centerTitle: true,
        actions: [
          // PERBAIKAN: Tambahkan tombol refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingData ? null : _loadStatistics,
            tooltip: 'Muat Ulang Statistik',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Performa'),
            Tab(text: 'Sesi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoadingData ? null : _loadStatistics,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildPerformanceTab(),
                    _buildSessionsTab(),
                  ],
                ),
    );
  }

  Widget _buildSummaryTab() {
    // Hitung total waktu belajar (dalam menit)
    final totalStudyTime = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );

    // Hitung rata-rata akurasi
    double averageAccuracy = 0;
    if (_sessions.isNotEmpty) {
      averageAccuracy = _sessions.fold<double>(
            0,
            (sum, session) => sum + session.accuracyPercentage,
          ) /
          _sessions.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu ringkasan
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Belajar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statistik dalam grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildStatCard(
                        'Total Frasa',
                        '$_totalPhrases',
                        Icons.translate,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Frasa Favorit',
                        '$_favoriteCount',
                        Icons.favorite,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'Total Sesi',
                        '${_sessions.length}',
                        Icons.history_edu,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Waktu Belajar',
                        '${totalStudyTime}m',
                        Icons.timer,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Akurasi rata-rata
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akurasi Rata-rata',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Circular progress indicator
                  Center(
                    child: SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              height: 150,
                              width: 150,
                              child: CircularProgressIndicator(
                                value: averageAccuracy / 100,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getAccuracyColor(averageAccuracy),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${averageAccuracy.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Note tentang statistik
          if (_sessions.isEmpty) ...[
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Selesaikan beberapa sesi latihan untuk melihat statistik lebih lengkap.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data performa.\nSelesaikan beberapa sesi latihan terlebih dahulu.',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Data untuk grafik
    final last7Sessions = _sessions.take(7).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akurasi 7 Sesi Terakhir',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grafik akurasi
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= last7Sessions.length ||
                              value.toInt() < 0) {
                            return const SizedBox();
                          }
                          final session = last7Sessions[
                              last7Sessions.length - 1 - value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(session.startTime),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: last7Sessions.length.toDouble() - 1,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(last7Sessions.length, (index) {
                      final session =
                          last7Sessions[last7Sessions.length - 1 - index];
                      return FlSpot(
                        index.toDouble(),
                        session.accuracyPercentage,
                      );
                    }),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Waktu Belajar per Sesi (menit)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grafik waktu belajar
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: last7Sessions
                        .fold<int>(
                          0,
                          (max, session) => session.durationMinutes > max
                              ? session.durationMinutes
                              : max,
                        )
                        .toDouble() *
                    1.2,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= last7Sessions.length ||
                              value.toInt() < 0) {
                            return const SizedBox();
                          }
                          final session = last7Sessions[
                              last7Sessions.length - 1 - value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(session.startTime),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  last7Sessions.length,
                  (index) {
                    final session =
                        last7Sessions[last7Sessions.length - 1 - index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: session.durationMinutes.toDouble(),
                          color: Colors.orange,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada sesi belajar.\nMulai sesi belajar di tab Belajar.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isCompleted = session.endTime != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAccuracyColor(session.accuracyPercentage)
                  .withOpacity(0.2),
              child: Icon(
                _getSessionTypeIcon(session.sessionType),
                color: _getAccuracyColor(session.accuracyPercentage),
              ),
            ),
            title: Text(
              'Sesi ${session.sessionType.split('.').last}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(session.startTime),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: _getAccuracyColor(session.accuracyPercentage),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${session.accuracyPercentage.toStringAsFixed(1)}% benar',
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text('${session.durationMinutes}m'),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Sesi tidak selesai',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            trailing: CircleAvatar(
              radius: 18,
              backgroundColor: _getAccuracyColor(session.accuracyPercentage)
                  .withOpacity(0.2),
              child: Text(
                '${session.correctAnswers}/${session.totalPhrases}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getAccuracyColor(session.accuracyPercentage),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) {
      return Colors.green;
    } else if (accuracy >= 60) {
      return Colors.blue;
    } else if (accuracy >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getSessionTypeIcon(String sessionType) {
    if (sessionType.contains('flashcard')) {
      return Icons.flip;
    } else if (sessionType.contains('quiz')) {
      return Icons.quiz;
    } else if (sessionType.contains('typing')) {
      return Icons.keyboard;
    } else {
      return Icons.school;
    }
  }
}
