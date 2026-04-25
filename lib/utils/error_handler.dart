class ErrorHandler {
  static String getMessage(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('host')) {
      return 'Tidak ada koneksi internet. Periksa jaringan kamu.';
    }

    if (message.contains('invalid login') ||
        message.contains('invalid email') ||
        message.contains('wrong password')) {
      return 'Email atau password salah.';
    }

    if (message.contains('email already') ||
        message.contains('already registered')) {
      return 'Email sudah terdaftar. Gunakan email lain.';
    }

    if (message.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa menit.';
    }

    if (message.contains('jwt expired') ||
        message.contains('session expired')) {
      return 'Sesi kamu sudah habis. Silakan login ulang.';
    }

    return 'Terjadi kesalahan. Coba lagi.';
  }
}