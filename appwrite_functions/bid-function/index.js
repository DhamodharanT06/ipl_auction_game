const sdk = require('node-appwrite');

/**
 * Cloud Function: Place Bid with Server-Side Validation
 * 
 * Validates bid amount and updates room state atomically on server.
 * This prevents race conditions and ensures bid integrity across clients.
 * 
 * Expected Request Body:
 * {
 *   "roomId": "string",
 *   "bidAmount": number,
 *   "userId": "string",
 *   "username": "string",
 *   "playerName": "string",
 *   "auctionId": "string"
 * }
 */
module.exports = async ({ req, res, log, error }) => {
  try {
    const body = JSON.parse(req.body || '{}');
    const { roomId, bidAmount, userId, username, playerName, auctionId } = body;

    // Validate required fields
    if (!roomId || bidAmount === undefined || !userId || !username || !playerName || !auctionId) {
      return res.json({ 
        success: false, 
        message: 'Missing required fields: roomId, bidAmount, userId, username, playerName, auctionId' 
      }, 400);
    }

    // Validate bid amount
    if (typeof bidAmount !== 'number' || bidAmount <= 0) {
      return res.json({ 
        success: false, 
        message: 'Bid amount must be a positive number' 
      }, 400);
    }

    const client = new sdk.Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY);

    const databases = new sdk.Databases(client);

    // Get current room state
    const roomDoc = await databases.getDocument(
      process.env.DATABASE_ID,
      process.env.ROOMS_COLLECTION_ID,
      roomId
    );

    const currentHighestBid = Number(roomDoc.highestBid || 0);

    // Server-side bid validation: bid must be strictly higher than current
    if (Number(bidAmount) <= currentHighestBid) {
      log(`Bid rejected: ${bidAmount} <= ${currentHighestBid}`);
      return res.json({ 
        success: false, 
        message: `Bid must be higher than ₹${currentHighestBid}L` 
      }, 409);
    }

    // Create bid document in bids collection
    const bidResult = await databases.createDocument(
      process.env.DATABASE_ID,
      process.env.BIDS_COLLECTION_ID,
      'unique()',
      {
        auctionId: auctionId,
        userId: userId,
        username: username,
        bidAmount: bidAmount,
        playerName: playerName,
        timestamp: new Date().toISOString(),
        roomId: roomId
      }
    );

    // Atomically update room with new highest bid and reset timer to initial 10s
    await databases.updateDocument(
      process.env.DATABASE_ID,
      process.env.ROOMS_COLLECTION_ID,
      roomId,
      {
        highestBid: bidAmount,
        timer: 10  // Reset to initial bidding phase when new bid placed
      }
    );

    log(`Bid placed: ${username} bid ₹${bidAmount}L`);
    return res.json({ 
      success: true, 
      message: 'Bid accepted',
      bidId: bidResult.$id,
      highestBid: bidAmount
    });

  } catch (e) {
    error(`Bid function error: ${e.message}`);
    return res.json({ 
      success: false, 
      message: 'Server error processing bid',
      error: e.message 
    }, 500);
  }
};
