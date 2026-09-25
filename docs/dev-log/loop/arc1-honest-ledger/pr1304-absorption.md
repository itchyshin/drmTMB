# PR #1304 absorption note (S9)

Author: Hopper (S9, `arc1-honest-ledger`). Read-only against `codex/071-ordinary-laplace-bridge`;
nothing on that branch or on GitHub was touched to write this note. All git commands below compare
`origin/main` (tip `7f7293f2d59c15167a392fa53c2bf47a434804d4`, matching the lane's own base) against
`origin/codex/071-ordinary-laplace-bridge` (tip `9e959fc8a8e6f631790411521f278f0a89112d63`), fetched
read-only. Merge-base: `1ae582c9fc9060071bb147ea4aa7206744392419`. Measured, not assumed: 63 commits
ahead of that merge-base, 301 behind, 77 files changed (`git rev-list --count`, `git diff --name-only`
against the merge-base; `gh pr view 1304 --json files` returns the same 77 paths).

## 1. Summary

**What #1304 claims (its own PR body, `gh pr view 1304 --json body`):**

> Adds the 0.7.1 ordinary-RI Laplace parity closeout to the R-to-Julia bridge registry and
> regenerates the capability tables, scoreboard, and source-pinned parity matrix. The retained S7
> source proof now verifies declared campaign source subsets against their Git commits, with
> positive and tamper/missing-root/foreign-bundle controls. No campaign task was submitted or
> rerun. The evidence is explicitly bounded to four frozen scenarios with 500 paired seeds per
> fixture. It does not claim general calibration or cross-engine coverage equality.

Its own verification section states: "Source-pinned parity-matrix and 071-four-fixture-summary
tests passed against DRM.jl b2caf00f."

**DRModels (DRM.jl) SHA the evidence was measured at:** `b2caf00f23f080fe89028966a4bfb098ef095510`
(short `b2caf00f`). Verified two independent ways, not just quoted from the plan:
- PR body's own verification line ("against DRM.jl b2caf00f").
- The after-task report in the PR, `docs/dev-log/after-task/2026-09-12-071-ordinary-laplace-closeout.md`:
  "`docs/design/parity-scoreboard.md` and `docs/design/parity-matrix.md` are regenerated at DRM.jl
  `b2caf00f23f080fe89028966a4bfb098ef095510`."

A second, R-side pin is also named in the branch's own check-log
(`docs/dev-log/check-log.d/2026-09-11-071-ordinary-laplace-active-campaign-pins.md`): "the contract
now names frozen drmTMB `453cff…` and DRM.jl `b2caf00…` pins; historical `b877…` receipts remain
explicitly non-current." `453cff782` is itself one of the 63 PR commits ("Harden S7 retained receipt
checksums"), i.e. the campaign's own R-side freeze point. The `b877…` pin is a historical,
already-superseded-within-#1304 pin and is not used anywhere in this note.

**What the PR actually mixes (confirmed by diffing content, not just trusting the body):**
1. A genuinely new, reusable finding: DRM.jl's default ordinary-random-intercept route (`:LA`) is
   GHQ-32 for scalar mu-side `(1 | g)` Binomial/Poisson/NB2, and is *distinct* from DRM.jl's new
   explicit `:Laplace` mode. No capability row for this scalar ordinary-RI shape (Binomial, Poisson,
   or NB2, mu-only) exists on `origin/main` today (`grep -E "^ordinary_" inst/extdata/julia-capabilities.tsv`
   returns nothing), so this is evidence about a route the bridge can already reach, not a claim
   already ledgered; exactly the T5/S5 gap Arc 1 is chartered to close.
2. New public API and coverage: a `marginal = "Laplace"` argument on `drmTMB()` (absent from
   `origin/main`'s `R/drmTMB.R`; confirmed by `grep -n "marginal = NULL" R/drmTMB.R`, which finds
   nothing on `main`), a new native (TMB) coupled NB2 `mu`/`sigma` labelled random-intercept pair
   (`src/drmTMB.cpp`, `R/drmTMB.R`), and a new native "coupled Cholesky" profiling path
   (`R/profile.R`). Two new `julia-capabilities.tsv` rows, `ordinary_ri_scalar_laplace` and
   `ordinary_nb2_coupled_laplace`, both at `r_bridge_status = supported` / `claim_status = partial`,
   ride on this new argument.
3. A large amount of content that is simply **stale relative to `origin/main`**, not neutral and not
   new: `beta_family()` was `beta()` in drmTMB at #1304's branch point and was later renamed, with
   `beta()` kept as a deprecated alias (`R/family.R` on `main`: `beta <- function() { lifecycle::deprecate_warn(...); beta_family() }`).
   #1304 still spells it `beta()` everywhere it touches capability text. Similarly, one
   `capability-ledger` row (`mc-0568`/`mc-0576`) points at a 2026-09-12 recovery folder that
   `origin/main` has since re-certified twice more (through PR #1375 Wave B2 and PR #1398, dated
   2026-09-20); folding #1304's version would regress that chain of custody. The README and
   DESCRIPTION rewrites revert `main`'s current, more recently reader-first-edited text (commit
   `54df129fe`, "docs: make package description reader-first") to an older draft.

## 2. File table (77 files, every file in the PR)

Tag legend: **FOLD-NOW** = evidence/tests about a route already reachable on `origin/main`, safe to
carry into a fresh PR-D with provenance. **ARC-2** = new public API or new coverage, deferred.
**OBSOLETE** = superseded by `origin/main`'s own later commits (verified by diff, not assumed).

### Core R / C++ / docs (marginal= and coupled-NB2 API surface)

| Path | Tag | Reason |
|---|---|---|
| `R/drmTMB.R` | ARC-2 | Adds the public `marginal = NULL` argument and its validation/cli_abort text; absent from `origin/main` entirely. Foreign file under Arc 1's own invariants regardless. |
| `R/julia-bridge.R` | ARC-2 | 376+/160- lines, almost entirely new `marginal=` plumbing (`drm_julia_validate_marginal()`, `drm_julia_scalar_laplace_formula()`, `drm_julia_coupled_ordinary_mu_sigma()`) plus capability-comparison text for the two new rows. No independent bug fix found in the sampled hunks. |
| `R/profile.R` | ARC-2 | 245+/63- lines. Bulk is new "native coupled Cholesky" profiling for the coupled-NB2 route (`drm_profile_native_coupled_cholesky_confint()` and helpers). One hunk in `drm_wald_confint()` (removes `bias_applied`/`wald_bias_corrected`/rho12-specific boundary warning/`drm_as_confint_table()` wrapper) is **stale**, not new: `origin/main` has since *added* that bias-correction and rho12 reporting; applying this hunk would regress it. Do not fold that hunk. |
| `src/drmTMB.cpp` | ARC-2 | Native coupled NB2 `mu`/`sigma` covariance implementation named explicitly in the ultra-plan as coverage-widening. |
| `man/drmTMB.Rd` | ARC-2 | Regenerated for the new `marginal` parameter (commit `0581bc877` says so directly: "regenerate drmTMB.Rd for the marginal argument"). |
| `DESCRIPTION` | OBSOLETE | Full `Description:` field rewrite reverting to an older draft (does not match `main`'s current, more recently edited text); unrelated to `marginal=`/NB2. Classic README/DESCRIPTION churn. |
| `.gitignore` | OBSOLETE | Net diff removes the "graft's local graph cache" ignore rule `origin/main` added later; applying it verbatim regresses `.gitignore`. The one useful add; ignoring `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/receipt/*`; should be hand-added to PR-D's `.gitignore` only if/when the evidence directory is folded (see §4), not by taking this file's diff. |
| `README.md` | OBSOLETE | 424+/89- lines reverting `main`'s current, reader-first README (commit `54df129fe`) to an older draft. Not tied to `marginal=`/NB2 specifically. |
| `docs/design/01-formula-grammar.md` | ARC-2 | Net new content is the coupled-NB2 grammar row (`y ~ x1 + (1 \| p \| id), sigma ~ x2 + (1 \| p \| id), family = nbinom2()`, "Implemented, parity-only"). The rest of the diff is the stale `beta_family()`→`beta()` reversion (do not fold). |
| `docs/design/04-random-effects.md` | ARC-2 | Documents the new "one bounded ordinary NB2 mu–sigma intercept pair" as an extension of the labelled-covariance section. |
| `docs/design/143-phase-18-structured-workflow-registry.md` | ARC-2 | Updates the Counts workflow-status cell to mention the new bounded NB2 pair; also carries the stale `beta_family()`→`beta()` reversion in a separate cell (do not fold that part). |
| `docs/design/261-reml-by-route.md` | ARC-2 | Row count "37 rows" → "39 rows" tracks the two new capability rows exactly. Also carries the stale `beta()` reversion in two formula cells (do not fold those). |
| `docs/design/capability-status.md` | ARC-2 | Adds two table rows naming the new scalar-Laplace and coupled-NB2 capabilities as "implemented" (stronger wording than the TSV's own `claim_status = partial`; a phrasing inconsistency worth flagging to whoever owns Arc 2, not fixed here). |
| `docs/dev-log/known-limitations.md` | ARC-2 | Documents the boundary of the new coupled-NB2 exception ("One ordinary NB2 exception admits exactly one matching labelled complete-data mu/sigma random-intercept pair..."). |
| `vignettes/formula-grammar.Rmd` | ARC-2 | Net new content is the same coupled-NB2 grammar row as the design doc (confirmed `origin/main` already carries the *other* ~35 rows in this table, including 12 pre-existing `(1 \| p \| id)` matches, so this is not a wholesale table rewrite; the diff bulk is the stale `beta_family()`→`beta()` reversion applied across ~35 unrelated rows; do not fold those). |
| `inst/extdata/julia-capabilities.tsv` | ARC-2 | Adds two new rows: `ordinary_ri_scalar_laplace` and `ordinary_nb2_coupled_laplace` (both `r_bridge_status = supported`, `claim_status = partial`, both keyed on `marginal = "Laplace"`). Also edits 3 pre-existing rows (`phylo_gamma_beta_binomial`, `general_covariance_structured`, `fe_beta`) whose only change is the stale `beta_family()`→`beta()` reversion; those 3 edits must NOT be folded. |
| `docs/dev-log/dashboard/julia-capabilities.tsv` | ARC-2 | Byte-identical generated mirror of the row above (confirmed identical to `inst/extdata/julia-capabilities.tsv` on `main`); same two new rows, same stale rename in the same 3 rows. |
| `docs/design/parity-matrix.md` | OBSOLETE | Generated document, regenerated at DRM.jl `b2caf00f` against #1304's stale 301-commits-behind capability set. Arc 1's S1a/S10 regenerate this fresh; folding this copy would reintroduce the `beta()` staleness and an old pin. |
| `docs/design/parity-scoreboard.md` | OBSOLETE | Same reasoning as `parity-matrix.md`: generated, stale pin, regenerated by Arc 1 (S1b/S10). |
| `tools/write-parity-matrix.R` | ARC-2 | Diff is (a) removal of the `beta`→`beta_family` constructor special-case in `pm_family_constructor()`; **stale, do not fold** (main's current mapping is correct); (b) two new `st(...)` capability entries for the two new (ARC-2) rows, whose boundary text is specific to the `marginal = "Laplace"` capability IDs. S1a rewrites this generator from scratch regardless (honest-state vocabulary), so nothing here is adopted verbatim. |
| `tools/write-parity-scoreboard.R` | FOLD-NOW | 351 new lines, but the substantive new functions (`sb_ordinary_laplace_summary()`, `sb_ordinary_laplace_source_drift()`) read and fail-closed-validate `reconciled-summary.tsv`; generic reader/staleness-check logic over the FOLD-NOW evidence artifact, not specific to the new capability IDs. S1b (Grace) can adapt this pattern for whichever capability_id Arc 1's own S5 row ultimately uses; it should not reuse the literal `ordinary_ri_scalar_laplace`/`ordinary_nb2_coupled_laplace` IDs unless Arc 2 lands first. |

### Tests / test scaffolding

| Path | Tag | Reason |
|---|---|---|
| `tests/testthat/test-071-four-fixture-summary.R` | FOLD-NOW | New file. Tests `reconcile-four-fixture-summary.R` (fails closed when a receipt is missing) and the source-commit staging/tamper verifier; this is exactly "the S7 source-subset verifier" the ultra-plan names as FOLD-NOW. Does not test `marginal=` itself. |
| `tests/testthat/test-julia-bridge.R` | ARC-2 | 164 new lines, all testing `marginal = "Laplace"` payload/validation behaviour (`drm_julia_validate_marginal()`, `requested_marginal`). |
| `tests/testthat/test-julia-bridge-coef-labels.R` | ARC-2 | New test is specifically for "the scalar Laplace families" coefficient-label route. |
| `tests/testthat/test-nbinom2-location-scale.R` | ARC-2 | 91 new lines exercising the native coupled NB2 mu/sigma random-intercept pair. |
| `inst/extdata/env-skip-census.tsv` | FOLD-NOW | Adds the two census rows for `test-071-four-fixture-summary.R` (needed if that FOLD-NOW test file is folded). Also *removes* 7 lines for `test-dinnage-audit-*.R`/`test-pkgdown-public-surface.R`; **stale**: those test files still exist on `origin/main` today (`git cat-file -e origin/main:tests/testthat/test-dinnage-audit-wave1.R` succeeds); do not apply that part of the diff. |
| `tools/source-tree-tests.txt` | FOLD-NOW | Same pattern: adds `test-071-four-fixture-summary.R` (needed, fold it) and removes `test-dinnage-audit-wave1.R`/`test-pkgdown-public-surface.R` (both still present on `main`; **stale, do not apply**). |

### `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/` (27 new files; the four-fixture campaign)

None of these paths exist on `origin/main` (confirmed: `git ls-tree origin/main -- docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/` is empty), so none can be "superseded by main" on file-collision grounds; they are the raw substance of finding #1 in §1. All measured at DRM.jl `b2caf00f23f080fe89028966a4bfb098ef095510` (drmTMB-side freeze `453cff782`).

| Path | Tag | Reason |
|---|---|---|
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/four-fixture-contract.md` | FOLD-NOW | The frozen four-fixture design contract (which shapes, which pins) that all downstream evidence cites. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/cost-probe.md` | FOLD-NOW | D-139-style run-time/cost estimate for the campaign; provenance context for why it was sized as it was. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconciled-summary.tsv` | FOLD-NOW | The core artifact: the four-fixture paired-seed (500 seeds/fixture) profile classification the PR body describes. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-coverage-summary.tsv` | FOLD-NOW | Coverage summary data feeding the reconciled summary. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-coverage-summary.tsv.sha256` | FOLD-NOW | Checksum for the coverage summary data above. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconcile-four-fixture-receipt.R` | FOLD-NOW | Reconciliation script producing `reconciled-summary.tsv` from raw attempts; needed for reproducibility of the cited evidence. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconcile-four-fixture-summary.R` | FOLD-NOW | Summary-generation script for the four-fixture evidence; same reproducibility role as above. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/run-four-fixture-receipt.R` | FOLD-NOW | Runner script that produces per-fixture receipts feeding the reconciled summary. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/verify-source-commit.sh` | FOLD-NOW | The S7 source-subset verifier itself, named explicitly FOLD-NOW in the ultra-plan ("How #1304 is absorbed"). |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/test-source-commit-proof.sh` | FOLD-NOW | Test harness for the S7 source-subset verifier above. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-reconcile-campaign.R` | FOLD-NOW | Reconciler feeding the coverage summary; supporting machinery for the cited evidence. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-write-coverage-summary.R` | FOLD-NOW | Writer producing `s7-coverage-summary.tsv`; supporting machinery for the cited evidence. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-write-coverage-summary-scopefix.R` | FOLD-NOW | Scope-fix revision of the coverage-summary writer above; same evidence chain. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fit-diagnostics.R` | FOLD-NOW | Per-seed fit-diagnostics machinery generating the raw data behind `reconciled-summary.tsv`. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fit-attempt.R` | FOLD-NOW | Per-seed fit-attempt machinery; part of the evidence's chain of custody. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-run-attempt.R` | FOLD-NOW | Single-attempt runner invoked by the campaign dispatcher; part of the evidence's chain of custody. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-run-task.R` | FOLD-NOW | Per-task runner invoked by the campaign dispatcher; part of the evidence's chain of custody. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-task-dispatch.R` | FOLD-NOW | Task dispatcher for the campaign; part of the evidence's chain of custody. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-live-fit-factory.R` | FOLD-NOW | Live-fit factory used by the campaign runner; part of the evidence's chain of custody. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-campaign-fixture.R` | FOLD-NOW | Seedable fixture generator for the four frozen scenarios; part of the evidence's chain of custody. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-attempt-contract.R` | FOLD-NOW | Contract defining a valid campaign attempt; part of the evidence's chain of custody. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/prepare-s7-campaign-bundle.R` | FOLD-NOW | Source-tree bundling script feeding the S7 source-subset verifier's input. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/prepare-s7-campaign-manifest.R` | FOLD-NOW | Manifest-prep script feeding the S7 source-subset verifier's input. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-array.sh` | FOLD-NOW | Cluster job-array script that ran the campaign. Cluster-specific paths mean this is provenance/documentation of *how* the evidence was produced more than directly re-runnable as-is on Totoro/DRAC without adaptation; kept as FOLD-NOW because it is still part of the evidence's chain of custody, not new API. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-preflight.sh` | FOLD-NOW | Preflight check for the job-array run above; same chain-of-custody reasoning. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-reconcile.sh` | FOLD-NOW | Post-run reconciliation step for the job array; same chain-of-custody reasoning. |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-worker.sh` | FOLD-NOW | Per-node worker script for the job array; same chain-of-custody reasoning. |

### `docs/dev-log/after-task/` (4 files)

| Path | Tag | Reason |
|---|---|---|
| `docs/dev-log/after-task/2026-09-09-071-ordinary-laplace-native-coupled-nb2.md` | ARC-2 | Documents implementing the native coupled NB2 mu/sigma pair; the new-coverage prerequisite for the bridge feature. |
| `docs/dev-log/after-task/2026-09-12-071-ordinary-laplace-closeout.md` | ARC-2 | Its "Implemented" section is the registry-row insertion and `marginal=`-keyed capability rows; predominantly documents the new API, though it also states the useful "`:Laplace` is distinct from the legacy GHQ-32 `:LA` route" framing (captured separately as FOLD-NOW evidence, see §1 finding 1). |
| `docs/dev-log/after-task/2026-09-12-071-source-subset-proof-reconciliation.md` | FOLD-NOW | Documents repairing the S7 reconciliation guard itself; directly the FOLD-NOW verifier's design fix. |
| `docs/dev-log/after-task/2026-09-13-071-ci-repair.md` | OBSOLETE | CI repair specific to keeping #1304's own (foreign) branch green; moot once folded material lands fresh on PR-D instead of continuing that branch. |

### `docs/dev-log/check-log.d/` (12 files)

| Path | Tag | Reason |
|---|---|---|
| `docs/dev-log/check-log.d/2026-09-09-071-native-profile-thread-control.md` | FOLD-NOW | Bug-fix record for the four-fixture runner's thread-option forwarding; correctness of the retained evidence. |
| `docs/dev-log/check-log.d/2026-09-09-071-nb2-free-target-manifest.md` | FOLD-NOW | Fixes a duplicate free/derived-parameter listing in the NB2 RI manifest; evidence correctness. |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-current-pin-boundary.md` | FOLD-NOW | Pin-boundary provenance record for the campaign. |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-g0.md` | OBSOLETE | G0 groundwork checkpoint that explicitly disclaims any claim ("no bridge fit, parity, profile, campaign, or release claim is made"); no citable content, superseded by the later closeout/summary-gate entries. |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-native-coupled-nb2.md` | ARC-2 | Records the native coupled-NB2 prerequisite (new coverage). |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-summary-gate.md` | FOLD-NOW | Documents the reconciled-summary gate/tool directly backing `reconciled-summary.tsv`. |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-task-provenance.md` | FOLD-NOW | Documents the per-task provenance-row guard for the four-fixture runner. |
| `docs/dev-log/check-log.d/2026-09-11-071-ordinary-laplace-active-campaign-pins.md` | FOLD-NOW | Names the frozen drmTMB (`453cff782`) and DRM.jl (`b2caf00f`) pins used for the cited evidence; direct provenance. |
| `docs/dev-log/check-log.d/2026-09-11-071-source-commit-proof.md` | FOLD-NOW | Check-log for the S7 source-subset verifier itself. |
| `docs/dev-log/check-log.d/2026-09-12-071-ordinary-laplace-closeout.md` | OBSOLETE | Short record of test-suite pass and matrix/scoreboard regeneration at the old pin; redone at the current pin by Arc 1's own S10 MECHANICAL-VERIFY. |
| `docs/dev-log/check-log.d/2026-09-12-071-source-subset-proof-reconciliation.md` | FOLD-NOW | Check-log twin of the after-task entry above; the S7 verifier's repair. |
| `docs/dev-log/check-log.d/2026-09-13-071-ci-repair.md` | OBSOLETE | CI repair specific to #1304's own branch state; moot for a fresh PR-D. |

### `docs/dev-log/handover/` (2 files) and `docs/dev-log/implementation-recovery/2026-09-12-ordinary-laplace-merge-c17c2-c14-final-source-compatibility/` (4 files)

| Path | Tag | Reason |
|---|---|---|
| `docs/dev-log/handover/2026-09-13-claude-handover-071-ordinary-laplace.md` | OBSOLETE | Cross-session handover for continuing #1304's own branch; moot once we fold selectively into a fresh PR-D instead of continuing that branch. |
| `docs/dev-log/handover/2026-09-13-cursor-handover-071-ordinary-laplace.md` | OBSOLETE | Same reasoning. |
| `docs/dev-log/implementation-recovery/2026-09-12-ordinary-laplace-merge-c17c2-c14-final-source-compatibility/dirty-state.txt` | OBSOLETE | Backs capability-ledger row `mc-0576` (see next table), which `origin/main` has already superseded with two later re-certifications (PR #1375 Wave B2, PR #1398, through 2026-09-20). Folding this recovery snapshot would regress the chain of custody. |
| `docs/dev-log/implementation-recovery/2026-09-12-ordinary-laplace-merge-c17c2-c14-final-source-compatibility/provenance.tsv` | OBSOLETE | Same reasoning. |
| `docs/dev-log/implementation-recovery/2026-09-12-ordinary-laplace-merge-c17c2-c14-final-source-compatibility/raw-attempts.tsv` | OBSOLETE | Same reasoning. |
| `docs/dev-log/implementation-recovery/2026-09-12-ordinary-laplace-merge-c17c2-c14-final-source-compatibility/summary.tsv` | OBSOLETE | Same reasoning. |

### `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`

| Path | Tag | Reason |
|---|---|---|
| `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv` | OBSOLETE | Diff touches exactly 3 rows (`mc-0568`, `mc-0569`, `mc-0576`). Verified by diff, not assumed: on `origin/main` this row (`mc-0568`) points to `docs/dev-log/implementation-recovery/2026-09-20-pr1398-reader-vocabulary-c17c2-c14-final-source-compatibility/...`, i.e. a re-certification dated 2026-09-20 (after PR #1375 Wave B2 and PR #1398). #1304's version (`mc-0576`) points to the older `2026-09-12-ordinary-laplace-merge-...` folder and is missing those later re-certifications entirely. Folding this would regress the model-15 compatibility chain of custody. |

**File-tag totals (77 files):** FOLD-NOW = 40, ARC-2 = 21, OBSOLETE = 16.

## 3. Commit table (63 commits, every commit in the PR)

Retrieved via `gh api repos/itchyshin/drmTMB/pulls/1304/commits --paginate`. Tag = the tag of the
file(s) the commit mostly touches, or MIXED with a note when it straddles.

| SHA | Subject | Tag |
|---|---|---|
| `d51ced6c0` | docs: pin ordinary Laplace four-fixture contract | FOLD-NOW |
| `6bb773332` | feat: add bounded NB2 mean-scale RI covariance | ARC-2 |
| `a03e3ad96` | feat: bridge ordinary Laplace parity fixtures | MIXED; `marginal=` bridge wiring is ARC-2; the fixture receipts it seeds are FOLD-NOW |
| `e58a28273` | fix: preserve per-target parity profile receipts | FOLD-NOW |
| `3efd65083` | feat: stream durable parity profile sidecars | FOLD-NOW |
| `4ae31d5d5` | feat: profile native coupled Cholesky coordinates | ARC-2 |
| `c65355508` | fix: persist profile rows before Julia teardown | FOLD-NOW |
| `0094a19a6` | fix: isolate parity receipt engine tasks | FOLD-NOW |
| `627805ae1` | fix: retain engine-specific profile readiness | FOLD-NOW |
| `925ace233` | fix: retain coupled target inventory scope | FOLD-NOW |
| `9abb2d0f0` | docs: record adverse coupled profile gate | FOLD-NOW |
| `d24a30d09` | Retain Julia profile endpoint diagnostics | FOLD-NOW |
| `e46c2d700` | Invalidate stale ordinary Laplace receipts | FOLD-NOW |
| `90051c6ea` | docs: pin four-fixture task provenance | FOLD-NOW |
| `340a60c5f` | fix: reconcile task provenance schema | FOLD-NOW |
| `e9eae1473` | fix: keep NB2 receipt targets on free scale | FOLD-NOW |
| `64c3c1fc7` | fix: keep native profiles on their default path | ARC-2 |
| `9939ace07` | feat: classify ordinary Laplace parity receipts | FOLD-NOW |
| `29773fb5d` | docs: record ordinary Laplace parity receipt | FOLD-NOW |
| `704e2fe25` | docs: record ordinary Laplace cost probe | FOLD-NOW |
| `9519f9ff2` | fix: allow generated parity scoreboard successors | FOLD-NOW |
| `1ea43e5be` | docs: refresh parity scoreboard source pin | OBSOLETE |
| `79d766431` | docs: close ordinary Laplace fixture classification gate | FOLD-NOW |
| `07c50af0b` | feat: freeze ordinary Laplace S7 campaign plan | FOLD-NOW |
| `f9a40fa60` | feat: add seedable ordinary Laplace campaign fixtures | FOLD-NOW |
| `0972c8670` | feat: validate retained ordinary Laplace attempts | FOLD-NOW |
| `952446b68` | feat: resolve ordinary Laplace S7 worker tasks | FOLD-NOW |
| `f7426669a` | feat: add guarded ordinary Laplace worker entrypoint | FOLD-NOW |
| `c2d9917f3` | feat: freeze ordinary Laplace campaign bundle | FOLD-NOW |
| `e474864bd` | feat: expand ordinary Laplace S7 array tasks | FOLD-NOW |
| `95469aac8` | feat: classify ordinary Laplace S7 fit diagnostics | FOLD-NOW |
| `98113e7c4` | feat: classify ordinary Laplace S7 fit attempts | FOLD-NOW |
| `568056fbc` | feat: dispatch ordinary Laplace S7 task receipts | FOLD-NOW |
| `9c7ee1c47` | feat: add guarded ordinary Laplace Fir worker | FOLD-NOW |
| `947edd2f4` | feat: enable approved ordinary Laplace S7 worker | FOLD-NOW |
| `7317e1671` | feat: retain atomic ordinary Laplace task receipts | FOLD-NOW |
| `a113cf029` | feat: add ordinary Laplace Fir preflight worker | FOLD-NOW |
| `621891c51` | feat: reconcile retained ordinary Laplace S7 campaign | FOLD-NOW |
| `46ec8a1ac` | fix: forward Laplace for coupled S7 fixture | ARC-2 |
| `d49b2b9fc` | feat: add guarded Fir S7 array payload | FOLD-NOW |
| `e1f672db8` | perf: avoid suggested packages in S7 preflight | FOLD-NOW |
| `19d20ef1b` | fix: retain coupled q2 Laplace bridge route | ARC-2 |
| `764ceaf9b` | fix: declare compiled TMB package metadata | ARC-2; DESCRIPTION metadata tied to compiling the new `src/drmTMB.cpp` coupled-NB2 code |
| `ade8aea08` | feat: add fail-closed S7 coverage writer | FOLD-NOW |
| `217f5bcdf` | feat: classify retained S7 coverage in scoreboard | FOLD-NOW |
| `9a0f66297` | fix: bind S7 coverage to frozen source trees | FOLD-NOW |
| `854d6381c` | fix: verify S7 source-tree comparison receipt | FOLD-NOW |
| `ddf16873e` | test: gate scoreboard rendering on S7 receipt | FOLD-NOW |
| `fcf925e93` | test: prove campaign source commits | FOLD-NOW |
| `d63d98387` | fix: stream source archive proof | FOLD-NOW |
| `453cff782` | Harden S7 retained receipt checksums | FOLD-NOW; also the named drmTMB-side campaign freeze commit |
| `4ab0486eb` | test: supply fixed-effect class to Julia inference mock | ARC-2 |
| `6f1d49d46` | docs: record active ordinary Laplace campaign pins | FOLD-NOW |
| `148baeb98` | docs: log active ordinary Laplace campaign pins | FOLD-NOW |
| `30dcb9103` | docs: classify retained ordinary Laplace coverage | FOLD-NOW |
| `0285af445` | docs: close ordinary Laplace parity evidence | MIXED; mostly ARC-2 (row insertion, closeout, regenerated matrix/scoreboard at old pin) |
| `81e080176` | test: recertify model-15 compatibility receipt | OBSOLETE |
| `8744b91d7` | docs: hand off ordinary Laplace CI repair to Cursor | OBSOLETE |
| `afa88a5b3` | docs: hand off ordinary Laplace CI repair to Claude | OBSOLETE |
| `e6b4981bc` | fix(ci): repair the four PR #1304 failures without touching retained evidence | OBSOLETE |
| `0dfbbbb31` | fix(ci): align the branch test and the REML-by-route table with the registry URL fix | ARC-2; the REML-by-route row-count change tracks the two new capability rows |
| `0581bc877` | docs(man): regenerate drmTMB.Rd for the marginal argument (codoc WARNING on PR #1304) | ARC-2 |
| `9e959fc8a` | test(071): skip every four-fixture-summary block when the source tree is absent | FOLD-NOW |

**Commit-tag totals (63 commits):** FOLD-NOW = 47, ARC-2 = 11 (including the 2 MIXED-mostly-ARC-2), OBSOLETE = 5.

## 4. Fold plan for PR-D

PR-D branches fresh from `origin/main` (not from #1304, not from this lane's branch). Every item
below carries a provenance line naming its #1304 commit(s) and the DRModels SHA it was measured at.
**Nothing is re-labelled to the current pin `da8b3f8711beb5ef3186b890544c2e7850c7f194` unless it is
re-measured there.** Everything else keeps its original `b2caf00f23f080fe89028966a4bfb098ef095510`
citation explicitly.

1. **The four-fixture campaign evidence directory**; copy
   `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/` (27 files) verbatim to the same path
   on PR-D. Provenance line: "Folded from itchyshin/drmTMB#1304, commits `d51ced6c0`…`9e959fc8a`
   (see the S7/four-fixture commit set in §3), measured against DRM.jl
   `b2caf00f23f080fe89028966a4bfb098ef095510` with drmTMB frozen at `453cff782`." Cite as historical
   evidence at that pin; do not relabel it to `da8b3f871`; the 500-seed campaign itself is not
   re-run by Arc 1 (that is a >30 min campaign, D-139, out of Arc 1's scope).
2. **The S7 source-subset verifier and its test**; `verify-source-commit.sh`,
   `test-source-commit-proof.sh` (already covered by item 1) plus
   `tests/testthat/test-071-four-fixture-summary.R`, `inst/extdata/env-skip-census.tsv` (only the two
   added rows), and `tools/source-tree-tests.txt` (only the one added line). Provenance: commits
   `fcf925e93`, `d63d98387`, `854d6381c`, `9e959fc8a`. This verifier is generic (proves a staged
   archive matches a declared Git commit) and needs no DRModels pin at all.
3. **The check-log/after-task provenance trail**; the 8 FOLD-NOW `check-log.d` entries and the 1
   FOLD-NOW `after-task` entry (`2026-09-12-071-source-subset-proof-reconciliation.md`) land under
   PR-D's own `docs/dev-log/check-log.d/` and `docs/dev-log/after-task/` with their original dates
   kept and a one-line "originally landed on itchyshin/drmTMB#1304" provenance note added to each,
   naming the specific commit from §3.
4. **The scoreboard reader pattern**; do not fold `tools/write-parity-scoreboard.R` wholesale (S1b
   is rewriting this generator). Instead, S1b/Grace should read commits `ade8aea08`, `217f5bcdf`,
   `9a0f66297` for the `sb_ordinary_laplace_summary()`/`sb_ordinary_laplace_source_drift()`
   fail-closed-staleness pattern and reimplement the equivalent join against whichever
   `capability_id` Arc 1's own S5 assigns the scalar-ordinary-RI row (not
   `ordinary_ri_scalar_laplace`, which is the Arc-2-only `marginal=` route).
5. **The new S5 ledger row itself is not copied from #1304.** S5 writes its own row (a *different*
   `capability_id* than #1304's two rows) for the existing, already-reachable ordinary mu-only `(1 |
   g)` Binomial/Poisson/NB2 route, citing the folded `reconciled-summary.tsv`/`s7-coverage-summary.tsv`
   at `b2caf00f` for the historical 500-seed numbers, plus a fresh one-line note from S3 (next item)
   for the current-pin integrator identity.
6. **What Arc 1's own model-identity sweep (S3) can re-measure at `da8b3f871`:** the *qualitative*
   integrator-identity fact only; that DRM.jl's default `:LA` route for a scalar ordinary `(1 | g)`
   Binomial/Poisson/NB2 mean random intercept reports GHQ-32 (not Laplace) in its own integrator
   label, on a small fixture, per A9's DIFFERENT-INTEGRATOR classification (same parameter names,
   count, and df; only the integrator differs). S3 does **not** re-run the 500-seed paired coverage
   campaign; that stays cited at `b2caf00f` as bounded historical evidence, per D-139. If S3's small
   fixture confirms the identity fact at `da8b3f871`, S5's ledger row may cite *both* the historical
   `b2caf00f` campaign numbers and a fresh `da8b3f871` integrator-identity receipt, each dated and
   pinned separately; never merged into one claim carrying the newer pin's label.
7. **Everything tagged OBSOLETE in §2 is left out of PR-D entirely**; it is not folded, not
   adapted, and not cited; `origin/main` already carries the current version of whatever it touched
   (the beta rename, the model-15 re-certification chain, the README/DESCRIPTION text).

## 5. Arc 2 list (verbatim items, provenance #1304)

- A public `marginal = "Laplace"` argument on `drmTMB()` for `engine = "julia"`, admitting exactly
  one scalar unlabelled `(1 | g)` mean term for Binomial/Poisson, or NB2 with `sigma ~ 1`.
  Provenance: itchyshin/drmTMB#1304, `R/drmTMB.R`, `R/julia-bridge.R` (`drm_julia_validate_marginal()`
  et al.), commits `a03e3ad96`, `46ec8a1ac`, `19d20ef1b`.
- A native (TMB) coupled NB2 `mu`/`sigma` labelled ordinary random-intercept pair: `bf(count ~ x + (1
  | p | id), sigma ~ z + (1 | p | id)), family = nbinom2()`, fitted through a non-centred transform
  `rho = 0.999999 * tanh(eta_cor_mu_sigma)`. Provenance: #1304, `src/drmTMB.cpp`, `R/drmTMB.R`,
  commit `6bb773332`, after-task `2026-09-09-071-ordinary-laplace-native-coupled-nb2.md`.
- A native "coupled Cholesky" profiling path for that same coupled-NB2 route (`R/profile.R`,
  `drm_profile_native_coupled_cholesky_confint()` and helpers). Provenance: #1304, commit `4ae31d5d5`.
- Two new `julia-capabilities.tsv` capability rows built on the argument above:
  `ordinary_ri_scalar_laplace` (`r_bridge_status = supported`, `claim_status = partial`) and
  `ordinary_nb2_coupled_laplace` (same statuses). Provenance: #1304, commit `0285af445`.
- Design/doc/vignette coverage of the above: `docs/design/01-formula-grammar.md`,
  `docs/design/04-random-effects.md`, `docs/design/143-phase-18-structured-workflow-registry.md`,
  `docs/design/261-reml-by-route.md`, `docs/design/capability-status.md`,
  `docs/dev-log/known-limitations.md`, `vignettes/formula-grammar.Rmd`, `man/drmTMB.Rd`. Provenance:
  #1304, commits `0285af445`, `0dfbbbb31`, `0581bc877`.
- Tests for the above: `tests/testthat/test-julia-bridge.R` (marginal= payload/validation),
  `tests/testthat/test-julia-bridge-coef-labels.R` (scalar-Laplace coef labels),
  `tests/testthat/test-nbinom2-location-scale.R` (native coupled NB2). Provenance: #1304, commits
  `a03e3ad96`, `4ab0486eb`.

## 6. Draft comment for #1304 (NOT posted; only after G3 sign-off and Shinichi's yes)

> Thanks for this. Arc 1 of the R-Julia parity programme read through this PR in detail while
> auditing the parity ledger for honesty. Two things came out of it.
>
> First, the finding that DRModels' default ordinary random-intercept route reports GHQ-32
> integration, not Laplace, for a scalar mu-only `(1 | g)` Binomial, Poisson, or NB2 random
> intercept is genuinely new and useful, and it describes a route the bridge can already reach. The
> four-fixture evidence for that, and the source-subset verifier that checks a staged campaign
> archive against its declared Git commit, are being folded into the successor draft PR (link added
> when it opens), with full provenance back to this PR's commits and the DRM.jl pin they were
> measured at.
>
> Second, the new `marginal = "Laplace"` argument, the coupled NB2 mean-scale random-intercept
> route, and the two new ledger rows they introduce are new public API and new coverage. Arc 1 is
> deliberately scoped to making the existing ledger honest before any coverage widens, so that part
> moves to a separate follow-up arc rather than landing here. It is listed in full, with this PR
> named as its source, so nothing is silently dropped.
>
> This PR itself is not being merged, edited, or closed as part of that work. Thank you for the
> careful, source-pinned evidence trail (the four-fixture contract, the paired-seed reconciliation,
> and the source-commit proof); it made folding the useful part straightforward.
