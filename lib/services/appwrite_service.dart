import 'package:appwrite/appwrite.dart';
import '../config/appwrite_constants.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();

  factory AppwriteService() => _instance;

  AppwriteService._internal();

  Client get client => _client;
  late Client _client;
  late Account account;
  late Databases databases;
  late Storage storage;
  late Realtime realtime;

  void initialize() {
    _client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(status: true); // Atur ke false di produksi

    account = Account(_client);
    databases = Databases(_client);
    storage = Storage(_client);
    realtime = Realtime(_client);
  }
}
