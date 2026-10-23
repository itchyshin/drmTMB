# After Task: FTP upload post-#1061 julia-skip tarball to win-builder

**2026-08-17 · Cursor · `cursor/070-julia-skip-winbuilder-upload` from `origin/main` `5108c9207`**

## Goal

Exact-bytes FTP of the post-#1061 julia-skip tarball to win-builder R-release
and R-oldrelease only. No CRAN submit. No Ligges email. No #1033.

## Files created or changed

- `docs/dev-log/release/0.7.0-cran-gate/candidate-julia-skip/winbuilder-upload-receipt.md`
- `docs/dev-log/after-task/2026-08-17-julia-skip-winbuilder-upload.md` — this report

## Checks run and exact outcomes

| Check | Result |
| --- | --- |
| `shasum -a 256` before upload | `8764b2febf1d01b0c8709f3b931cae5195373ae9e1b35939fd5e39c39f058212` (match) |
| FTP R-release | curl exit 0, FTP 226, finish **2026-08-17T23:21:44Z** |
| FTP R-oldrelease | curl exit 0, FTP 226, finish **2026-08-17T23:21:47Z** |
| Post-upload listing | `drmTMB_0.7.0.tar.gz` on both lanes |

## Consistency audit

Docs-only. No formula / family / shipped-code change. Did not touch #1033,
`submit_cran`, or Ligges email.

## Tests of the tests

N/A — no test or package code change.

## What did not go smoothly

Lane preflight flagged foreign `main-direct` / dirty primary checkout; this slice
used a fresh worktree on a docs branch only.

## Team learning

Exact-bytes `curl -T` to win-builder remains the route that preserves the
candidate hash; `check_win_*` would rebuild and break the receipt.

## Design-doc / pkgdown / issues

None.

## Known limitations and next actions

STOP for Ligges mails. Do not invent check results. File emails when they
arrive; keep `platform-clean` unclaimed until then.
