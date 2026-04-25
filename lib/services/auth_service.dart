import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Daftar akun baru
  Future<ProfileModel?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // 1. Daftarkan ke Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return null;

      // 2. Simpan data tambahan ke tabel profiles
      await _supabase.from('profiles').insert({
        'id': user.id,
        'name': name,
        'phone': phone,
        'role': 'customer',
      });

      // 3. Ambil data profile yang baru dibuat
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return ProfileModel.fromJson(profile);
    } catch (e) {
      throw Exception('Gagal daftar: $e');
    }
  }

  // Login
  Future<ProfileModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return null;

      // Ambil data profile setelah login
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return ProfileModel.fromJson(profile);
    } catch (e) {
      throw Exception('Gagal login: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Kirim email reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.sport_center_projects://login-callback',
      );
    } catch (e) {
      throw Exception('Gagal kirim email reset: $e');
    }
  }

  // Cek apakah user sedang login
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Ambil data user yang sedang login
  Future<ProfileModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return ProfileModel.fromJson(profile);
  }
}