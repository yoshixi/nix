# secureinput — report which process (if any) holds the macOS Secure Input
# lock. While any app holds it, AeroSpace's global hotkeys are suppressed
# system-wide. Terminals/browsers grab it on password fields; quitting such an
# app *while* it holds the lock orphans it onto loginwindow (needs a logout to
# clear), so prefer clicking OUT of the password field to release it cleanly.
secureinput() {
  local pid
  # ioreg lists the console-user dict more than once, so take the first match.
  pid=$(ioreg -l -w 0 | grep -o '"kCGSSessionSecureInputPID"=[0-9]*' | grep -o '[0-9]*$' | head -1)
  if [[ -z $pid || $pid == 0 ]]; then
    echo "✅ no secure input lock — AeroSpace shortcuts should work"
    return 0
  fi
  local comm
  comm=$(ps -p "$pid" -o comm= 2>/dev/null)
  if [[ -z $comm ]]; then
    echo "🔒 held by DEAD PID $pid (stale lock) → log out / reboot to clear"
    return 1
  fi
  echo "🔒 held by PID $pid: $comm"
  if [[ $comm == *loginwindow* ]]; then
    # An app that held the lock quit while still holding it, orphaning it onto
    # loginwindow. Lock/unlock won't release it — only a full session teardown.
    echo "   → orphaned onto loginwindow: log out (Apple menu) or reboot to clear"
  else
    echo "   → click OUT of the password field in that app (don't quit it)"
  fi
  return 1
}
