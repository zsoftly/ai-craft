#!/usr/bin/env bash
# Transport-only send from any sender to a running Codex session.
#
# Usage: queue.sh <codex-thread-uuid-or-exact-name> <handoff-text>
#
# codex queue also accepts sandbox, approval, and config overrides. This script
# passes only --thread and --message, so a caller can pre-approve it without
# letting a sender change how the receiving session runs.

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "usage: queue.sh <codex-thread-uuid-or-exact-name> <handoff-text>" >&2
    exit 64
fi

thread=$1
handoff=$2

if ! [[ "$thread" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$ ]]; then
    echo "queue: thread must be a UUID or a name of letters, digits, dots, hyphens, or underscores" >&2
    exit 65
fi

if [ -z "$handoff" ]; then
    echo "queue: handoff text is empty" >&2
    exit 65
fi

codex_bin=${ZS_QUEUE_CODEX_BIN:-$(command -v codex || true)}
if [ -z "$codex_bin" ] || [ ! -x "$codex_bin" ]; then
    echo "queue: MISSING_CAPABILITY codex binary not found" >&2
    exit 69
fi

help_text=$("$codex_bin" queue --help 2>&1 || true)
for flag in --thread --message; do
    if ! grep -q -- "$flag" <<<"$help_text"; then
        echo "queue: MISSING_CAPABILITY $codex_bin queue lacks $flag" >&2
        exit 69
    fi
done

# The = form keeps a handoff that starts with a dash from being read as a flag.
exec "$codex_bin" queue --thread="$thread" --message="$handoff"
