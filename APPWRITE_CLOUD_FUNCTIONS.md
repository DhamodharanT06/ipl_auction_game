# Appwrite Cloud Functions - Deployment Guide

## Overview

This project uses **two Appwrite Cloud Functions** for server-side auction management:

1. **place_bid** - Server-side bid validation (prevents race conditions)
2. **auction_timer** - Server-side timer countdown with auto-transitions

These functions ensure **data consistency across all connected devices** by validating bids and managing phase transitions on the server instead of relying on client-side logic alone.

---

## ✅ Step 1: Create Functions in Appwrite Console

### 1.1 Create `place_bid` Function

1. Go to **Appwrite Console** → Your Project
2. Navigate to **Functions** (sidebar)
3. Click **Create Function**
4. **Configure:**
   - Name: `place_bid`
   - Runtime: **Node.js (18.0+)**
   - GitHub/Git: No
5. Click **Create**
6. Copy code from: `appwrite_functions/bid-function/index.js`
7. Paste into the Appwrite editor
8. **Deploy** by clicking the checkmark button

### 1.2 Create `auction_timer` Function

1. Click **Create Function** again
2. **Configure:**
   - Name: `auction_timer`
   - Runtime: **Node.js (18.0+)**
3. Copy code from: `appwrite_functions/timer-function/index.js`
4. Paste into the Appwrite editor
5. **Deploy**

---

## ✅ Step 2: Configure Environment Variables

Both functions need these environment variables. Set them in Appwrite Console:

### For both functions, add these variables:

| Variable | Value | Example |
|----------|-------|---------|
| `APPWRITE_ENDPOINT` | Your Appwrite endpoint | `https://nyc.cloud.appwrite.io/v1` |
| `APPWRITE_FUNCTION_PROJECT_ID` | Your Appwrite project ID | `69e70398003c632edda2` |
| `APPWRITE_API_KEY` | Appwrite API Key (with Admin scope) | Generate in Appwrite Settings |
| `DATABASE_ID` | Database ID | `ipl_auction_users` |
| `ROOMS_COLLECTION_ID` | Rooms collection ID | `rooms` |
| `BIDS_COLLECTION_ID` | Bids collection ID | `bids` |

### How to set environment variables:

1. In Appwrite Console → Functions → Select function → **Settings** tab
2. Scroll to **Environment Variables**
3. Click **Add Variable** for each variable above
4. **Save**
5. **Redeploy** the function

### How to get APPWRITE_API_KEY:

1. Go to **Settings** → **API Keys** (or **Server API Keys** in older versions)
2. Click **Create API Key**
3. Give it a name: `Cloud Functions`
4. Scopes needed:
   - ✅ `databases.read`
   - ✅ `databases.write`
5. Copy and save securely

---

## ✅ Step 3: Verify Function IDs Match

Make sure the function IDs in your code match what you created:

**File:** `lib/core/config/appwrite_env.dart`

```dart
static const bidFunctionId = 'place_bid';        // ✓ Verify this matches
static const timerFunctionId = 'auction_timer';  // ✓ Verify this matches
```

If you named your functions differently, update these constants.

---

## ✅ Step 4: Test Functions (Optional)

### Test via Appwrite Console

1. Navigate to **Functions** → **place_bid**
2. Click **Execute** tab
3. Enter test payload:
```json
{
  "roomId": "test_room_123",
  "bidAmount": 100,
  "userId": "user1",
  "username": "john_doe",
  "playerName": "Virat Kohli",
  "auctionId": "auction1"
}
```
4. Click **Execute** → Should see `{"success": true, ...}`

---

## ✅ Step 5: Verify in Flutter App

The Flutter app is already integrated. When you place a bid:

1. **Without cloud functions:** Bid written directly to database
2. **With cloud functions:** Bid validated on server first, then written

**To enable cloud functions:**
- The `room_controller.dart` now calls `functionServiceProvider.placeBid()`
- This automatically uses your deployed `place_bid` function

---

## 🔍 Function Details

### `place_bid` Function

**What it does:**
- Validates bid amount is strictly greater than current highest bid
- Prevents duplicate bids or lower bids from being placed
- Creates bid document in database
- Updates room with new highest bid and resets timer to 10s
- Returns error with HTTP 409 if bid validation fails

**Payload:**
```json
{
  "roomId": "room_abc123",
  "bidAmount": 500,
  "userId": "user_xyz789",
  "username": "player_name",
  "playerName": "Virat Kohli",
  "auctionId": "auction_001"
}
```

**Response:**
```json
{
  "success": true,
  "bidId": "bid_doc_id",
  "highestBid": 500,
  "message": "Bid accepted"
}
```

---

### `auction_timer` Function

**What it does:**
- Decrements timer by 1 second every call
- Auto-transitions phases when timer hits 0
  - BIDDING (0) → GOING_ONCE (1) [3s timer]
  - GOING_ONCE (1) → GOING_TWICE (2) [3s timer]
  - GOING_TWICE (2) → SOLD (3) [0s timer]
- Updates room with new timer and phase

**Payload:**
```json
{
  "roomId": "room_abc123"
}
```

**Response:**
```json
{
  "success": true,
  "timer": 9,
  "auctionPhase": 0,
  "message": "Timer synced: 9s, Phase: 0"
}
```

---

## 🚀 How Functions Are Called

### From Flutter App:

**1. Placing a bid:**
```dart
// In room_controller.dart
final result = await functions.placeBid(
  roomId: room.roomId,
  bidAmount: 500,
  userId: uid,
  username: 'john_doe',
  playerName: 'Virat Kohli',
  auctionId: auction.id,
);
```

**2. Syncing timer (Optional - currently client manages):**
```dart
// Could be called every second
final result = await functions.tickAuctionTimer(roomId: roomId);
```

---

## 🐛 Troubleshooting

### "Function not found" Error
- ✓ Verify function ID in `appwrite_env.dart` matches console
- ✓ Function must be **deployed** (not just saved)
- ✓ Check function status shows "Active"

### "Missing environment variables" Error
- ✓ Add all 6 environment variables listed in Step 2
- ✓ Redeploy function after adding variables
- ✓ Verify `APPWRITE_API_KEY` has read/write scopes

### "Bid rejected" Error (HTTP 409)
- ✓ This is expected if bid ≤ current highest bid
- ✓ Client should show error: "Bid must be higher than current"

### Timer not updating
- ✓ Currently managed client-side in `auction_screen.dart`
- ✓ To enable server-side timer, call `tickAuctionTimer()` every second
- ✓ Keep client-side timer as fallback

---

## 📊 Database Schema Requirements

Functions expect these collection structures:

### `rooms` Collection
```dart
{
  "id": "string",
  "roomId": "string",
  "timer": "number",
  "auctionPhase": "number",  // 0=BIDDING, 1=ONCE, 2=TWICE, 3=SOLD
  "highestBid": "number",
  "currentPlayer": "string"
}
```

### `bids` Collection
```dart
{
  "id": "string",
  "auctionId": "string",
  "userId": "string",
  "username": "string",
  "bidAmount": "number",
  "playerName": "string",
  "timestamp": "string",
  "roomId": "string"
}
```

---

## ✅ Deployment Checklist

- [ ] Created `place_bid` function in Appwrite
- [ ] Created `auction_timer` function in Appwrite
- [ ] Set all 6 environment variables for `place_bid`
- [ ] Set all 6 environment variables for `auction_timer`
- [ ] Generated and secured `APPWRITE_API_KEY`
- [ ] Verified function IDs match `appwrite_env.dart`
- [ ] Tested functions via Appwrite console
- [ ] Run Flutter app and test placing a bid
- [ ] Verified bid goes through `place_bid` function

---

## 📚 Next Steps

1. **Deploy functions** following steps 1-4 above
2. **Test in Flutter** - Place a bid and verify it goes through
3. **Monitor** - Check Appwrite Logs → Functions for execution details
4. **Optional** - Enable server-side timer by uncommenting timer sync in auction screen

---

## 🔒 Security Notes

- ✓ API Key should never be committed to version control
- ✓ Regenerate API Key if it's ever exposed
- ✓ Functions run with Admin privileges - be careful with permissions
- ✓ Consider adding rate limiting if functions are hammered with requests
- ✓ Use Appwrite's built-in audit logs to monitor function execution

---

**Questions?** Check Appwrite documentation: https://appwrite.io/docs/products/functions
