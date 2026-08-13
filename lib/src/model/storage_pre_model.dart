class View360ChatPrefsModel {
  final String chatId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final bool isInQueue;

  View360ChatPrefsModel({
    required this.isInQueue,
    required this.chatId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });
}
