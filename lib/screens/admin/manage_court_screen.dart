import 'package:flutter/material.dart';
import '../../services/court_service.dart';
import '../../models/court_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_price_screen.dart';

class ManageCourtScreen extends StatefulWidget {
  const ManageCourtScreen({super.key});

  @override
  State<ManageCourtScreen> createState() => _ManageCourtScreenState();
}

class _ManageCourtScreenState extends State<ManageCourtScreen> {
  final _courtService = CourtService();
  final _supabase = Supabase.instance.client;
  List<CourtModel> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('courts')
          .select()
          .order('sport_type');
      setState(() {
        _courts = (response as List)
            .map((item) => CourtModel.fromJson(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCourtStatus(CourtModel court) async {
    try {
      await _supabase
          .from('courts')
          .update({'is_active': !court.isActive})
          .eq('id', court.id);
      _loadCourts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            court.isActive
                ? '${court.name} dinonaktifkan'
                : '${court.name} diaktifkan',
          ),
          backgroundColor:
              court.isActive ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal update status lapangan'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kelola Lapangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _courts.length,
                itemBuilder: (context, index) {
                  return _buildCourtCard(_courts[index]);
                },
              ),
            ),
    );
  }

  Widget _buildCourtCard(CourtModel court) {
    final color = _sportColor(court.sportType);
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPriceScreen(court: court),
            ),
          );
          _loadCourts(); // refresh setelah edit
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon olahraga
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSportIcon(court.sportType),
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Info lapangan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _sportLabel(court.sportType),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      court.description ?? '-',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Kanan: toggle + tap hint
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(
                    value: court.isActive,
                    onChanged: (_) => _toggleCourtStatus(court),
                    activeColor: Colors.green,
                  ),
                  Text(
                    court.isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11,
                      color: court.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap untuk edit harga',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}