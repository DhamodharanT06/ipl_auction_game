# IPL Auction MVP (Flutter + Appwrite)

Production-ready MVP mobile app for IPL-style real-time auction gameplay.

## Stack

- Flutter (null safety)
- Appwrite: Auth, Database, Realtime, Functions
- Hive: local cache (players + last room)
- HTTP: Google Sheets Apps Script API (read-only)
- Riverpod: app state
- Material 3 dark-only premium UI

## Folder Architecture

```text
lib/
	core/
		config/
		constants/
		theme/
	models/
	services/
	providers/
	screens/
	widgets/
```

## Run

1. Update values in `lib/core/config/appwrite_env.dart`.
2. Update `lib/core/config/sheets_env.dart` with your Apps Script endpoint.
3. Install dependencies:

```bash
flutter pub get
```

4. Run:

```bash
flutter run
```

## Appwrite Setup

### 1) Authentication

- Enable Google OAuth provider in Appwrite Authentication.
- Add your app callback/redirect URLs for Android/iOS in the provider settings.
- App users must sign in with Google before lobby actions.

### 2) Database

- Create database: `ipl_auction_db`
- Create collections:
	- `users`
	- `rooms`

### 3) Collection Schemas

#### users

```json
{
	"user_id": "string (required)",
	"username": "string (required)",
	"email": "string (required)",
	"mobile": "string (required)",
	"fav_team": "string (optional)",
	"fav_player": "string (optional)",
	"games_played": "integer (default 0)",
	"first_place": "integer (default 0)",
	"second_place": "integer (default 0)",
	"third_place": "integer (default 0)"
}
```

#### rooms

```json
{
	"room_id": "string (required)",
	"host_id": "string (required)",
	"host_mode": "string enum: player|dedicated",
	"status": "string enum: waiting|active|selection|ended",
	"participants": "array of objects",
	"current_player": "string (nullable)",
	"highest_bid": "integer",
	"highest_bidder": "string (nullable)",
	"timer": "integer",
	"auction_state": "string enum: idle|goingOnce|goingTwice|sold|unsold",
	"sold_player_ids": "string[]",
	"unsold_player_ids": "string[]",
	"current_order": "string[]"
}
```

`participants` object shape:

```json
{
	"uid": "string",
	"name": "string",
	"approved": "bool",
	"team": "string|null",
	"ready_for_result": "bool",
	"squad": "string[]",
	"selected_xi": "string[]",
	"captain_id": "string|null",
	"vice_captain_id": "string|null",
	"points": "double"
}
```

### 4) Permissions

- Room document create:
	- read: `Role.any()`
	- update/delete: host user only
- Function API key should have `databases.read` + `databases.write` for room updates.

## Realtime and Cost Controls

- Exactly one subscription per room document in `RealtimeService`.
- No full collection scans for room updates.
- No bid history storage.
- Batched state in single room document.
- Hive first-load for players to reduce network calls.

## Appwrite Functions

Function examples are included:

- `appwrite_functions/bid-function/index.js`
- `appwrite_functions/timer-function/index.js`

Create two functions in Appwrite and set IDs matching `appwrite_env.dart`:

- `place_bid`
- `auction_timer`

Required env vars for both functions:

- `APPWRITE_ENDPOINT`
- `APPWRITE_FUNCTION_PROJECT_ID`
- `APPWRITE_API_KEY`
- `DATABASE_ID=ipl_auction_db`
- `ROOMS_COLLECTION_ID=rooms`

## Google Sheets API (Apps Script)

Deploy an Apps Script Web App that returns JSON:

```javascript
function doGet() {
	const sheet = SpreadsheetApp.getActive().getSheetByName('players');
	const rows = sheet.getDataRange().getValues();
	const headers = rows.shift();

	const players = rows.map((row) => {
		const obj = {};
		headers.forEach((h, i) => (obj[h] = row[i]));
		return obj;
	});

	return ContentService
		.createTextOutput(JSON.stringify({ players }))
		.setMimeType(ContentService.MimeType.JSON);
}
```

Expected fields per row:

- `player_id`
- `name`
- `role`
- `country`
- `base_price`
- `image_url`
- `category`
- `rating` (hidden in UI)

## Hive Setup

- `CacheService.init()` is called at splash startup.
- Boxes:
	- `players_cache`
	- `app_cache`
- Cache strategy:
	- load from Hive instantly
	- refresh from Sheets in background

## Key Gameplay Rules Implemented

- Host approval flow with max 10 players
- Random IPL team assignment after approval
- Atomic bidding via function (`new_bid > highest_bid`)
- 8-second timer reset on successful bid
- Auction state transitions (idle -> goingOnce -> goingTwice -> sold/unsold)
- Team selection validation:
	- exactly 11 players
	- max 4 foreign
	- min 1 wicketkeeper
	- captain/vice-captain multipliers
- Leaderboard with tie-aware ranking

## Notes

- Existing legacy screens in the repository are left untouched.
- New MVP flow uses `main.dart` -> `screens/splash_screen.dart` and Riverpod-first architecture.
"# ipl_auction_game" 
