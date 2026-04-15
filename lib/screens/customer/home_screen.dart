import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/profile_model.dart';
import '../../screens/auth/login_screen.dart';
import 'history_screen.dart';
import 'court_list_screen.dart';
import 'notification_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  ProfileModel? _profile;
  bool _isLoading = true;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _sportCategories = [
    {'label': 'Badminton', 'value': 'badminton', 'icon': Icons.sports_tennis, 'color': Color(0xFF1565C0)},
    {'label': 'Futsal', 'value': 'soccer', 'icon': Icons.sports_soccer, 'color': Color(0xFF2E7D32)},
    {'label': 'Mini Soccer', 'value': 'mini_soccer', 'icon': Icons.sports_soccer, 'color': Color(0xFF00838F)},
    {'label': 'Voli', 'value': 'volleyball', 'icon': Icons.sports_volleyball, 'color': Color(0xFFE65100)},
    {'label': 'Basket', 'value': 'basketball', 'icon': Icons.sports_basketball, 'color': Color(0xFF6A1B9A)},
    {'label': 'Billiard', 'value': 'billiard', 'icon': Icons.circle, 'color': Color(0xFF4E342E)},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getCurrentUser();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onCategoryTap(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourtListScreen(
          sportType: category['value'],
          sportLabel: category['label'],
          sportColor: category['color'],
          sportIcon: category['icon'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 1 - Beranda
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${_profile?.name ?? ''}!',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mau olahraga apa hari ini?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout),
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Label pilih olahraga
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text(
                            'Pilih Olahraga',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),

                      // List kategori olahraga
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cat = _sportCategories[index];
                              return _buildCategoryCard(cat);
                            },
                            childCount: _sportCategories.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),

            // Tab 2 - Riwayat Booking
            const HistoryScreen(),

            // Tab 3 - Notifikasi
            const NotificationScreen(),

            // Tab 4 - Akun
            const AccountScreen(),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Booking Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
  final color = cat['color'] as Color;
  return GestureDetector(
    onTap: () => _onCategoryTap(cat),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color, color.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icon besar di background kanan
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              cat['icon'] as IconData,
              size: 110,
              color: Colors.white.withOpacity(0.15),
            ),
          ),

          // Konten kiri
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Icon kecil di lingkaran
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),

                // Nama olahraga
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat['label'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap untuk lihat lapangan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow kanan
          const Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ],
      ),
    ),
  );
}
}