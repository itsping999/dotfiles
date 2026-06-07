#!/bin/bash
set -uo pipefail

APP_NAME="Navicat Premium"
APP_SUPPORT_DIR="$HOME/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium"
PLIST_FILE="$HOME/Library/Preferences/com.navicat.NavicatPremium.plist"
KEYCHAIN_SERVICE="com.navicat.NavicatPremium"

echo "Terminating $APP_NAME process..."
if pkill -9 "$APP_NAME" 2>/dev/null; then
  echo "Successfully terminated running $APP_NAME process."
else
  echo "$APP_NAME process not running, skipping termination."
fi

echo "Cleaning hash files in app support directory..."
find "$APP_SUPPORT_DIR" -maxdepth 1 -type f -name '.[0-9A-F][0-9A-F]*' 2>/dev/null | \
while IFS= read -r file; do
  filename=$(basename "$file")
  if echo "$filename" | grep -Eq '^\.([0-9A-F]{32})$'; then
    echo "Deleting hash file: $filename"
    rm -f "$file"
  fi
done

echo "Processing preferences plist file..."
if [[ -f "$PLIST_FILE" ]]; then
  keys_to_delete=$(/usr/libexec/PlistBuddy -c "Print" "$PLIST_FILE" | grep -Eoa "^\s{4}[0-9A-F]{32}" | tr -d ' ')
  if [[ -n "$keys_to_delete" ]]; then
    while IFS= read -r key; do
      echo "Deleting key: $key"
      /usr/libexec/PlistBuddy -c "Delete :$key" "$PLIST_FILE" 2>/dev/null || true
    done <<< "$keys_to_delete"
  else
    echo "No 32-character hash keys found to delete."
  fi
else
  echo "Preferences plist file not found: $PLIST_FILE"
fi

echo "Cleaning trial tracking entries in Keychain..."
keychain_accounts=$(security dump-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null | \
  awk '/0x00000007.*'"$KEYCHAIN_SERVICE"'/{found=1} found && /"acct"/{print; found=0}' | \
  sed 's/.*<blob>="\([^"]*\)".*/\1/')

deleted_count=0
if [[ -n "$keychain_accounts" ]]; then
  while IFS= read -r account; do
    if echo "$account" | grep -Eq '^[0-9A-F]{32}$'; then
      echo "Deleting keychain entry: $account"
      security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$account" >/dev/null 2>&1 || true
      ((deleted_count++))
    fi
  done <<< "$keychain_accounts"
fi

if [[ $deleted_count -eq 0 ]]; then
  echo "No keychain entries found to delete."
else
  echo "Deleted $deleted_count keychain entries."
fi