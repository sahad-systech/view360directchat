import 'package:flutter/foundation.dart';
import 'call/config/call_config.dart';

/// Settings for View360 AI voice calls.
/// This is an alias for the existing [View360CallConfig] to maintain backward compatibility.
typedef View360CallSettings = View360CallConfig;

/// Represents the customer details for View360 chat and call sessions.
@immutable
class View360Customer {
  /// The customer's display name.
  final String? name;

  /// The customer's email address.
  final String? email;

  /// The customer's phone number.
  final String? phone;

  /// Creates a [View360Customer] instance.
  const View360Customer({
    this.name,
    this.email,
    this.phone,
  });

  /// Creates a copy of this customer with the given fields replaced with the new values.
  View360Customer copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return View360Customer(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

/// Global configuration for the View360 package.
@immutable
class View360Config {
  /// The base URL for the View360 API endpoints.
  final String baseUrl;

  /// The unique application identifier assigned by View360.
  final String appId;

  /// Customer details to use as default for chat and calls.
  final View360Customer? customer;

  /// Configuration for LiveKit voice calls.
  final View360CallSettings? call;

  /// Whether to enable logging for debugging. Defaults to false.
  final bool enableLogging;

  /// Creates a [View360Config] instance.
  /// 
  /// Throws an [ArgumentError] if [appId] is empty, or if [baseUrl] is invalid.
  View360Config({
    required String baseUrl,
    required this.appId,
    this.customer,
    this.call,
    this.enableLogging = false,
  }) : baseUrl = _normalizeBaseUrl(baseUrl) {
    if (appId.trim().isEmpty) {
      throw ArgumentError('appId cannot be empty.');
    }
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('baseUrl cannot be empty.');
    }
    final lower = trimmed.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      throw ArgumentError('baseUrl must start with http:// or https://');
    }
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
