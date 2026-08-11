# Handover — drmTMB 0.7.0: the gate now names the right candidate; win-builder is the next move

Meta: 2026-08-11 · Claude → next session (any platform) · **the committed repository is authoritative.**

Read `AGENTS.md`, then this file, then
[`../release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md`](../release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md).
Classify every item below `OWED`, `DONE`, or `PROTECTED` against live git and GitHub state before acting.

## Where this stands

**Highest proven rung: `tarball-clean`. Next unproven: `platform-clean`.** Unchanged by this arc — and
that is the point. What changed is that the rung is now backed by a machine-checkable ledger describing
the artifact we actually intend to ship.

| field | value |
| --- | --- |
| tarball | `drmTMB_0.7.0.tar.gz` |
| SHA-256 | `2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9` |
| size | 9,925,713 bytes |
| commit | `a75c3c9013e1e7c4ab8e56aa13baf5e668b99c76` |
| durable copies | `~/drmTMB-release-artifacts/0.7.0/` · `snakagaw@totoro:~/drmTMB_0.7.0_cand2.tar.gz` |
| ledger | `docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json` |
| PR | **#996 OPEN** at `079b66523` — do not auto-merge |

Verify the candidate is still current before trusting any of it:

```sh
git fetch origin && git diff --name-only 6065b90e5 origin/main | grep -v '^docs/dev-log/'   # empty => current
python3 ~/shinichi-brain/tools/cran_release_gate.py docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json
```

## OWED — next immediate steps

1. **win-builder, R-release and R-devel — Shinichi's action.** The only absent evidence class, and the
   only measurement of Windows CRAN-lane time. Run-book:
   [`../release/0.7.0-cran-gate/WIN-BUILDER-RUNBOOK.md`](../release/0.7.0-cran-gate/WIN-BUILDER-RUNBOOK.md).
   Upload the durable copy, not the `/private/tmp` one.
2. **PR #996 needs a merge decision.** It carries the DESCRIPTION 0.7.0 bump, the rung report, the new
   ledger, and `cran-comments.md`. No owner authorisation is on record for the DESCRIPTION bump or the
   `cran-comments.md` finalisation — the merge is the natural place to accept or reject them.
3. **The rights review is stale and MUST close before `submission-ready`.** It predates the 2026-08-09
   `inst/COPYRIGHTS` section adapting gllvmTMB `431e173f7198…` (GPL-3), including `drm_log_pnorm()`.
   The borrowing is documented to line granularity and the licence is compatible (GPL-3 inside
   GPL (>= 3)), so this is a review gap, not a licence defect — but it is unreviewed.
   `RUNG-REPORT-0.7.0.md` Gate 1 also records **UNRESOLVED 2**.
4. **Re-cut the source-clean evidence before `submission-ready`.** `product_contract` and
   `rendered_site` describe `8df6f2402`; 339 files changed since, including a new vignette
   (`vignettes/first-week-intervals.Rmd`) and a new Suggests (`detectseparation`). No rendered-site
   check covers the candidate.

All four are recorded as `known_evidence_gaps` in the ledger itself.

## Gotchas — each cost real time

- **"Same commit" is not "same bytes."** GitHub Actions and R-hub build their own tarball from the
  source checkout; they never see the frozen file. Only the local `--as-cran` and the Totoro valgrind
  run are exact-bytes. `cran-comments.md` briefly asserted otherwise and was corrected before commit.
- **The frozen bytes cannot be regenerated.** `R CMD build` embeds timestamps. Restore from a copy;
  never rebuild and assume equivalence.
- **The gate stats every path and fails closed.** A ledger anchored in a session scratchpad stops
  passing when `/private/tmp` is purged. Evidence now lives in `~/drmTMB-release-artifacts/0.7.0/`
  with `repo_path` back-references — but that root is machine-local and not version-controlled.
- **The gate has no supersession concept.** It ignores `superseded_by`, so the 2026-08-07 predecessor
  ledger *also* still returns `READY FOR CLAIMED RUNG`. The marker is prose-only. Read the first line
  of any ledger before citing it.
- **Cite valgrind as "clean on a documented seven-file subset", never "valgrind clean."**
- **Lane ownership is contested on paper.** Shinichi assigned the CRAN ladder to Claude on 2026-08-11
  (lane ownership only). Two unmerged Cursor branches (`cursor/07-tarball-clean`,
  `cursor/07-cran-readiness`, both 2026-08-07) rewrite the same board section to give Cursor the 0.7
  slices. **Not resolved here — Shinichi's call under D-87.**

## Landing state

| artifact | state |
| --- | --- |
| `claude/07-candidate-freeze-2` @ `079b66523` → #996 | **ACTIVE**, pushed |
| `~/drmTMB-release-artifacts/0.7.0/` | durable, **outside version control** — do not delete |
| ~12 foreign branches with unpushed commits; PRs #959, #955, #858 | **PROTECTED FOREIGN** — do not push, clean, or reconcile |
| `scratchpad/freeze.sh`, `scratchpad/freeze-ready.sh` | untracked, a prior session's — not staged here |
| Stale `.git/index.lock` (2026-08-05) | **REPORT ONLY** — needs a human `rm` |

## Live environment

Work in a fresh worktree off `origin/main`; **never** the primary checkout
(`/Users/z3437171/Dropbox/Github Local/drmTMB` is on a stale July branch, dirty, PROTECTED).
Never `git add -A`. Totoro is reachable through its existing ControlMaster (no Duo).

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e '...'   # the .Rprofile R-4.5 lib segfaults R 4.6
python3 -B tools/capability_ledger.py --check              # expect OK (31 generated outputs)
python3 -m unittest tools.tests.test_capability_ledger     # expect 67 tests OK
```

## Fenced — do not do without a new decision

Claim or write `platform-clean` · upload to CRAN · merge #996 · re-freeze or rebuild the tarball ·
edit `DESCRIPTION`/`NEWS.md` · resolve the Cursor/Claude board overlap · commit the tarball binary.
