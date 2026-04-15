import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/court_model.dart';
import '../models/time_slot_model.dart';
import '../models/venue_model.dart';

class CourtService {
  final _supabase = Supabase.instance.client;

  // Ambil semua venue
  Future<List<VenueModel>> getVenues() async {
    try {
      final response = await _supabase
          .from('venues')
          .select();

      return (response as List)
          .map((item) => VenueModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal ambil venue: $e');
    }
  }

  // Ambil semua lapangan (bisa filter by jenis olahraga)
  Future<List<CourtModel>> getCourts({String? sportType}) async {
    try {
      var query = _supabase
          .from('courts')
          .select()
          .eq('is_active', true);

      if (sportType != null) {
        query = query.eq('sport_type', sportType);
      }

      final response = await query;

      return (response as List)
          .map((item) => CourtModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal ambil lapangan: $e');
    }
  }

  // Ambil slot waktu untuk lapangan tertentu
    Future<List<TimeSlotModel>> getTimeSlots(String courtId, {String? dayType}) async {
    try {
      var query = _supabase
          .from('time_slots')
          .select()
          .eq('court_id', courtId)
          .eq('is_available', true);

      if (dayType != null) {
        query = query.eq('day_type', dayType);
      }

      final response = await query.order('start_time', ascending: true);

      return (response as List)
          .map((item) => TimeSlotModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal ambil slot waktu: $e');
    }
  }
}