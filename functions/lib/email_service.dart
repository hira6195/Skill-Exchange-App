import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> sendTestEmail({
    required String recipientEmail,
  }) async {
    final smtpServer = gmail(
      'hira61956@gmail.com',
      '',
    );

    final message = Message()
      ..from = Address(
        'YOUR_GMAIL@gmail.com',
        'Skill Exchange',
      )
      ..recipients.add(recipientEmail)
      ..subject = 'Skill Exchange Email Verification'
      ..text = 'Your Skill Exchange email verification email is working!';

    try {
      await send(message, smtpServer);
      print('Email sent successfully');
    } on MailerException catch (e) {
      print('Email failed: $e');
    }
  }
}