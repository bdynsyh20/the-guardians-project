import 'package:flutter/material.dart';
import '../../models/court_model.dart';
import '../../models/time_slot_model.dart';
import '../../services/court_service.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import 'payment_screen.dart';
import '../../utils/error_handler.dart';


class BookingScreen extends StatefulWidget {
  final CourtModel court;
  const BookingScreen({super.key, required this.court});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _courtService = CourtService();
  final _bookingService = BookingService();
  final _authService = AuthService();

  List<TimeSlotModel> _slots = [];
  List<String> _bookedSlotIds = []; // tambah ini
  TimeSlotModel? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isBooking = false;
  bool _isPastSlot(TimeSlotModel slot) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    if (!isToday) return false;

    final parts = slot.startTime.split(':');
    final slotHour = int.parse(parts[0]);
    final slotMinute = int.parse(parts[1].split(':')[0]);
    final slotTime = DateTime(
      now.year, now.month, now.day,
      slotHour, slotMinute,
    );
    return slotTime.isBefore(now);
  }

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  String _getDayType(DateTime date) {
    // 6 = Sabtu, 7 = Minggu
    return (date.weekday == 6 || date.weekday == 7) ? 'weekend' : 'weekday';
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    try {
      final dayType = _getDayType(_selectedDate);

      final results = await Future.wait([
        _courtService.getTimeSlots(
          widget.court.id,
          dayType: dayType,
        ),
        _bookingService.getBookedSlots(
          courtId: widget.court.id,
          bookingDate: _selectedDate,
        ),
      ]);

      final allSlots = results[0] as List<TimeSlotModel>;
      final bookedIds = results[1] as List<String>;

      // Filter slot yang sudah lewat kalau hari ini
      final now = DateTime.now();
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;

      setState(() {
        _slots = allSlots;
        _bookedSlotIds = bookedIds;

        // Kalau hari ini, tambahkan slot yang sudah lewat ke bookedSlotIds
        if (isToday) {
          for (final slot in allSlots) {
            final parts = slot.startTime.split(':');
            final slotHour = int.parse(parts[0]);
            final slotMinute = int.parse(parts[1].split(':')[0]);
            final slotTime = DateTime(
              now.year, now.month, now.day,
              slotHour, slotMinute,
            );
            // Kalau jam slot sudah lewat dari sekarang
            if (slotTime.isBefore(now) && !_bookedSlotIds.contains(slot.id)) {
              _bookedSlotIds.add(slot.id);
            }
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _sportColor(widget.court.sportType),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      _loadSlots(); // reload slot sesuai hari baru
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      _showSnackbar('Pilih slot waktu dulu', isError: true);
      return;
    }

    setState(() => _isBooking = true);

    try {
      final profile = await _authService.getCurrentUser();
      if (profile == null) {
        _showSnackbar('Session habis, silakan login ulang', isError: true);
        return;
      }

      final bookingResult = await _bookingService.createBooking(
        userId: profile.id,
        courtId: widget.court.id,
        slotId: _selectedSlot!.id,
        bookingDate: _selectedDate,
        totalPrice: _selectedSlot!.price,
      );

      if (!mounted) return;

      // Tampilkan dialog sukses
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Berhasil!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking kamu sedang menunggu konfirmasi admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _infoRow('Lapangan', widget.court.name),
                    const SizedBox(height: 4),
                    _infoRow('Tanggal', _formatDate(_selectedDate)),
                    const SizedBox(height: 4),
                    _infoRow(
                      'Waktu',
                      '${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}',
                    ),
                    const SizedBox(height: 4),
                    _infoRow('Total', _formatPrice(_selectedSlot!.price)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  // Navigasi ke halaman payment
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        booking: bookingResult,
                        court: widget.court,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Lanjut ke Pembayaran'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(ErrorHandler.getMessage(e), isError: true);
      
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      _showSnackbar(
        message.contains('sudah dipesan')
            ? 'Maaf, slot ini baru saja dipesan orang lain!'
            : 'Gagal booking, coba lagi',
        isError: true,
      );
      // Reload slots supaya tampilan terupdate
      _loadSlots();
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final color = _sportColor(widget.court.sportType);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text('Pesan ${widget.court.name}'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilih Tanggal
                  _sectionLabel('Pilih Tanggal', color),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.calendar_today,
                                color: color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal Bermain',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getDayType(_selectedDate) == 'weekend'
                                      ? 'Weekend — harga weekend berlaku'
                                      : 'Weekday — harga weekday berlaku',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getDayType(_selectedDate) == 'weekend'
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pilih Slot Waktu
                  _sectionLabel('Pilih Slot Waktu', color),
                  const SizedBox(height: 10),
                  ..._slots.map((slot) => _buildSlotItem(slot, color)),

                  const SizedBox(height: 24),

                  // Ringkasan Booking
                  if (_selectedSlot != null) ...[
                    _sectionLabel('Ringkasan Booking', color),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Lapangan', widget.court.name),
                          const Divider(height: 20),
                          _summaryRow('Tanggal', _formatDate(_selectedDate)),
                          const Divider(height: 20),
                          _summaryRow(
                            'Waktu',
                            '${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}',
                          ),
                          const Divider(height: 20),
                          _summaryRow(
                            'Total Bayar',
                            _formatPrice(_selectedSlot!.price),
                            isTotal: true,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),

      // Tombol Konfirmasi
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
          onPressed: _isBooking || _selectedSlot == null
              ? null
              : _confirmBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isBooking
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _selectedSlot == null
                      ? 'Pilih Slot Waktu Dulu'
                      : 'Konfirmasi Booking — ${_formatPrice(_selectedSlot!.price)}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildSlotItem(TimeSlotModel slot, Color color) {
    final isSelected = _selectedSlot?.id == slot.id;
    final isBooked = _bookedSlotIds.contains(slot.id);

    return GestureDetector(
      onTap: isBooked || !slot.isAvailable
          ? null
          : () => setState(() => _selectedSlot = slot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.grey[100]
              : isSelected
                  ? color
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBooked
                ? Colors.grey[300]!
                : isSelected
                    ? color
                    : color.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isBooked ? Icons.block : Icons.access_time,
              color: isBooked
                  ? Colors.grey[400]
                  : isSelected
                      ? Colors.white
                      : color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${slot.startTime} - ${slot.endTime}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isBooked
                      ? Colors.grey[400]
                      : isSelected
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ),

            // Badge status
            // Badge status
            if (isBooked)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isPastSlot(slot) ? 'Sudah Lewat' : 'Sudah Dipesan',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                _formatPrice(slot.price),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isTotal ? 15 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? color : Colors.black87,
          ),
        ),
      ],
    );
  }
}