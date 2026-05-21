import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:ipl_auction_game/core/config/appwrite_env.dart';

class FunctionService {
  FunctionService(this._functions);

  final Functions _functions;

  /// Place a bid with server-side validation
  /// Returns the server response including bidId and highestBid
  Future<Map<String, dynamic>> placeBid({
    required String roomId,
    required int bidAmount,
    required String userId,
    required String username,
    required String playerName,
    required String auctionId,
  }) async {
    final response = await _functions.createExecution(
      functionId: AppwriteEnv.bidFunctionId,
      body: jsonEncode({
        'roomId': roomId,
        'bidAmount': bidAmount,
        'userId': userId,
        'username': username,
        'playerName': playerName,
        'auctionId': auctionId,
      }),
    );

    final decoded = _decodeResponse(response);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Bid failed');
    }
    return decoded;
  }

  /// Sync auction timer with server-side countdown
  /// Returns {timer: int, auctionPhase: int}
  Future<Map<String, dynamic>> tickAuctionTimer({required String roomId}) async {
    final response = await _functions.createExecution(
      functionId: AppwriteEnv.timerFunctionId,
      body: jsonEncode({'roomId': roomId}),
    );

    final decoded = _decodeResponse(response);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Timer sync failed');
    }
    return decoded;
  }

  /// Decode function response safely
  Map<String, dynamic> _decodeResponse(models.Execution execution) {
    if (execution.responseBody.isEmpty) {
      return {'success': execution.status == 'completed'};
    }
    try {
      return jsonDecode(execution.responseBody) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': 'Invalid response format'};
    }
  }
}

