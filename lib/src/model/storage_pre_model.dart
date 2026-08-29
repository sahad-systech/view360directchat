/// Model representing cached chat session state and customer details in local preferences.
class View360ChatPrefsModel {
  /// The active chat session ID.
  final String? chatId;

  /// The customer ID assigned by the server.
  final String customerId;

  /// The customer's registered name.
  final String customerName;

  /// The customer's registered email address.
  final String? customerEmail;

  /// The customer's registered phone number.
  final String? customerPhone;

  /// Whether the customer is currently in a waiting queue.
  final bool isInQueue;

  /// Creates a [View360ChatPrefsModel] instance.
  View360ChatPrefsModel({
    required this.isInQueue,
    this.chatId,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
  });
}
