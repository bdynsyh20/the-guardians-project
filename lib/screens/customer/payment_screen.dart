import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking_model.dart';
import '../../models/court_model.dart';
import '../../utils/error_handler.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final CourtModel court;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.court,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  File? _proofImage;
  String _selectedMethod = 'transfer_bca';
  bool _isUploading = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'transfer_bca',
      'label': 'Transfer BCA',
      'icon': Icons.account_balance,
      'color': Colors.blue,
      'detail': 'BCA',
      'number': '1234567890',
      'name': 'Arena Sport Center',
    },
    {
      'id': 'transfer_mandiri',
      'label': 'Transfer Mandiri',
      'icon': Icons.account_balance,
      'color': Colors.yellow[700]!,
      'detail': 'Mandiri',
      'number': '0987654321',
      'name': 'Arena Sport Center',
    },
    {
      'id': 'qris',
      'label': 'QRIS',
      'icon': Icons.qr_code,
      'color': Colors.purple,
      'detail': 'QRIS',
      'number': '1234-5678-9012-3456',
      'name': 'Arena Sport Center',
    },
    {
      'id': 'ewallet',
      'label': 'GoPay / OVO / Dana',
      'icon': Icons.wallet,
      'color': Colors.green,
      'detail': 'E-Wallet',
      'number': '08123456789',
      'name': 'Arena Sport Center',
    },
  ];

  Map<String, dynamic> get _selectedMethodData =>
      _paymentMethods.firstWhere((m) => m['id'] == _selectedMethod);

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (picked != null) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  Future<void> _submitPayment() async {
    if (_proofImage == null) {
      _showSnackbar('Upload bukti pembayaran dulu', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload foto ke Supabase Storage
      final fileName =
          'proof_${widget.booking.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('payment-proofs')
          .upload(fileName, _proofImage!);

      // Ambil URL foto
      final imageUrl = _supabase.storage
          .from('payment-proofs')
          .getPublicUrl(fileName);

      // Update data payment di database
      await _supabase
          .from('payments')
          .update({
            'method': _selectedMethod,
            'payment_method_detail': _selectedMethodData['label'],
            'payment_proof': imageUrl,
            'status': 'waiting_confirmation',
          })
          .eq('booking_id', widget.booking.id);

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
                'Bukti Pembayaran Terkirim!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pembayaran kamu sedang diverifikasi oleh admin. Kamu akan mendapat notifikasi setelah dikonfirmasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
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
                  Navigator.pop(context); // kembali ke booking
                  Navigator.pop(context); // kembali ke detail
                  Navigator.pop(context); // kembali ke list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Oke'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
        _showSnackbar(ErrorHandler.getMessage(e), isError: true);

      if (!mounted) return;
      _showSnackbar('Gagal upload bukti pembayaran', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringkasan booking
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Divider(height: 20),
                  _summaryRow('Lapangan', widget.court.name),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Tanggal',
                    _formatDate(widget.booking.bookingDate),
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Waktu',
                    '${widget.booking.startTime} - ${widget.booking.endTime}',
                  ),
                  const Divider(height: 20),
                  _summaryRow(
                    'Total Bayar',
                    _formatPrice(widget.booking.totalPrice),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pilih metode pembayaran
            _sectionLabel('Pilih Metode Pembayaran'),
            const SizedBox(height: 12),

            ..._paymentMethods.map((method) {
              final isSelected = _selectedMethod == method['id'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedMethod = method['id']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (method['color'] as Color)
                          : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (method['color'] as Color)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          method['icon'] as IconData,
                          color: method['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        method['label'],
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: method['color'] as Color,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Instruksi pembayaran
            _sectionLabel('Instruksi Pembayaran'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_selectedMethodData['color'] as Color)
                      .withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedMethodData['icon'] as IconData,
                        color: _selectedMethodData['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedMethodData['label'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Nomor tujuan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMethodData['detail'],
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedMethodData['number'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'a/n ${_selectedMethodData['name']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Tombol copy
                      IconButton(
                        onPressed: () {
                          _showSnackbar(
                              'Nomor disalin: ${_selectedMethodData['number']}');
                        },
                        icon: const Icon(Icons.copy),
                        color: Colors.grey[400],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Total yang harus dibayar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Transfer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatPrice(widget.booking.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Transfer sesuai nominal. Lebih atau kurang 1 rupiah akan ditolak.',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Upload bukti pembayaran
            _sectionLabel('Upload Bukti Pembayaran'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: _proofImage != null ? 200 : 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _proofImage != null
                        ? Colors.green
                        : Colors.grey[300]!,
                    width: _proofImage != null ? 2 : 1,
                    style: _proofImage != null
                        ? BorderStyle.solid
                        : BorderStyle.solid,
                  ),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _proofImage!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _proofImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 36,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk upload bukti pembayaran',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Foto struk transfer / screenshot',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Tombol konfirmasi
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
          onPressed: _isUploading || _proofImage == null
              ? null
              : _submitPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isUploading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Mengupload...'),
                  ],
                )
              : Text(
                  _proofImage == null
                      ? 'Upload Bukti Pembayaran Dulu'
                      : 'Kirim Bukti Pembayaran',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.green,
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

  Widget _summaryRow(String label, String value,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isTotal ? 15 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight:
                isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 13,
            color: isTotal ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}