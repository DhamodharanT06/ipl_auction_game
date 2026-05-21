# Appwrite Schema Update: Adding hostMode Field

## Problem
The `rooms` collection in Appwrite is missing the `hostMode` attribute, which causes this error:
```
AppwriteException: document_invalid_structure, Invalid document structure: Unknown attribute: "hostMode" (400)
```

## Solution: Add hostMode Attribute to rooms Collection

### Via Appwrite Console (Recommended)

1. **Go to Appwrite Console** → https://your-appwrite-domain/console
2. **Select Your Project** → `ipl_auction_game`
3. **Navigate to Database** → `ipl_auction_db`
4. **Open the `rooms` Collection**
5. **Click "Attributes" Tab**
6. **Click "Create Attribute"** button
7. **Fill in the following:**
   - **Attribute ID:** `hostMode`
   - **Attribute Type:** String
   - **Size:** 50 (default)
   - **Is Required:** ❌ No (leave unchecked)
   - **Default Value:** *(leave blank)*
8. **Click "Create"**

### Verification
After adding the attribute:
- Run the app again
- Create a new room
- Select "Play & Bid" or "Just Conduct" in the dialog
- The `hostMode` field should now save successfully without errors

## Alternative: Update Existing Rooms (Optional)

If you have existing rooms without the `hostMode` field and want to backfill them:

1. Go to the `rooms` collection
2. Manually edit any existing documents
3. Add `hostMode: "play"` or `hostMode: "conduct"` as needed

## Using curl/API (Advanced)

If you prefer command line:

```bash
curl -X POST \
  https://your-appwrite-domain/v1/databases/{DATABASE_ID}/collections/{COLLECTION_ID}/attributes/string \
  -H "X-Appwrite-Project: {PROJECT_ID}" \
  -H "X-Appwrite-Key: {API_KEY}" \
  -d "attributeId=hostMode" \
  -d "size=50" \
  -d "required=false"
```

Replace:
- `{YOUR_APPWRITE_DOMAIN}`
- `{DATABASE_ID}` - Use: `ipl_auction_db` ID
- `{COLLECTION_ID}` - Use: `rooms` collection ID
- `{PROJECT_ID}` - Your Appwrite project ID
- `{API_KEY}` - Your Appwrite API key

## Field Details

- **ID:** `hostMode`
- **Type:** String
- **Length:** 50
- **Required:** No
- **Allowed Values:** `"play"` or `"conduct"`
  - `"play"` = Host wants to participate in bidding
  - `"conduct"` = Host only conducts, cannot bid
