---
name: navicat-reset
description: Reset Navicat Premium trial period on macOS or Windows. Use when the user asks to reset Navicat trial, extend Navicat license, fix Navicat expired or evaluation period ended, or clean Navicat registration state.
---

# Navicat Reset

Reset Navicat Premium trial period by cleaning registration artifacts.

## Platform Scripts

| Platform | Script |
| --- | --- |
| macOS | `scripts/navicat-reset-macos.sh` |
| Windows | `scripts/navicat-reset-windows.bat` |

## macOS Workflow

1. Confirm the user wants to reset Navicat Premium trial.
2. Ask the user to quit Navicat if it is running; the script will also `pkill -9` as a safety net.
3. Run the macOS script:

```bash
bash ~/.codex/skills/navicat-reset/scripts/navicat-reset-macos.sh
```

4. The script performs these steps in order:
   - Terminates the running Navicat Premium process.
   - Deletes hex-hash files (`.[0-9A-F]{32}`) from `~/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium/`.
   - Removes 32-char hex keys from `~/Library/Preferences/com.navicat.NavicatPremium.plist`.
   - Deletes matching generic-password entries from the login Keychain (`com.navicat.NavicatPremium`).
5. After completion, advise the user to relaunch Navicat.

## Windows Workflow

1. Confirm the user wants to reset Navicat Premium trial.
2. Ask the user to close Navicat completely.
3. Run the Windows script as Administrator:

```cmd
navicat-reset-windows.bat
```

4. The script deletes registry entries under `HKEY_CURRENT_USER\Software\PremiumSoft\NavicatPremium` (Update, Registration) and cleans related CLSID entries.
5. After completion, advise the user to relaunch Navicat.

## Safety

- The scripts target Navicat Premium specifically; they do not affect other Navicat editions or unrelated software.
- macOS script uses `pkill -9` with the exact app name to avoid killing unrelated processes.
- Windows script operates only on the current user's registry hive.
- Both scripts are destructive to Navicat's local registration state; confirm with the user before running.
