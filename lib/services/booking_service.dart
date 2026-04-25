import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class BookingService {
  final _supabase = Supabase.instance.client;

  // Cek apakah slot sudah dipesan di tanggal tertentu
  Future<bool> isSlotAvailable({
    required String courtId,
    required String slotId,
    required DateTime bookingDate,
  }) async {
    try {
      final response = await _supabase
          .from('booking_slots')
          .select()
          .eq('court_id', courtId)
          .eq('slot_id', slotId)
          .eq('booking_date', bookingDate.toIso8601String().split('T')[0]);

      return (response as List).isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Ambil semua slot yang sudah dipesan untuk lapangan & tanggal tertentu
  Future<List<String>> getBookedSlots({
    required String courtId,
    required DateTime bookingDate,
  }) async {
    try {
      final response = await _supabase
          .from('booking_slots')
          .select('slot_id')
          .eq('court_id', courtId)
          .eq('booking_date', bookingDate.toIso8601String().split('T')[0]);

      return (response as List)
          .map((item) => item['slot_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Buat booking baru
  Future<BookingModel> createBooking({
    required String userId,
    required String courtId,
    required String slotId,
    required DateTime bookingDate,
    required double totalPrice,
  }) async {
    try {
      // 1. Cek dulu apakah slot masih tersedia
      final available = await isSlotAvailable(
        courtId: courtId,
        slotId: slotId,
        bookingDate: bookingDate,
      );

      if (!available) {
        throw Exception('Slot ini sudah dipesan oleh orang lain!');
      }

      // 2. Simpan booking
      final bookingResponse = await _supabase
          .from('bookings')
          .insert({
            'user_id': userId,
            'court_id': courtId,
            'slot_id': slotId,
            'booking_date': bookingDate.toIso8601String().split('T')[0],
            'status': 'pending',
            'total_price': totalPrice,
          })
          .select()
          .single();

      // 3. Catat slot yang sudah dipesan
      await _supabase.from('booking_slots').insert({
        'court_id': courtId,
        'slot_id': slotId,
        'booking_date': bookingDate.toIso8601String().split('T')[0],
        'booking_id': bookingResponse['id'],
      });

      // 4. Buat payment
      await _supabase.from('payments').insert({
        'booking_id': bookingResponse['id'],
        'method': 'manual',
        'status': 'pending',
        'amount': totalPrice,
      });

      // 5. Ambil ulang dengan join
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
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<BookingModel>> getMyBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            courts(name, sport_type),
            time_slots(start_time, end_time),
            payments(status, method, payment_method_detail, payment_proof)
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
          .select('''
            *,
            courts(name, sport_type),
            time_slots(start_time, end_time)
          ''')
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
      await _supabase
          .from('bookings')
          .update({'status': 'confirmed'})
          .eq('id', bookingId);

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
      // Hapus dari booking_slots supaya slot bisa dipesan lagi
      await _supabase
          .from('booking_slots')
          .delete()
          .eq('booking_id', bookingId);

      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Gagal batalkan booking: $e');
    }
  }
}