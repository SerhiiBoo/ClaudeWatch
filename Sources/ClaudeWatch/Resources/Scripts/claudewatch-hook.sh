#!/bin/sh
# CLAUDEWATCH-MANAGED — bundled with ClaudeWatch.app
# Hard rule: never block, never interfere. Always exit 0 for non-PreToolUse events.
# If ClaudeWatch isn't running, drop the event silently — do NOT auto-launch.
PAYLOAD=$(cat)
pgrep -x ClaudeWatch >/dev/null 2>&1 || exit 0

CLAUDE_PID=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
HOOK_EVENT=$(printf '%s' "$PAYLOAD" | /usr/bin/python3 -c "import sys,json; print(json.loads(sys.stdin.read() or '{}').get('hook_event_name',''))" 2>/dev/null)

# Shared Python helpers: discover terminal bundle_id by walking the process tree.
# Walks up to 12 hops; falls back to process-name matching for known terminals
# so sub-agent process chains (which are longer) are still resolved.
_PY_HELPERS='
import subprocess, re

KNOWN_TERMINAL_NAMES = {
    "Terminal", "iTerm2", "WezTerm", "Alacritty", "kitty", "Ghostty",
    "Warp", "Hyper", "Code", "Cursor", "Nova", "zed",
}

def get_ppid(pid):
    r = subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)], capture_output=True, text=True)
    try: return int(r.stdout.strip())
    except: return None

def get_proc_name(pid):
    r = subprocess.run(["ps", "-o", "comm=", "-p", str(pid)], capture_output=True, text=True)
    return r.stdout.strip()

def get_bundle(pid):
    r = subprocess.run(["lsappinfo", "info", "-only", "bundleid", "-app", str(pid)], capture_output=True, text=True)
    m = re.search("\"CFBundleIdentifier\"=\"([^\"]+)\"", r.stdout)
    return m.group(1) if m else None

def bundle_for_named_app(name):
    """Resolve bundle id for a running app by display name via lsappinfo."""
    r = subprocess.run(["lsappinfo", "info", "-only", "bundleid", "-app", name], capture_output=True, text=True)
    m = re.search("\"CFBundleIdentifier\"=\"([^\"]+)\"", r.stdout)
    return m.group(1) if m else None

def find_bundle(start_pid):
    pid = start_pid
    for _ in range(12):
        pid = get_ppid(pid)
        if not pid or pid <= 1: break
        b = get_bundle(pid)
        if b: return b
        # lsappinfo returned nothing — try process-name fallback
        name = get_proc_name(pid)
        if name and name in KNOWN_TERMINAL_NAMES:
            b = bundle_for_named_app(name)
            if b: return b
    return ""
'

if [ "$HOOK_EVENT" = "PreToolUse" ]; then
    SOCK="$HOME/Library/Application Support/ClaudeWatch/permission.sock"

    # Build request JSON: forward all relevant payload fields to the Swift service.
    # agent_id / agent_type are present for sub-agent calls; absent for main-agent.
    # permission_mode reflects Claude's actual runtime mode for this call.
    REQUEST=$(printf '%s' "$PAYLOAD" | CLAUDE_PID="$CLAUDE_PID" /usr/bin/python3 -c "
import sys, json, os, uuid
${_PY_HELPERS}

claude_pid = int(os.environ.get('CLAUDE_PID') or 0) or None
bundle_id = find_bundle(claude_pid) if claude_pid else ''
d = json.loads(sys.stdin.read() or '{}')
out = {
    'tool_name': d.get('tool_name', ''),
    'tool_input': d.get('tool_input', {}),
    'session_id': d.get('session_id', ''),
    'cwd': d.get('cwd', ''),
    'pid': claude_pid,
    'bundle_id': bundle_id,
    'request_id': d.get('request_id', str(uuid.uuid4())),
    'permission_mode': d.get('permission_mode', ''),
    'agent_id': d.get('agent_id', ''),
    'agent_type': d.get('agent_type', ''),
}
print(json.dumps(out))
" 2>/dev/null)

    # If we failed to build the request, fall through to Claude's native prompt
    [ -z "$REQUEST" ] && exit 0

    # Connect to the app's Unix socket and exchange JSON (nc -w 125 = safety timeout)
    RESPONSE=$(printf '%s\n' "$REQUEST" | /usr/bin/nc -U -w 125 "$SOCK" 2>/dev/null)

    [ -z "$RESPONSE" ] && exit 0

    DECISION=$(printf '%s' "$RESPONSE" | /usr/bin/python3 -c "
import sys, json
print(json.loads(sys.stdin.read() or '{}').get('decision', 'none'))
" 2>/dev/null)

    case "$DECISION" in
        allow)
            printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","reason":"Approved via ClaudeWatch"}}'
            ;;
        deny)
            printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","reason":"Denied via ClaudeWatch"}}'
            ;;
        *)
            # No decision — exit with no output so Claude evaluates its own rules / prompts normally
            ;;
    esac

    exit 0
fi

# Existing Notification / Stop path — fire-and-forget via URL scheme
B64=$(printf '%s' "$PAYLOAD" | CLAUDE_PID="$CLAUDE_PID" /usr/bin/python3 -c "
import sys, json, base64, os
${_PY_HELPERS}

claude_pid = int(os.environ.get('CLAUDE_PID') or 0) or None
bundle_id = find_bundle(claude_pid) if claude_pid else ''
d = json.loads(sys.stdin.read() or '{}')
d['pid'] = claude_pid
d['bundle_id'] = bundle_id
print(base64.urlsafe_b64encode(json.dumps(d).encode()).decode().rstrip('='))
" 2>/dev/null)

[ -n "$B64" ] && /usr/bin/open -g "claudewatch://notify?payload=$B64" >/dev/null 2>&1
exit 0
