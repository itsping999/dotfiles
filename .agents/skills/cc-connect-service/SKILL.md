---
name: cc-connect-service
description: Diagnose local cc-connect DingTalk/Codex bridge stalls by separating daemon health from stale chat session bindings, then restart the LaunchAgent only when needed.
---

# cc-connect Service Operations

Use this skill when the user asks whether `cc-connect` is stuck, asks to restart it, or reports DingTalk/Codex bridge messages are queued, hanging, or not responding.

## Workflow

1. Check the bridge CLI/session view first when available:

   ```bash
   cc-connect daemon status
   cc-connect sessions list
   ```

   Separate these cases:
   - Daemon unhealthy: process or LaunchAgent needs repair.
   - Daemon healthy but chat is bound to an old or idle resumed session: repair the chat/session binding before restarting repeatedly.

2. Check for a running service and PID:

   ```bash
   launchctl list | rg -i 'com.cc-connect.service|cc-connect'
   ps aux | rg -i '/cc-connect/bin/cc-connect|cc-connect'
   ```

3. Inspect LaunchAgent state:

   ```bash
   launchctl print gui/$(id -u)/com.cc-connect.service 2>&1 | sed -n '1,180p'
   ```

   Useful signals:
   - `state = running` means the LaunchAgent is active.
   - A non-zero value in `launchctl list` or `last terminating signal = Terminated: 15` can indicate a previous unclean stop.
   - The configured log path is usually `~/.cc-connect/logs/cc-connect.log`.

4. Inspect recent logs:

   ```bash
   tail -80 ~/.cc-connect/logs/cc-connect.log
   ```

   Common stuck indicators include long `slow agent send`, `message queued for busy session`, growing `queue_depth`, or a chat attached to an idle resumed session.

5. If the daemon is unhealthy, restart with launchctl:

   ```bash
   launchctl kickstart -k gui/$(id -u)/com.cc-connect.service
   ```

6. Verify the restart or session repair:

   ```bash
   launchctl list | rg -i 'com.cc-connect.service'
   ps aux | rg -i '/cc-connect/bin/cc-connect'
   launchctl print gui/$(id -u)/com.cc-connect.service 2>&1 | sed -n '1,130p'
   tail -40 ~/.cc-connect/logs/cc-connect.log
   ```

   Confirm the daemon is running, the target chat/session mapping is current, and logs show fresh bridge activity such as `dingtalk: stream connected`, `api server started`, or `cc-connect is running`.

## Safety

- Use `launchctl kickstart -k` for a normal service restart.
- Do not treat a healthy daemon as fixed just because it was restarted; verify the chat/session binding changed or resumed correctly.
- Do not delete `~/.cc-connect` state, session files, config, or logs unless the user explicitly asks and the impact is clear.
- Avoid persisting DingTalk session IDs, user IDs, tokens, or private message contents into memory.
