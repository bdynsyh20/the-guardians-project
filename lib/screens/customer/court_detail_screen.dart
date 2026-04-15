import 'package:flutter/material.dart';
import '../../models/court_model.dart';
import '../../models/time_slot_model.dart';
import '../../services/court_service.dart';
import 'booking_screen.dart';

class CourtDetailScreen extends StatefulWidget {
  final CourtModel court;
  const CourtDetailScreen({super.key, required this.court});

  @override
  State<CourtDetailScreen> createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends State<CourtDetailScreen> {
  final _courtService = CourtService();
  List<TimeSlotModel> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    try {
      // Default tampilkan weekday dulu di halaman detail
      final slots = await _courtService.getTimeSlots(
        widget.court.id,
        dayType: 'weekday',
      );
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  Color _sportColor(String sportType) {
    switch (sportType) {
      case 'badminton': return const Color(0xFF1565C0);
      case 'soccer': return const Color(0xFF2E7D32);
      case 'mini_soccer': return const Color(0xFF00838F);
      case 'volleyball': return const Color(0xFFE65100);
      case 'basketball': return const Color(0xFF6A1B9A);
      case 'billiard': return const Color(0xFF4E342E);
      default: return Colors.blue;
    }
  }

  IconData _getSportIcon(String sportType) {
    switch (sportType) {
      case 'badminton': return Icons.sports_tennis;
      case 'soccer': return Icons.sports_soccer;
      case 'mini_soccer': return Icons.sports_soccer;
      case 'volleyball': return Icons.sports_volleyball;
      case 'basketball': return Icons.sports_basketball;
      case 'billiard': return Icons.circle;
      default: return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _sportColor(widget.court.sportType);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Header dengan warna olahraga
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Icon besar di background
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        _getSportIcon(widget.court.sportType),
                        size: 180,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Info lapangan
                    Positioned(
                      left: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.court.sportType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.court.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                widget.court.description ?? '-',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status lapangan
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getSportIcon(widget.court.sportType),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Lapangan',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: widget.court.isActive
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.court.isActive
                                ? 'Lapangan Tersedia'
                                : 'Lapangan Tidak Tersedia',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: widget.court.isActive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Label slot waktu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
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
                  const Text(
                    'Slot Waktu Tersedia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daftar slot waktu
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _slots.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.schedule,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada slot tersedia',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final slot = _slots[index];
                            return _buildSlotCard(slot, color);
                          },
                          childCount: _slots.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Tombol Pesan Sekarang
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.court.isActive
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(court: widget.court),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Pesan Sekarang',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(TimeSlotModel slot, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slot.isAvailable ? color.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Icon jam
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: slot.isAvailable
                  ? color.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.access_time,
              color: slot.isAvailable ? color : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Jam
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slot.isAvailable ? 'Tersedia' : 'Tidak tersedia',
                  style: TextStyle(
                    fontSize: 12,
                    color: slot.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Harga
          Text(
            _formatPrice(slot.price),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}