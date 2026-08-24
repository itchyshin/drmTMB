# After Task: fb8e6c 0.7.0 release-evidence closeout

## Goal

Replace stale predecessor release metadata with a hash-bound packet for the
frozen fb8e6c1 candidate, record the exact Windows results, and stop at a
maintainer submission decision.

## Implemented

cran-comments.md, the successor release ledger, and the Gate 7 report now
describe the immutable artifact 115abfa9: 5,546,071 bytes and 948 entries.
The ledger records the three exact-byte win-builder results and separates them
from source-state GitHub Actions and R-hub evidence.

## Mathematical Contract

No model, likelihood, formula grammar, estimator, or inferential claim changed.
This was release-evidence governance only.

## Files Changed

- cran-comments.md
- docs/dev-log/release-audits/2026-08-24-070-cran-release-ledger-115abfa9.json
- docs/dev-log/release-audits/2026-08-24-070-gate7-panel-115abfa9.md
- this report

## Checks Run

- Exact artifact identity: SHA-256, byte count, and entry count verified.
- Local exact CRAN lane: one expected new-submission NOTE, no errors or check
  warnings; FAIL 0 / WARN 19 / SKIP 30 / PASS 3501.
- Exact win-builder R-release, R-oldrelease, and R-devel: one NOTE each;
  raw outputs archived.
- Same-source 3-OS CI and three sanitizer jobs: success.
- Ledger parse and identity/authorization assertion: jq PASS.
- Fresh Grace, Rose, and Pat reviews: READY.

## Tests Of The Tests

The recorded jq assertion fails if the artifact hash, size, entry count,
no-submission condition, or any of the three Windows URLs is absent or changed.
It returned true on the committed ledger.

## Consistency Audit

The task-specific scan covered cran-comments.md, the successor ledger, old
ledger history, README.md, and NEWS.md for candidate hashes and release-rung
terms. Historical ledgers retain their original identities; the successor
ledger explicitly supersedes the immediately preceding candidate. No
behavioural documentation required an update.

## GitHub Issue Maintenance

An open-issue search for 0.7.0 CRAN could not reach the GitHub API because of
a network connection failure. No issue was opened, changed, or closed. The
protected issue and its artifacts were not inspected or modified.

## What Did Not Go Smoothly

The first fresh panel correctly withheld readiness because exact Windows
receipts, comments, and the ledger still described a predecessor. Grace's
fresh re-read then required that the packet be committed and have explicit
rights, policy, and rendered-material pointers. Those gaps were closed before
the final unanimous panel.

## Team Learning

For release work, a frozen archive, its exact Windows receipts, and the
machine-readable ledger must become durable together. A green source-state
matrix is valuable corroboration but cannot replace exact-byte evidence.

## Known Limitations

rchk remains red and attributed to installed TMB headers; it is not a platform
pass. Twelve unused sigma_i compiler warnings remain cleanup debt. Win-builder's
relationship to the archive is documented by client-side hash/size custody, not
server-side hash attestation.

## Next Actions

1. Shinichi decides separately whether to authorize CRAN submission.
2. Until then, do not call submit_cran(), upload to CRAN, tag, or announce.
3. Keep the frozen artifact and result URLs/logs intact; later source changes
   require a new candidate and evidence ladder.
