import 'package:shared_preferences/shared_preferences.dart';

import '../model/storage_pre_model.dart';

/// Helper utility for persisting and reading View360 chat session data using [SharedPreferences].
class View360ChatPrefs {
  View360ChatPrefs._();

  /// Preference key for stored chat ID.
  static String chatIdKey = 'CHAT_ID_KEY';

  /// Preference key for stored customer ID.
  static String customerIdKey = 'CUSTOMER_ID_KEY';

  /// Preference key for stored customer name.
  static String customerNameKey = 'CUSTOMER_NAME_KEY';

  /// Preference key for stored customer email.
  static String customerEmailKey = 'CUSTOMER_EMAIL_KEY';

  /// Preference key for stored customer phone number.
  static String customerPhoneKey = 'CUSTOMER_PHONE_KEY';

  /// Preference key for queue status.
  static String isInQueue = 'IS_IN_QUEUE';

  /// Saves session and customer details to local preferences.
  static Future<void> saveString({
    required String customerIdKeyValue,
    required String customerNameKeyValue,
    String? customerEmailKeyValue,
    String? customerPhoneKeyValue,
    required bool isInQueueValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isInQueue, isInQueueValue);
    await prefs.setString(customerIdKey, customerIdKeyValue);
    await prefs.setString(customerNameKey, customerNameKeyValue);
    if (customerEmailKeyValue != null) {
      await prefs.setString(customerEmailKey, customerEmailKeyValue);
    }
    if (customerPhoneKeyValue != null) {
      await prefs.setString(customerPhoneKey, customerPhoneKeyValue);
    }
  }

  /// Retrieves the saved session and customer model from local preferences.
  static Future<View360ChatPrefsModel> getString() async {
    final prefs = await SharedPreferences.getInstance();
    return View360ChatPrefsModel(
      chatId: prefs.getString(chatIdKey),
      customerId: prefs.getString(customerIdKey) ?? '',
      customerName: prefs.getString(customerNameKey) ?? '',
      isInQueue: prefs.getBool(isInQueue) ?? false,
      customerEmail: prefs.getString(customerEmailKey) ?? '',
      customerPhone: prefs.getString(customerPhoneKey) ?? '',
    );
  }

  /// Removes all stored chat keys from local preferences.
  static Future<void> remove() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(chatIdKey);
    await prefs.remove(customerIdKey);
    await prefs.remove(customerNameKey);
    await prefs.remove(customerEmailKey);
    await prefs.remove(customerPhoneKey);
    await prefs.remove(isInQueue);
  }

  /// Retrieves the saved customer ID, or `null` if none is saved.
  static Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(customerIdKey);
  }

  /// Removes only the customer ID key from preferences.
  static Future<bool> removeCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(customerIdKey);
  }

  /// Updates the stored queue status flag.
  static Future<void> changeQueueStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isInQueue, value);
  }

  /// Sets the active chat ID in preferences.
  static Future<void> setChatId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chatIdKey, value);
  }

  /// Clears all preferences completely.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
