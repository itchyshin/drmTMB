#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SRC="$ROOT/docs/dev-log/dashboard"
DEST="${DRMTMB_DASHBOARD_DIR:-/tmp/drm-dashboard}"
PORT="${DRMTMB_DASHBOARD_PORT:-8765}"
HOST="${DRMTMB_DASHBOARD_HOST:-127.0.0.1}"
URL="http://$HOST:$PORT/"

python3 "$ROOT/tools/validate-mission-control.py"

mkdir -p "$DEST"
mkdir -p "$DEST/docs/design" "$DEST/docs/dev-log/after-task" "$DEST/docs/dev-log/comparator-results" "$DEST/docs/dev-log/simulation-artifacts"
cp "$SRC/index.html" "$SRC/status.json" "$SRC/sweep.json" "$SRC/version.txt" "$SRC/README.md" "$SRC/julia-gates.tsv" "$SRC/julia-capabilities.tsv" "$SRC/finish-100-slices.tsv" "$SRC/q4-target-inventory.tsv" "$SRC/phylo-balance-inventory.tsv" "$SRC/scale-phylo-diagnostics.tsv" "$SRC/phylo-profile-loglik-status.tsv" "$SRC/bootstrap-refit-accounting.tsv" "$SRC/phylo-q2-q4-target-map.tsv" "$SRC/phylo-extractor-status.tsv" "$SRC/bridge-payload-schema.tsv" "$SRC/bridge-provenance-fields.tsv" "$SRC/loconly-bridge-draft.tsv" "$SRC/bridge-serialization-status.tsv" "$SRC/bridge-reconstruction-status.tsv" "$SRC/julia-home-smoke.tsv" "$SRC/bridge-rejection-messages.tsv" "$SRC/capability-regeneration-status.tsv" "$SRC/bridge-parity-smoke-status.tsv" "$SRC/binomial-bridge-map.tsv" "$SRC/binomial-profile-status.tsv" "$SRC/ayumi-phylo-balance-100-slices.tsv" "$SRC/ayumi-phylo-balance-vocabulary.tsv" "$SRC/ayumi-phylo-balance-trackers.tsv" "$DEST/"
cp "$ROOT/docs/design/168-r-julia-finish-capability-matrix.md" "$DEST/docs/design/"
cp "$ROOT/docs/dev-log/after-task/"*.md "$DEST/docs/dev-log/after-task/"
if [ -d "$ROOT/docs/dev-log/comparator-results" ]; then
  cp -R "$ROOT/docs/dev-log/comparator-results/." "$DEST/docs/dev-log/comparator-results/"
fi
if [ -d "$ROOT/docs/dev-log/simulation-artifacts" ]; then
  cp -R "$ROOT/docs/dev-log/simulation-artifacts/." "$DEST/docs/dev-log/simulation-artifacts/"
fi
python3 - "$DEST/status.json" "$ROOT" <<'PY'
import json
import pathlib
import subprocess
import sys

status_path = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])

def git(*args):
    return subprocess.check_output(
        ["git", "-C", str(root), *args],
        text=True,
        stderr=subprocess.DEVNULL,
    ).strip()

try:
    branch = git("branch", "--show-current") or "detached"
    head = git("rev-parse", "--short", "HEAD")
    dirty = bool(git("status", "--porcelain"))
except Exception:
    branch = "unknown"
    head = "unknown"
    dirty = True

status = json.loads(status_path.read_text(encoding="utf-8"))
for repo in status.get("repos", []):
    if repo.get("name") == "drmTMB":
        repo["branch"] = branch
        repo["head"] = head
        repo["dirty"] = dirty
        repo["note"] = "Live dashboard worktree; dirty reflects current local files at serve time."
        break
status_path.write_text(json.dumps(status, indent=2) + "\n", encoding="utf-8")
PY

if command -v lsof >/dev/null 2>&1; then
  if lsof -iTCP:"$PORT" -sTCP:LISTEN -n -P >/dev/null 2>&1; then
    if command -v curl >/dev/null 2>&1; then
      served_version=$(curl -fsS "$URL/version.txt" 2>/dev/null || true)
      if [ "$served_version" != "$(cat "$DEST/version.txt")" ]; then
        echo "port $PORT is busy, but it is not serving this dashboard version" >&2
        exit 1
      fi
      if ! curl -fsS "$URL/status.json" >/dev/null 2>&1; then
        echo "port $PORT is busy, but status.json is not reachable" >&2
        exit 1
      fi
    fi
    echo "dashboard already listening at $URL"
    exit 0
  fi
fi

if [ "${1:-}" = "--background" ]; then
  nohup python3 -m http.server "$PORT" --bind "$HOST" --directory "$DEST" > "$DEST/server.log" 2>&1 &
  echo "$!" > "$DEST/server.pid"
  sleep 1
  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsS "$URL" >/dev/null 2>&1; then
      echo "dashboard failed to answer at $URL" >&2
      echo "log: $DEST/server.log" >&2
      exit 1
    fi
  fi
  echo "dashboard started at $URL"
  echo "log: $DEST/server.log"
  exit 0
fi

exec python3 -m http.server "$PORT" --bind "$HOST" --directory "$DEST"
