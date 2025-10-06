#!/bin/bash

# Ensure Bitwarden CLI is unlocked
# You may need to run: export BW_SESSION=$(bw unlock --raw)

# Check if session is active
if [ -z "$BW_SESSION" ]; then
    echo "Warning: BW_SESSION is not set. You may need to unlock first."
    echo "Run: export BW_SESSION=\$(bw unlock --raw)"
    exit 1
fi

# File containing the items to update
JSON_FILE="notes_folder.json"

# Check if file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: $JSON_FILE not found!"
    exit 1
fi

# Get the total number of items
TOTAL_ITEMS=$(jq 'length' "$JSON_FILE")
echo "Found $TOTAL_ITEMS items to update"

# Loop through each item in the JSON array
jq -c '.[]' "$JSON_FILE" | while read -r item; do
    # Extract the item ID
    ITEM_ID=$(echo "$item" | jq -r '.id')
    ITEM_NAME=$(echo "$item" | jq -r '.name')
    
    echo "Updating item: $ITEM_NAME (ID: $ITEM_ID)"
    
    # Encode the item and update it in the vault
    echo "$item" | bw encode | bw edit item "$ITEM_ID"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully updated: $ITEM_NAME"
    else
        echo "✗ Failed to update: $ITEM_NAME"
    fi
    echo "---"
done

echo "Update complete!"

# Optionally sync
echo "Syncing with server..."
sleep 5
bw sync