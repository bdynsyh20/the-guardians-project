import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../models/booking_model.dart';
import '../../models/profile_model.dart';
import '../auth/login_screen.dart';
import 'manage_booking_screen.dart';
import 'manage_court_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _authService = AuthService();
  final _bookingService = BookingService();
  final _notifService = NotificationService();

  ProfileModel? _profile;
  List<BookingModel> _recentBookings = [];
  int _pendingCount = 0;
  int _confirmedCount = 0;
  int _totalCount = 0;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getCurrentUser();
      final bookings = await _bookingService.getAllBookings();

      setState(() {
        _profile = profile;
        _recentBookings = bookings.take(5).toList();
        _pendingCount =
            bookings.where((b) => b.status == 'pending').length;
        _confirmedCount =
            bookings.where((b) => b.status == 'confirmed').length;
        _totalCount = bookings.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout?'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 1 - Dashboard
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header admin
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            color: Colors.green[800],
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Admin Panel',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _profile?.name ?? 'Admin',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout),
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),

                          // Statistik
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _statCard(
                                  'Total Booking',
                                  _totalCount.toString(),
                                  Icons.receipt_long,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                _statCard(
                                  'Menunggu',
                                  _pendingCount.toString(),
                                  Icons.hourglass_empty,
                                  Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                _statCard(
                                  'Dikonfirmasi',
                                  _confirmedCount.toString(),
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),

                          // Menu cepat
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _quickMenu(
                                    Icons.list_alt,
                                    'Kelola Booking',
                                    Colors.blue,
                                    () => setState(
                                        () => _currentIndex = 1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _quickMenu(
                                    Icons.sports,
                                    'Kelola Lapangan',
                                    Colors.green,
                                    () => setState(
                                        () => _currentIndex = 2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Booking terbaru
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.green[800],
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Booking Terbaru',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_recentBookings.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Belum ada booking',
                                  style: TextStyle(
                                      color: Colors.grey[500]),
                                ),
                              ),
                            )
                          else
                            ..._recentBookings.map(
                              (booking) => Container(
                                margin: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                                booking.status)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.sports,
                                        color: _statusColor(
                                            booking.status),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booking.courtName ??
                                                'Lapangan',
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatPrice(
                                                booking.totalPrice),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                                booking.status)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _statusLabel(booking.status),
                                        style: TextStyle(
                                          color: _statusColor(
                                              booking.status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

            // Tab 2 - Kelola Booking
            const ManageBookingScreen(),

            // Tab 3 - Kelola Lapangan
            const ManageCourtScreen(),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_outlined),
            activeIcon: Icon(Icons.sports),
            label: 'Lapangan',
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
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
      ),
    );
  }

  Widget _quickMenu(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}