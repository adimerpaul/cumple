import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiUrl =>
      dotenv.env['API_URL'] ?? 'http://192.168.1.51:8000';
}
