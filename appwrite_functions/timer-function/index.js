const sdk = require('node-appwrite');

/**
 * Cloud Function: Auction Timer Countdown with Auto-Transitions
 * 
 * Server-side timer management for multi-device consistency.
 * Handles phase transitions: BIDDING → GOING_ONCE → GOING_TWICE → SOLD/UNSOLD
 * 
 * Expected Request Body:
 * {
 *   "roomId": "string"
 * }
 * 
 * Called every 1 second by host client (or could be scheduled via Appwrite Cron).
 */
module.exports = async ({ req, res, error, log }) => {
  try {
    const body = JSON.parse(req.body || '{}');
    const { roomId } = body;

    if (!roomId) {
      return res.json({ 
        success: false, 
        message: 'roomId is required' 
      }, 400);
    }

    const client = new sdk.Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
      .setKey(process.env.APPWRITE_API_KEY);

    const databases = new sdk.Databases(client);

    // Get current room state
    const room = await databases.getDocument(
      process.env.DATABASE_ID,
      process.env.ROOMS_COLLECTION_ID,
      roomId
    );

    let timer = Number(room.timer || 10);
    let auctionPhase = Number(room.auctionPhase || 0);  // 0=BIDDING, 1=GOING_ONCE, 2=GOING_TWICE, 3=SOLD/UNSOLD

    // Decrement timer
    if (timer > 0) {
      timer -= 1;
    }

    // Auto-transition phases when timer reaches 0
    if (timer === 0) {
      if (auctionPhase === 0) {
        // BIDDING → GOING_ONCE
        auctionPhase = 1;
        timer = 3;
        log(`Phase transition: BIDDING → GOING_ONCE for room ${roomId}`);
      } else if (auctionPhase === 1) {
        // GOING_ONCE → GOING_TWICE
        auctionPhase = 2;
        timer = 3;
        log(`Phase transition: GOING_ONCE → GOING_TWICE for room ${roomId}`);
      } else if (auctionPhase === 2) {
        // GOING_TWICE → SOLD (mark end of auction)
        auctionPhase = 3;
        timer = 0;
        log(`Phase transition: GOING_TWICE → SOLD for room ${roomId}`);
      }
    }

    // Update room with new timer and phase
    await databases.updateDocument(
      process.env.DATABASE_ID,
      process.env.ROOMS_COLLECTION_ID,
      roomId,
      {
        timer: timer,
        auctionPhase: auctionPhase
      }
    );

    return res.json({ 
      success: true, 
      timer: timer,
      auctionPhase: auctionPhase,
      message: `Timer synced: ${timer}s, Phase: ${auctionPhase}`
    });

  } catch (e) {
    error(`Timer function error: ${e.message}`);
    return res.json({ 
      success: false, 
      message: 'Server error updating timer',
      error: e.message 
    }, 500);
  }
};
