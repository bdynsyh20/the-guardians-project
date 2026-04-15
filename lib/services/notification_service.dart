import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  // Ambil semua notifikasi milik user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal ambil notifikasi: $e');
    }
  }

  // Kirim notifikasi ke user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'is_read': false,
      });
    } catch (e) {
      throw Exception('Gagal kirim notifikasi: $e');
    }
  }

  // Tandai notifikasi sudah dibaca
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Gagal update notifikasi: $e');
    }
  }

  // Hitung notifikasi yang belum dibaca
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}