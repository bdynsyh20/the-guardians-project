import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingService {
  final _supabase = Supabase.instance.client;

  // Buat booking baru
  Future<BookingModel> createBooking({
    required String userId,
    required String courtId,
    required String slotId,
    required DateTime bookingDate,
    required double totalPrice,
  }) async {
    try {
      // 1. Simpan booking
      final bookingResponse = await _supabase
          .from('bookings')
          .insert({
            'user_id': userId,
            'court_id': courtId,
            'slot_id': slotId,
            'booking_date': bookingDate.toIso8601String(),
            'status': 'pending',
            'total_price': totalPrice,
          })
          .select()
          .single();

      // 2. Buat payment
      await _supabase.from('payments').insert({
        'booking_id': bookingResponse['id'],
        'method': 'manual',
        'status': 'pending',
        'amount': totalPrice,
      });

      // 3. Ambil ulang booking dengan join courts dan time_slots
      final fullBooking = await _supabase
          .from('bookings')
          .select('''
            *,
            courts(name, sport_type),
            time_slots(start_time, end_time)
          ''')
          .eq('id', bookingResponse['id'])
          .single();

      return BookingModel.fromJson(fullBooking);
    } catch (e) {
      throw Exception('Gagal buat booking: $e');
    }
  }

  // Ambil riwayat booking milik customer
  Future<List<BookingModel>> getMyBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            courts(name, sport_type),
            time_slots(start_time, end_time)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => BookingModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal ambil riwayat: $e');
    }
  }

  // Ambil semua booking (untuk admin)
  Future<List<BookingModel>> getAllBookings() async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => BookingModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal ambil semua booking: $e');
    }
  }

  // Admin konfirmasi booking
  Future<void> confirmBooking(String bookingId) async {
    try {
      // Update status booking
      await _supabase
          .from('bookings')
          .update({'status': 'confirmed'})
          .eq('id', bookingId);

      // Update status payment
      await _supabase
          .from('payments')
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('booking_id', bookingId);
    } catch (e) {
      throw Exception('Gagal konfirmasi booking: $e');
    }
  }

  // Batalkan booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Gagal batalkan booking: $e');
    }
  }
}