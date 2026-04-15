import 'package:flutter/material.dart';
import '../../services/court_service.dart';
import '../../models/court_model.dart';
import 'court_detail_screen.dart';

class CourtListScreen extends StatefulWidget {
  final String sportType;
  final String sportLabel;
  final Color sportColor;
  final IconData sportIcon;

  const CourtListScreen({
    super.key,
    required this.sportType,
    required this.sportLabel,
    required this.sportColor,
    required this.sportIcon,
  });

  @override
  State<CourtListScreen> createState() => _CourtListScreenState();
}

class _CourtListScreenState extends State<CourtListScreen> {
  final _courtService = CourtService();
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
      final courts = await _courtService.getCourts(
        sportType: widget.sportType,
      );
      setState(() {
        _courts = courts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: widget.sportColor,
        foregroundColor: Colors.white,
        title: Text(widget.sportLabel),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.sportIcon,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada lapangan tersedia',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCourts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _courts.length,
                    itemBuilder: (context, index) {
                      final court = _courts[index];
                      return _buildCourtCard(court);
                    },
                  ),
                ),
    );
  }

  Widget _buildCourtCard(CourtModel court) {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourtDetailScreen(court: court),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.sportColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.sportIcon,
                  color: widget.sportColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      court.description ?? '-',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8,
                            color: court.isActive
                                ? Colors.green
                                : Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          court.isActive ? 'Tersedia' : 'Tidak tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            color: court.isActive
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}