# drmTMB Mission-Control Dashboard

This directory stores the durable source for the local finish-plan dashboard.
The live copy is served from `/tmp/drm-dashboard` so agents can update JSON
status while the repository remains the source of truth.

Start or refresh the board with:

```sh
sh tools/start-mission-control.sh --background
```

The start script first runs:

```sh
python3 tools/validate-mission-control.py
```

The validator checks that `version.txt` matches the HTML build constant, phase
counts match slice statuses, metrics match the phase slices, canonical team
names are used, and the dashboard matrix has the same number of rows as
`docs/design/168-r-julia-finish-capability-matrix.md`.

Then open:

```text
http://127.0.0.1:8765/
```

The page reads `status.json` and `sweep.json` every eight seconds. Update those
JSON files as slices move from `queued` to `active`, `blocked`, `verified`,
`banked`, or `deferred`.

Rows marked `verified`, `banked`, or `covered` need evidence. Local evidence
files linked from the dashboard are copied into `/tmp/drm-dashboard` by the
start script so the served page can resolve them.

The `drmTMB` Repo Truth row is refreshed in the served `/tmp` copy at launch
time from `git branch`, `git rev-parse`, and `git status --porcelain`. The
source JSON keeps a placeholder because a committed file cannot truthfully
contain its own final commit hash.

Keep `version.txt` equal to the `BUILD` constant in `index.html`. Change both
only when the HTML or JavaScript changes. JSON data updates do not need a
version bump.
