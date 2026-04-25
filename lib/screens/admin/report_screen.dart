import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;

  // Data statistik
  double _todayRevenue = 0;
  double _weekRevenue = 0;
  double _monthRevenue = 0;
  int _totalBookings = 0;
  int _pendingBookings = 0;
  int _confirmedBookings = 0;
  int _cancelledBookings = 0;

  // Data grafik - booking per hari 7 hari terakhir
  List<Map<String, dynamic>> _dailyBookings = [];

  // Data lapangan terpopuler
  List<Map<String, dynamic>> _popularCourts = [];

  // Data per jenis olahraga
  List<Map<String, dynamic>> _sportStats = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadRevenueStats(),
        _loadBookingStats(),
        _loadDailyBookings(),
        _loadPopularCourts(),
        _loadSportStats(),
      ]);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRevenueStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    // Ambil semua payment yang sudah paid
    final response = await _supabase
        .from('payments')
        .select('amount, paid_at')
        .eq('status', 'paid');

    double today = 0, week = 0, month = 0;

    for (final item in response as List) {
      if (item['paid_at'] == null) continue;
      final paidAt = DateTime.parse(item['paid_at']);
      final amount = (item['amount'] as num).toDouble();

      if (paidAt.isAfter(todayStart)) today += amount;
      if (paidAt.isAfter(weekStart)) week += amount;
      if (paidAt.isAfter(monthStart)) month += amount;
    }

    _todayRevenue = today;
    _weekRevenue = week;
    _monthRevenue = month;
  }

  Future<void> _loadBookingStats() async {
    final response = await _supabase.from('bookings').select('status');

    int total = 0, pending = 0, confirmed = 0, cancelled = 0;

    for (final item in response as List) {
      total++;
      switch (item['status']) {
        case 'pending': pending++; break;
        case 'confirmed': confirmed++; break;
        case 'cancelled': cancelled++; break;
      }
    }

    _totalBookings = total;
    _pendingBookings = pending;
    _confirmedBookings = confirmed;
    _cancelledBookings = cancelled;
  }

  Future<void> _loadDailyBookings() async {
    final now = DateTime.now();
    final days = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('bookings')
          .select('id')
          .eq('booking_date', dateStr);

      days.add({
        'date': dateStr,
        'day': _getDayLabel(date),
        'count': (response as List).length,
      });
    }

    _dailyBookings = days;
  }

  Future<void> _loadPopularCourts() async {
    final response = await _supabase
        .from('bookings')
        .select('court_id, courts(name, sport_type)');

    final Map<String, Map<String, dynamic>> courtCount = {};

    for (final item in response as List) {
      final courtId = item['court_id'] as String;
      final courtName = item['courts']?['name'] ?? 'Unknown';
      final sportType = item['courts']?['sport_type'] ?? '';

      if (!courtCount.containsKey(courtId)) {
        courtCount[courtId] = {
          'name': courtName,
          'sport_type': sportType,
          'count': 0,
        };
      }
      courtCount[courtId]!['count'] = courtCount[courtId]!['count'] + 1;
    }

    final sorted = courtCount.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    _popularCourts = sorted.take(5).toList();
  }

  Future<void> _loadSportStats() async {
    final response = await _supabase
        .from('bookings')
        .select('courts(sport_type)');

    final Map<String, int> sportCount = {};

    for (final item in response as List) {
      final sportType = item['courts']?['sport_type'] ?? 'unknown';
      sportCount[sportType] = (sportCount[sportType] ?? 0) + 1;
    }

    _sportStats = sportCount.entries
        .map((e) => {'sport': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  String _getDayLabel(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return 'Rp ${(price / 1000000).toStringAsFixed(1)}jt';
    } else if (price >= 1000) {
      return 'Rp ${(price / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${price.toStringAsFixed(0)}';
  }

  String _sportLabel(String sportType) {
    switch (sportType) {
      case 'badminton': return 'Badminton';
      case 'soccer': return 'Futsal';
      case 'mini_soccer': return 'Mini Soccer';
      case 'volleyball': return 'Voli';
      case 'basketball': return 'Basket';
      case 'billiard': return 'Billiard';
      default: return sportType;
    }
  }

  Color _sportColor(String sportType) {
    switch (sportType) {
      case 'badminton': return const Color(0xFF1565C0);
      case 'soccer': return const Color(0xFF2E7D32);
      case 'mini_soccer': return const Color(0xFF00838F);
      case 'volleyball': return const Color(0xFFE65100);
      case 'basketball': return const Color(0xFF6A1B9A);
      case 'billiard': return const Color(0xFF4E342E);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadReportData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === PENDAPATAN ===
                    _sectionLabel('Pendapatan', Colors.green[800]!),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _revenueCard(
                            'Hari ini',
                            _todayRevenue,
                            Icons.today,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _revenueCard(
                            '7 hari',
                            _weekRevenue,
                            Icons.date_range,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _revenueCard(
                            'Bulan ini',
                            _monthRevenue,
                            Icons.calendar_month,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // === STATISTIK BOOKING ===
                    _sectionLabel('Status Booking', Colors.green[800]!),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _statItem(
                              'Total',
                              _totalBookings,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _statItem(
                              'Menunggu',
                              _pendingBookings,
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _statItem(
                              'Konfirmasi',
                              _confirmedBookings,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _statItem(
                              'Batal',
                              _cancelledBookings,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // === GRAFIK BOOKING 7 HARI ===
                    _sectionLabel('Booking 7 Hari Terakhir', Colors.green[800]!),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _dailyBookings.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Belum ada data'),
                              ),
                            )
                          : SizedBox(
                              height: 180,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (_dailyBookings
                                              .map((e) => e['count'] as int)
                                              .reduce(
                                                  (a, b) => a > b ? a : b) +
                                          2)
                                      .toDouble(),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex,
                                          rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${rod.toY.toInt()} booking',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 ||
                                              index >=
                                                  _dailyBookings.length) {
                                            return const SizedBox();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              _dailyBookings[index]['day'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        getTitlesWidget: (value, meta) {
                                          if (value % 1 != 0) {
                                            return const SizedBox();
                                          }
                                          return Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) =>
                                        FlLine(
                                      color: Colors.grey[200]!,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _dailyBookings
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: (entry.value['count'] as int)
                                              .toDouble(),
                                          color: Colors.green[700],
                                          width: 22,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // === LAPANGAN TERPOPULER ===
                    _sectionLabel('Lapangan Terpopuler', Colors.green[800]!),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _popularCourts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('Belum ada data')),
                            )
                          : Column(
                              children: _popularCourts
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final court = entry.value;
                                final maxCount = _popularCourts.isNotEmpty
                                    ? (_popularCourts[0]['count'] as int)
                                    : 1;
                                final count = court['count'] as int;
                                final ratio =
                                    maxCount > 0 ? count / maxCount : 0.0;
                                final color =
                                    _sportColor(court['sport_type'] ?? '');

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 12),
                                      child: Row(
                                        children: [
                                          // Nomor ranking
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: index == 0
                                                  ? Colors.amber
                                                  : index == 1
                                                      ? Colors.grey[400]
                                                      : Colors.brown[300],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Info lapangan
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  court['name'] ?? '-',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: ratio,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            color),
                                                    minHeight: 6,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Jumlah booking
                                          Text(
                                            '$count booking',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < _popularCourts.length - 1)
                                      Divider(
                                          height: 1,
                                          indent: 56,
                                          color: Colors.grey[200]),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // === BOOKING PER OLAHRAGA ===
                    _sectionLabel('Booking per Olahraga', Colors.green[800]!),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _sportStats.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('Belum ada data')),
                            )
                          : Column(
                              children: _sportStats.asMap().entries.map((entry) {
                                final index = entry.key;
                                final stat = entry.value;
                                final sport = stat['sport'] as String;
                                final count = stat['count'] as int;
                                final total = _totalBookings > 0
                                    ? _totalBookings
                                    : 1;
                                final percentage =
                                    (count / total * 100).toStringAsFixed(1);
                                final color = _sportColor(sport);

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _sportLabel(sport),
                                              style: const TextStyle(
                                                  fontSize: 13),
                                            ),
                                          ),
                                          Text(
                                            '$count booking',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$percentage%',
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < _sportStats.length - 1)
                                      Divider(
                                          height: 1,
                                          indent: 36,
                                          color: Colors.grey[200]),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _revenueCard(
      String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            _formatPrice(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}