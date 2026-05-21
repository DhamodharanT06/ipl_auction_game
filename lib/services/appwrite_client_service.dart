import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:ipl_auction_game/core/config/appwrite_env.dart';

class AppwriteClientService {
  AppwriteClientService() {
    client
      ..setEndpoint(AppwriteEnv.endpoint)
      ..setProject(AppwriteEnv.projectId);

    // Self-signed certs are for local/self-hosted environments only.
    // Enabling it on web can cause browser-side issues.
    if (!kIsWeb) {
      client.setSelfSigned(status: true);
    }

    account = Account(client);
    databases = Databases(client);
    functions = Functions(client);
    realtime = Realtime(client);
  }

  final Client client = Client();
  late final Account account;
  late final Databases databases;
  late final Functions functions;
  late final Realtime realtime;
}
