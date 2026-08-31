import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class SessionManager {
  static Timer? _timer;
  // Development Phase: 5 Minutes (5 * 60 seconds)
  static const int sessionDurationInMinutes = 5;

  static void startSessionTimer(Function onTimeout) {
    _timer?.cancel();
    _timer = Timer(const Duration(minutes: sessionDurationInMinutes), () async {
      await FirebaseAuth.instance.signOut();
      onTimeout();
    });
  }

  static void resetTimer(Function onTimeout) {
    startSessionTimer(onTimeout);
  }

  static void stopTimer() {
    _timer?.cancel();
  }
}