import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../models/booking_model.dart';
import '../../utils/error_handler.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _bookingService = BookingService();
  final _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  late TabController _tabController;
  final List<String> _tabs = [
    'Semua',
    'Menunggu',
    'Dikonfirmasi',
    'Selesai',
    'Dibatalkan'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();

    // Listener scroll untuk load more
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreBookings();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
      _bookings = [];
    });

    try {
      final profile = await _authService.getCurrentUser();
      if (profile == null) return;

      final response = await Supabase.instance.client
          .from('bookings')
          .select('''
            *,
            courts(name, sport_type),
            time_slots(start_time, end_time),
            payments(status, method, payment_method_detail, payment_proof)
          ''')
          .eq('user_id', profile.id)
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      final bookings = (response as List)
          .map((item) => BookingModel.fromJson(item))
          .toList();

      setState(() {
        _bookings = bookings;
        _hasMore = bookings.length == _pageSize;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMoreBookings() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final profile = await _authService.getCurrentUser();
      if (profile == null) return;

      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;

      final response = await Supabase.instance.client
          .from('bookings')
          .select('''
            *,
            courts(name, sport_type),
            time_slots(start_time, end_time),
            payments(status, method, payment_method_detail, payment_proof)
          ''')
          .eq('user_id', profile.id)
          .order('created_at', ascending: false)
          .range(from, to);

      final newBookings = (response as List)
          .map((item) => BookingModel.fromJson(item))
          .toList();

      setState(() {
        _bookings.addAll(newBookings);
        _hasMore = newBookings.length == _pageSize;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  List<BookingModel> _filteredBookings(String tab) {
    switch (tab) {
      case 'Menunggu':
        return _bookings.where((b) => b.status == 'pending').toList();
      case 'Dikonfirmasi':
        return _bookings.where((b) => b.status == 'confirmed').toList();
      case 'Selesai':
        return _bookings.where((b) => b.status == 'done').toList();
      case 'Dibatalkan':
        return _bookings.where((b) => b.status == 'cancelled').toList();
      default:
        return _bookings;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'done': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed': return 'Dikonfirmasi';
      case 'pending': return 'Menunggu';
      case 'cancelled': return 'Dibatalkan';
      case 'done': return 'Selesai';
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle;
      case 'pending': return Icons.hourglass_empty;
      case 'cancelled': return Icons.cancel;
      case 'done': return Icons.sports;
      default: return Icons.info;
    }
  }

  Color _paymentStatusColor(String? status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'waiting_confirmation': return Colors.orange;
      case 'pending': return Colors.grey;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _paymentStatusLabel(String? status) {
    switch (status) {
      case 'paid': return 'Lunas';
      case 'waiting_confirmation': return 'Menunggu Verifikasi';
      case 'pending': return 'Belum Bayar';
      case 'failed': return 'Gagal';
      default: return 'Belum Bayar';
    }
  }

  IconData _paymentStatusIcon(String? status) {
    switch (status) {
      case 'paid': return Icons.check_circle;
      case 'waiting_confirmation': return Icons.hourglass_top;
      case 'pending': return Icons.payment;
      case 'failed': return Icons.error;
      default: return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Booking',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final bookings = _filteredBookings(tab);
                return RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada booking',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: tab == 'Semua'
                              ? _scrollController
                              : null,
                          padding: const EdgeInsets.all(16),
                          itemCount: bookings.length +
                              (tab == 'Semua' && _isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Loading indicator di bawah list
                            if (index == bookings.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildBookingCard(bookings[index]);
                          },
                        ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _statusColor(booking.status);
    final paymentColor = _paymentStatusColor(booking.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header status booking
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(booking.status), color: statusColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(booking.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(booking.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.sports, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.courtName ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${booking.startTime ?? '-'} - ${booking.endTime ?? '-'}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(booking.bookingDate),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(booking.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Status pembayaran
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: paymentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: paymentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _paymentStatusIcon(booking.paymentStatus),
                        color: paymentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Pembayaran',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _paymentStatusLabel(booking.paymentStatus),
                              style: TextStyle(
                                color: paymentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (booking.paymentMethod != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'via ${booking.paymentMethod}',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (booking.paymentProof != null)
                        GestureDetector(
                          onTap: () => _showProofImage(booking.paymentProof!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              booking.paymentProof!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (booking.status == 'pending') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(booking.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Batalkan Booking'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bukti Pembayaran',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Booking?'),
        content: const Text('Apakah kamu yakin ingin membatalkan booking ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bookingService.cancelBooking(bookingId);
      _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil dibatalkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}