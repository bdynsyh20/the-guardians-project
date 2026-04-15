import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/court_model.dart';

class EditPriceScreen extends StatefulWidget {
  final CourtModel court;
  const EditPriceScreen({super.key, required this.court});

  @override
  State<EditPriceScreen> createState() => _EditPriceScreenState();
}

class _EditPriceScreenState extends State<EditPriceScreen> {
  final _supabase = Supabase.instance.client;

  // Controller untuk harga weekday & weekend
  final _weekdayController = TextEditingController();
  final _weekendController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  double _currentWeekdayPrice = 0;
  double _currentWeekendPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrices();
  }

  @override
  void dispose() {
    _weekdayController.dispose();
    _weekendController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPrices() async {
    setState(() => _isLoading = true);
    try {
      // Ambil harga weekday
      final weekdayResponse = await _supabase
          .from('time_slots')
          .select('price')
          .eq('court_id', widget.court.id)
          .eq('day_type', 'weekday')
          .limit(1)
          .single();

      // Ambil harga weekend
      final weekendResponse = await _supabase
          .from('time_slots')
          .select('price')
          .eq('court_id', widget.court.id)
          .eq('day_type', 'weekend')
          .limit(1)
          .single();

      setState(() {
        _currentWeekdayPrice =
            (weekdayResponse['price'] as num).toDouble();
        _currentWeekendPrice =
            (weekendResponse['price'] as num).toDouble();

        _weekdayController.text =
            _currentWeekdayPrice.toStringAsFixed(0);
        _weekendController.text =
            _currentWeekendPrice.toStringAsFixed(0);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrices() async {
    // Validasi input tidak kosong
    if (_weekdayController.text.isEmpty ||
        _weekendController.text.isEmpty) {
      _showSnackbar('Harga tidak boleh kosong', isError: true);
      return;
    }

    final weekdayPrice = double.tryParse(_weekdayController.text);
    final weekendPrice = double.tryParse(_weekendController.text);

    if (weekdayPrice == null || weekendPrice == null) {
      _showSnackbar('Harga harus berupa angka', isError: true);
      return;
    }

    if (weekdayPrice <= 0 || weekendPrice <= 0) {
      _showSnackbar('Harga harus lebih dari 0', isError: true);
      return;
    }

    if (weekendPrice < weekdayPrice) {
      _showSnackbar('Harga weekend tidak boleh lebih murah dari weekday',
          isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update semua slot weekday
      await _supabase
          .from('time_slots')
          .update({'price': weekdayPrice})
          .eq('court_id', widget.court.id)
          .eq('day_type', 'weekday');

      // Update semua slot weekend
      await _supabase
          .from('time_slots')
          .update({'price': weekendPrice})
          .eq('court_id', widget.court.id)
          .eq('day_type', 'weekend');

      if (!mounted) return;
      _showSnackbar('Harga berhasil diupdate!');

      // Kembali ke halaman sebelumnya setelah 1 detik
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Gagal update harga', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: Text('Edit Harga — ${widget.court.name}'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info lapangan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Perubahan harga akan berlaku untuk semua slot waktu ${widget.court.name}',
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Harga saat ini
                  _sectionLabel('Harga Saat Ini', color),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _currentPriceCard(
                          'Weekday',
                          _formatPrice(_currentWeekdayPrice),
                          Icons.calendar_today,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _currentPriceCard(
                          'Weekend',
                          _formatPrice(_currentWeekendPrice),
                          Icons.weekend,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Form edit harga
                  _sectionLabel('Ubah Harga', color),
                  const SizedBox(height: 12),

                  // Input weekday
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga Weekday',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Senin - Jumat',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _weekdayController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.green.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Colors.green, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Input weekend
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.weekend,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga Weekend',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Sabtu - Minggu',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _weekendController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.orange.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Colors.orange, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePrices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              'Simpan Harga',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
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

  Widget _currentPriceCard(
      String label, String price, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'per jam',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}