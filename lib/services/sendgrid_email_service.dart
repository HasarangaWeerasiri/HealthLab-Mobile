import 'dart:convert';
import 'package:http/http.dart' as http;

class SendGridEmailService {
  final String apiKey;
  final String fromEmail;
  final String fromName;

  SendGridEmailService({required this.apiKey, required this.fromEmail, this.fromName = 'HealthLab'})
      : assert(apiKey.isNotEmpty),
        assert(fromEmail.isNotEmpty);

  Future<void> sendOtpEmail({required String toEmail, required String otpCode}) async {
    final uri = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final html = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Verify your email</title>
    <style>
      body { background: #0F0E0C; color: #E6FDD8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
      .container { max-width: 520px; margin: 0 auto; padding: 24px; }
      .card { background: #151410; border-radius: 16px; padding: 24px; border: 1px solid rgba(255,255,255,0.1); }
      .title { font-size: 22px; font-weight: 800; margin: 0 0 8px; }
      .subtitle { opacity: 0.8; margin: 0 0 16px; }
      .otp { font-size: 36px; font-weight: 800; letter-spacing: 10px; text-align: center; background: #0F0E0C; border: 1px dashed rgba(230,253,216,0.3); border-radius: 12px; padding: 16px; margin: 16px 0; }
      .footer { font-size: 12px; opacity: 0.6; margin-top: 16px; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="card">
        <div class="title">Verify your email</div>
        <div class="subtitle">Use the code below to verify your email address. This code expires in 10 minutes.</div>
        <div class="otp">$otpCode</div>
        <div class="subtitle">If you didn't request this, you can ignore this email.</div>
        <div class="footer">Sent by $fromName</div>
      </div>
    </div>
  </body>
</html>
''';

    final payload = {
      'personalizations': [
        {
          'to': [
            {'email': toEmail}
          ],
          'subject': 'Your HealthLab verification code'
        }
      ],
      'from': {
        'email': fromEmail,
        if (fromName.isNotEmpty) 'name': fromName,
      },
      'content': [
        {
          'type': 'text/plain',
          'value': 'Your verification code is: $otpCode\nThis code will expire in 10 minutes.'
        },
        {
          'type': 'text/html',
          'value': html
        }
      ]
    };

    final response = await http.post(uri, headers: headers, body: jsonEncode(payload));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to send email via SendGrid: ${response.statusCode} ${response.body}');
    }
  }
}


