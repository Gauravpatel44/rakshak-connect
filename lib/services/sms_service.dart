import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';

/// Handles SMS and WhatsApp messaging for emergency alerts
class SmsService {
  /// Send emergency SMS to a contact with location link
  Future<bool> sendEmergencySms({
    required ContactModel contact,
    required double latitude,
    required double longitude,
    required String userName,
  }) async {
    final locationLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final message =
        '🆘 EMERGENCY ALERT!\n\n'
        '$userName needs immediate help!\n\n'
        '📍 Location: $locationLink\n\n'
        'Please respond immediately!\n\n'
        '-- Rakshak Connect';

    final encodedMessage = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:${contact.phone}?body=$encodedMessage');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Send emergency WhatsApp message to a contact
  Future<bool> sendWhatsAppAlert({
    required ContactModel contact,
    required double latitude,
    required double longitude,
    required String userName,
  }) async {
    final locationLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final message =
        '🆘 *EMERGENCY ALERT!*\n\n'
        '*$userName* needs immediate help!\n\n'
        '📍 *Location:* $locationLink\n\n'
        'Please respond immediately!\n\n'
        '_Sent via Rakshak Connect_';

    final encodedMessage = Uri.encodeComponent(message);

    // Bug #6 fix: normalize the phone number before prepending country code.
    // Strip leading '+', spaces, '-', and any existing '91' prefix so we
    // never end up with '91919876543210'.
    final phone = _normalizeToE164India(contact.phone);

    final waUri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Normalizes an Indian phone number to E.164 format without '+'  .
  /// Examples:
  ///   '9876543210'    → '919876543210'
  ///   '+919876543210' → '919876543210'
  ///   '919876543210'  → '919876543210'
  ///   '09876543210'   → '919876543210'
  static String _normalizeToE164India(String raw) {
    // Remove all non-digit characters (spaces, dashes, parentheses, +)
    String digits = raw.replaceAll(RegExp(r'[^\d]'), '');

    // Strip leading 0
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Strip existing country code '91' if the number is already 12 digits
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }

    // BUG-03 fix: validate we have exactly 10 digits before prepending country code.
    // A non-10-digit number at this point is unrecognizable; return it as-is with
    // country code and let the platform handle it (better than silently wrong number).
    if (digits.length != 10) {
      debugPrint('⚠️ SmsService: unexpected digit count (${digits.length}) for "$raw"');
    }

    // Prepend India country code
    return '91$digits';
  }

  /// Share location via platform share sheet
  Future<bool> shareLocationLink(double latitude, double longitude) async {
    final locationLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final uri = Uri.parse(locationLink);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Send generic text message
  Future<bool> sendGenericSms(String message) async {
    final encoded = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:?body=$encoded');
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Make a phone call
  Future<bool> makeCall(String phoneNumber) async {
    final telUri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
