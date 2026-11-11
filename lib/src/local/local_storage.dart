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

  /// Preference key for stored agent name.
  static String agentNameKey = 'AGENT_NAME_KEY';

  /// Saves session and customer details to local preferences.
  static Future<void> saveString({
    required String customerIdKeyValue,
    required String customerNameKeyValue,
    String? customerEmailKeyValue,
    String? customerPhoneKeyValue,
    required bool isInQueueValue,
    String? agentNameValue,
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
    if (agentNameValue != null) {
      await prefs.setString(agentNameKey, agentNameValue);
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
      agentName: prefs.getString(agentNameKey),
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
    await prefs.remove(agentNameKey);
  }

  /// Retrieves the saved customer ID, or `null` if none is saved.
  static Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(customerIdKey);
  }

  /// Retrieves the saved customer ID, or `null` if none is saved.
  static Future<String?> getChatId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(chatIdKey);
  }

  /// Checks whether the stored chat ID is null or empty.
  ///
  /// Returns `true` if [chatIdKey] is not set, `null`, or consists only of whitespace.
  static Future<bool> isChatIdNullOrEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    final String? chatId = prefs.getString(chatIdKey);
    return chatId == null || chatId.trim().isEmpty;
  }

  /// Checks whether the stored chat ID is empty or null.
  ///
  /// Alias for [isChatIdNullOrEmpty].
  static Future<bool> isChatIdEmpty() => isChatIdNullOrEmpty();

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

  /// Sets the active agent name in preferences.
  static Future<void> setAgentName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(agentNameKey, value);
  }

  /// Retrieves the saved agent name, or `null` if none is saved.
  static Future<String?> getAgentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(agentNameKey);
  }

  /// Removes only the agent name key from preferences.
  static Future<bool> removeAgentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(agentNameKey);
  }

  /// Clears all preferences completely.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
