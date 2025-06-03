import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/subscription.dart';
import '../config/appwrite_constants.dart';
import 'appwrite_service.dart';

class SubscriptionService {
  final AppwriteService _appwriteService;
  late Databases _databases;

  SubscriptionService(this._appwriteService) {
    _databases = _appwriteService.databases;
  }

  // Mendapatkan langganan aktif pengguna
  Future<Subscription?> getActiveSubscription(String userId) async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.subscriptionsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('is_active', true),
          Query.greaterThan('end_date', DateTime.now().toIso8601String()),
        ],
      );

      if (documentList.documents.isEmpty) {
        return null;
      }

      return Subscription.fromDocument(documentList.documents.first);
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan semua langganan pengguna
  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    try {
      final documentList = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.subscriptionsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('start_date'),
        ],
      );

      return documentList.documents
          .map((doc) => Subscription.fromDocument(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Membuat langganan baru
  Future<Subscription> createSubscription({
    required String userId,
    required String planType,
    required DateTime startDate,
    required DateTime endDate,
    String? paymentMethod,
  }) async {
    try {
      final subscription = Subscription(
        id: ID.unique(),
        userId: userId,
        planType: planType,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.subscriptionsCollection,
        documentId: subscription.id,
        data: subscription.toMap(),
      );

      return Subscription.fromDocument(document);
    } catch (e) {
      rethrow;
    }
  }

  // Membatalkan langganan
  Future<Subscription> cancelSubscription(String subscriptionId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.subscriptionsCollection,
        documentId: subscriptionId,
      );

      final subscription = Subscription.fromDocument(document);
      final updatedSubscription = subscription.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      final updatedDocument = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.subscriptionsCollection,
        documentId: subscriptionId,
        data: updatedSubscription.toMap(),
      );

      return Subscription.fromDocument(updatedDocument);
    } catch (e) {
      rethrow;
    }
  }

  // Memperpanjang langganan
  Future<Subscription> extendSubscription(
      String subscriptionId, DateTime newEndDate) async {
    try {
      final document = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.subscriptionsCollection,
        documentId: subscriptionId,
      );

      final subscription = Subscription.fromDocument(document);
      final updatedSubscription = subscription.copyWith(
        endDate: newEndDate,
        isActive: true,
        updatedAt: DateTime.now(),
      );

      final updatedDocument = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.subscriptionsCollection,
        documentId: subscriptionId,
        data: updatedSubscription.toMap(),
      );

      return Subscription.fromDocument(updatedDocument);
    } catch (e) {
      rethrow;
    }
  }

  // Memeriksa apakah pengguna memiliki langganan premium aktif
  Future<bool> hasPremiumSubscription(String userId) async {
    try {
      final subscription = await getActiveSubscription(userId);
      return subscription != null;
    } catch (e) {
      rethrow;
    }
  }
}
