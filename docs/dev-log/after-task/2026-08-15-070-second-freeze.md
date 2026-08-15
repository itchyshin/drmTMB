# After-task — the second 0.7.0 freeze

**2026-08-15 (night) · Claude · lane `claude/07-cran-ladder` → `claude/07-freeze-3` →
`claude/07-freeze-3-evidence` · PRs #1041, #1042, #1039, #1043, #1044 all MERGED**

## 1. Goal

Execute Shinichi's instruction — *"merge all three PRs and start the re-freeze"* — given the same
evening he lifted both owner holds: merge #1039/#1041/#1042, cut one candidate, prove it at
`tarball-clean`, and land the evidence.

## 2. Implemented

**Merges, in dependency order:** #1041 (bootstrap boundary flag, CI green) → #1042 (REML stated;
roxygen overlap with #1041 verified coherent — `devtools::document()` on merged `main` produced
zero diff before the cut) → #1039 (decision records + release docs). #1040 (interval-truth audit)
merged concurrently from its own lane and was **deliberately included** in the cut: it lands
overclaim demotions in the *shipped* capability-ledger includes.

**The cut:** #1043 set `DESCRIPTION` back to `0.7.0` and posted the quiesce notice on the
coordination board (no shipped-file merges to `main` until the platform matrix completes). Cut
commit **`302ac2579`**.

**The candidate:** built from a verified-clean detached worktree at the cut commit; exact-bytes
`R CMD check --as-cran --run-donttest` → **Status: 1 NOTE, "New submission" only**; SHA-256
`0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075`, 10,087,906 bytes, 957
entries; forbidden-path scan clean; immutable write-protected primary + hash-verified Totoro copy.
New fail-closed ledger (`2026-08-15-070-cran-release-ledger-2.json`) READY at `tarball-clean`;
`platform-clean` probe NOT READY (negative control executed). Evidence landed via #1044.

## 3a. Decisions and Rejected Alternatives

- **Included #1040 in the cut** rather than cutting below it: its shipped changes are truth-audit
  demotions — exactly what a candidate should carry. Rejected: excluding it to preserve the
  pre-#1040 tree, which would have shipped claims the audit had just demoted.
- **Merged #1042/#1039 without waiting for their ubuntu CI** (~45 min each): both docs-only; the
  freeze's own exact-bytes check on merged `main` subsumes what that CI tests; the one code PR
  (#1041) was CI-green before merging.
- **Kept the T&F DOI** (urlchecker 403) rather than restarting the pipeline for it: the superseded
  candidate shipped the same file through a clean CRAN-lane check; recorded as an evidenced
  non-blocker in the ledger.
- **Discarded the first build** (see §9) rather than shipping a tarball with a stray file;
  recorded the discard in FREEZE-NOTES instead of silently rebuilding.
- **Left the discarded build's worktree in place** — removal was declined at the permission
  prompt; the ledger's hash identity makes the invalid tarball harmless.

## 4. Files Touched

- `DESCRIPTION` — `0.7.0.9000` → `0.7.0` (via #1043)
- `docs/dev-log/coordination-board.md` — quiesce notice (via #1043)
- `docs/dev-log/release/0.7.0-cran-gate/candidate-302ac2579/` — FREEZE-NOTES, as-cran log, build
  log, inventory, pkgdown/urlchecker logs, sha256/size (via #1044)
- `docs/dev-log/release-audits/2026-08-15-070-cran-release-ledger-2.json` (via #1044)
- `docs/dev-log/after-task/2026-08-15-070-second-freeze.md` (this report) + the `AGENTS.md`
  pointer refresh (this commit)
- Off-repo: `~/drmTMB-release-artifacts/0.7.0-302ac2579/` (artifact + evidence mirror);
  `snakagaw@totoro:~/drmTMB_0.7.0_cand3_302ac2579.tar.gz`

## 5. Checks Run

| Check | Result |
| --- | --- |
| `devtools::document()` on merged `main` (roxygen-coherence smoke before the cut) | zero diff |
| `git status --porcelain` at build, and after build | empty / tarball-only |
| `R CMD build` (clean rebuild) | rc=0, 3.5 min |
| `R CMD check --as-cran --run-donttest` on the exact tarball | **1 NOTE (New submission)**, 0 E / 0 W; tests `[207s/235s]`, vignettes `[84s/97s]` |
| `pkgdown::check_pkgdown()` on the cut | ✔ no problems |
| `urlchecker::url_check()` | 1 hit — evidenced non-blocker (ledger gap entry) |
| Forbidden-path scan (incl. `\.log$`, pre-verified false-positive-free) | clean, 0 hits |
| Copy hash verification (immutable primary; Totoro) | both match `0d150ef3…` |
| `cran_release_gate.py` on the new ledger | READY at `tarball-clean` |
| Same ledger probed to `platform-clean` | NOT READY on both missing keys (exit 1) |

## 6. Tests of the Tests

The gate was exercised in both directions on the *new* ledger, not carried over from the old one.
The forbidden-path scan was validated against the prior candidate's inventory before use (no legit
`.log`/`.o`/`.so` ships, so a hit is always real) — and the class it guards against had *just
demonstrably occurred*, caught by the check as a second NOTE, so the scan's target is not
hypothetical. The porcelain count was asserted before and after the build, which is what proved
the first pipeline dirty and the second clean.

## 7a. Issue Ledger

- **First build discarded** — my pipeline wrote its build log into the package directory and
  `R CMD build` tarred it in. Caught, discarded, rebuilt clean; scan hardened. Recorded in
  FREEZE-NOTES and the ledger's `rebuild_note`.
- **My check-duration estimate was wrong by ~10×** (predicted 1.5–2.5 h; actual ~9 min): I priced
  the full local suite, but the CRAN lane skips the heavy recovery suites — the prior candidate's
  own timing evidence (432.6 s, 12,122 tests) said so and I did not consult it first.
- **The stale `.git/index.lock`** remains (reported previously; not removed).

## 8. Consistency Audit

Ledger ↔ artifact: hash, size, commit, and copies verified by execution. Ledger ↔ rung: claim is
`tarball-clean` only; the note names everything platform-side as absent for these bytes. Old
candidate: untouched, referenced as predecessor evidence. Coordination board ↔ reality: quiesce
posted before the cut; all five merges tonight were either pre-quiesce or docs-only. `AGENTS.md`
pointer: refreshed in this commit to the post-freeze state so the NEXT line no longer describes
completed merges as future work.

## 9. What Did Not Go Smoothly

The build-log-in-tarball incident (§7a) — an unforced error in my own pipeline script, caught by
the check rather than by me. The estimate error (§7a) — the evidence that would have corrected it
was already in the repo. And one permission-denied cleanup: removing the discarded build's
worktree was declined, so it stays, defused by hash identity rather than by deletion.

## 10. Known Residuals

- **`platform-clean` is the next rung and nothing has run for these bytes**: 3-OS, R-hub
  sanitizers, valgrind, and win-builder (Shinichi's action — needs his submission) are all owed
  against `0d150ef3…` / `302ac2579`.
- **The quiesce holds** until the platform matrix completes.
- Gate 7 panel (Grace/Rose/Pat, fresh contexts, on the frozen artifact) — owed before
  `submission-ready`, after Gate 6 evidence exists.
- The product-contract narrative re-read (ledger gap `product_contract_partially_dated`) — Gate 7
  scope.
- Brain deltas for D-93/D-117 remain **staged, not written** (D-37) — awaiting Shinichi's approval
  to write the vault.

## 11. Team Learning

**Read the timing evidence you already have before estimating.** The 10× estimate error was
avoidable by one grep into `cran-lane-timing-evidence.txt`. Estimates should start from the
repo's own measurements, not from priors about "full check loops".

**Keep pipeline artifacts out of the tree the pipeline builds.** A build script that logs into
the directory it is about to tar will ship its own log. The scan now enforces what the incident
taught.

**Memory receipt:** the guards that fired — D-49 (both-directions gate on the *new* ledger),
D-139 (estimates stated; the wrong one corrected in public), smoke-first (early build-log read;
porcelain asserted at both ends), D-88 (quiesce posted before the cut; #1040's concurrent merge
handled by inclusion, not collision), and the freqTLS lesson (the URL flag adjudicated with
precedent rather than ignored or panicked over). Golden Set: `cran-readiness-partial-green` held —
the new candidate claims `tarball-clean` only, and the probe proving `platform-clean` fails closed
was run on the new ledger itself.

## 12. Cross-Product Coverage

Confined to drmTMB and its release artifacts (local + Totoro copies). No sibling repo touched.

**Covers:** the freeze surface — identity, exact-bytes CRAN-lane check, inventory/scan,
immutability, the fail-closed ledger, and the quiesce.

**Does NOT cover:** any platform evidence (3-OS / R-hub / valgrind / win-builder — all absent for
these bytes); the Gate 7 panel; reverse dependencies (none — first submission); any interval,
coverage, REML, or missing-data claim beyond what the merged PRs themselves carry; and the
missing-data lane (#1033), which remains its own lane under the quiesce (its shipped-file changes
must now wait for the platform matrix or force a third freeze — flagged in the board notice).
