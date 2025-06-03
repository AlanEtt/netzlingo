import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import '../services/appwrite_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService =
      SubscriptionService(AppwriteService());
  final UserService _userService = UserService(AppwriteService());

  Subscription? _activeSubscription;
  List<Subscription> _subscriptionHistory = [];
  bool _isLoading = false;
  String? _error;

  Subscription? get activeSubscription => _activeSubscription;
  List<Subscription> get subscriptionHistory => _subscriptionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium =>
      _activeSubscription != null && _activeSubscription!.isValid;

  // Memuat langganan pengguna
  Future<void> loadSubscriptions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Dapatkan langganan aktif
      _activeSubscription =
          await _subscriptionService.getActiveSubscription(userId);

      // Dapatkan riwayat langganan
      _subscriptionHistory =
          await _subscriptionService.getUserSubscriptions(userId);

      // Update status premium di user
      if (_activeSubscription != null && _activeSubscription!.isValid) {
        await _userService.updateUserSettings(
          userId: userId,
          isPremium: true,
        );
      } else {
        await _userService.updateUserSettings(
          userId: userId,
          isPremium: false,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Membuat langganan baru
  Future<bool> createSubscription({
    required String userId,
    required String planType,
    required int durationMonths,
    String? paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: 30 * durationMonths));

      final newSubscription = await _subscriptionService.createSubscription(
        userId: userId,
        planType: planType,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
      );

      // Update active subscription
      _activeSubscription = newSubscription;

      // Add to history
      _subscriptionHistory.insert(0, newSubscription);

      // Update user premium status
      await _userService.updateUserSettings(
        userId: userId,
        isPremium: true,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Membatalkan langganan
  Future<bool> cancelSubscription(String userId) async {
    if (_activeSubscription == null) {
      _error = 'Tidak ada langganan aktif untuk dibatalkan';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedSubscription = await _subscriptionService
          .cancelSubscription(_activeSubscription!.id);

      // Update active subscription
      _activeSubscription = null;

      // Update in history
      final index = _subscriptionHistory
          .indexWhere((s) => s.id == updatedSubscription.id);
      if (index != -1) {
        _subscriptionHistory[index] = updatedSubscription;
      }

      // Update user premium status
      await _userService.updateUserSettings(
        userId: userId,
        isPremium: false,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Memperpanjang langganan
  Future<bool> extendSubscription(String userId, int additionalMonths) async {
    if (_activeSubscription == null) {
      _error = 'Tidak ada langganan aktif untuk diperpanjang';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Hitung tanggal akhir baru
      final currentEndDate = _activeSubscription!.endDate;
      final newEndDate =
          currentEndDate.add(Duration(days: 30 * additionalMonths));

      final updatedSubscription = await _subscriptionService.extendSubscription(
        _activeSubscription!.id,
        newEndDate,
      );

      // Update active subscription
      _activeSubscription = updatedSubscription;

      // Update in history
      final index = _subscriptionHistory
          .indexWhere((s) => s.id == updatedSubscription.id);
      if (index != -1) {
        _subscriptionHistory[index] = updatedSubscription;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset error
  void resetError() {
    _error = null;
    notifyListeners();
  }
}
