# After-task: q-series coverage-runner hardening + bank q2-slope runner

Meta: 2026-06-27 · Claude (ultracode) session · branch
`claude/coverage-runner-hardening-q2-bank` · q-series structured-RE completion lane.

## 1. Goal

Advance the apply-list from the 2026-06-27 handover: fix the degenerate MCSE
gate in both new coverage runners, fix the SLURM copy-back defect in all three
coverage sbatch files, apply the blind-safe q4-location fixes, and bank the
q2-slope coverage runner as deploy-ready scaffolding (sigma-slope is already
deploy-ready). No cluster job is submitted; no coverage evidence is produced;
no `coverage_status` moves off `planned`.

## 2. Implemented

- **Degenerate MCSE gate fix (both runners).** `mcse_threshold_met` previously
  read `if (!is.na(wald_mcse)) wald_mcse <= 0.01 else NA`. A saturated-coverage
  Wald MCSE is `sqrt(p(1-p)/n) = 0` exactly at `p in {0,1}`, so the old gate
  falsely fired `TRUE` at the n=6 smoke (e.g. q4 pilot: `n_wald_finite=4`,
  `wald_coverage=1`, `wald_mcse=0`, `mcse_threshold_met=TRUE`). New gate, applied
  **byte-identically** to `tools/run-structured-re-q2-slope-coverage-grid.R:964`
  and `tools/run-structured-re-q4-location-coverage-grid.R:835`:
  `if (!is.na(wald_mcse) && n_wald_fin >= 475L && wald_mcse > 0) wald_mcse <= 0.01 else NA`.
- **SLURM copy-back fix (all 3 sbatch).** `sigma-/q2-/q4-` grid sbatch all ran
  `Rscript` under `set -euo pipefail`, so a non-zero Rscript exit aborted the
  script *before* the `EXIT_CODE=$?` capture and the `cp ... $RESULTS_DIR` step,
  stranding per-rep results on purged `$SCRATCH`. Now the `Rscript` call is
  wrapped `set +e` / `EXIT_CODE=$?` / `set -eo pipefail`; the copy-back (with its
  existing `|| true`) and `exit $EXIT_CODE` are reached unconditionally.
- **q4-location blind-safe fixes (runner stays HELD).**
  - D2: added `wald_finite_frac` and `profile_finite_frac` derived columns to
    `make_summary()` so boundary-censoring of the coverage denominator is visible
    as a single readable fraction (coverage is computed on the finite-interval
    subset only).
  - D4: `sd_label_in_sdpars()` now builds the native biv_gaussian key with the
    endpoint prefix (`mu1:provider(coef | p | group)`); the prefix-less key never
    matched `fit$sdpars$mu`, leaving `estimate_sd`/`mean_est_sd`/`bias_mean_est`
    all-NA. Fix derived from source (`phylo_mu_sd_labels` ->
    `format_structured_label`); flagged in-code as **needs live confirmation** of
    `names(fit$sdpars$mu)` before estimate_sd/bias are trusted.

## 3a. Decisions and Rejected Alternatives

- **`else NA` over `else FALSE`** for the gate. The two reviewers diverged
  (Fisher: NA fine; q4 investigator wrote FALSE). `mcse_threshold_met` is a
  write-only reporting column (verified: never read for control flow in either
  runner), and the adjacent `coverage_evaluable = "pending_mcse_check"` /
  `claim_boundary` already say "no coverage claims until MCSE<=0.01". NA reads as
  "not assessable"; FALSE positively asserts "gate evaluated and not met" at a
  degenerate denominator, a slight over-claim. The non-negotiable was that q2 and
  q4 share the **identical** expression (handover step 2).
- **`set -eo pipefail` restore over bare `set -e`** (Grace). The files open with
  `set -euo pipefail`; bare `set -e` would silently drop `pipefail`. Latent-only
  today (no pipes after the restore point), fixed anyway for fidelity. `|| true`
  on the `cp` is **kept** (still needed: if R dies before writing any `.tsv` the
  glob does not expand, `cp` errors, and `set -e` would abort before
  `exit $EXIT_CODE`, discarding the true R exit code).
- **q4-location kept HELD, not banked.** Its blind-safe fixes (D1/D2/D4) landed,
  but D4 needs one live fit to confirm the sdpars key and D3 needs a regenerated
  pilot artifact — neither possible in this no-live-R Claude session. Banking it
  as deploy-ready would over-claim.
- **No heavy q2 sidecar machinery.** The mission-control validator does not
  reference the runner `.R`/`.sbatch` or their pilot/smoke summaries (source-
  verified by Rose), so the sigma-style dispatch-review/runner-contract sidecar
  tier is **not required** to bank the q2 runner honestly. That tier remains an
  available follow-up if the maintainer wants full sigma-parity tracking.
- **No profile-MCSE gate added.** Fisher recommends `mcse_threshold_met` also
  gate on profile MCSE; kept Wald-only to stay faithful to the apply-list and the
  reviewed fix. Recorded as a known asymmetry (Residuals).

## 4. Files Touched

- `tools/run-structured-re-q2-slope-coverage-grid.R` (MCSE gate)
- `tools/run-structured-re-q4-location-coverage-grid.R` (MCSE gate, D2 finite
  fractions, D4 sdpars key)
- `tools/slurm/sigma-slope-coverage-grid.sbatch` (copy-back)
- `tools/slurm/q2-slope-coverage-grid.sbatch` (copy-back)
- `tools/slurm/q4-location-coverage-grid.sbatch` (copy-back)
- `docs/dev-log/after-task/2026-06-27-coverage-runner-hardening-and-q2-slope-bank.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- **No live R fits / `devtools` / `testthat` were run this session** (unavailable
  in this app R library; `~/.Rprofile` segfaults R 4.6). Evidence below is
  source-reasoning + parse/syntax checks + an adversarial subagent review panel.
- `Rscript --no-init-file -e 'parse(...)'` on both runners: parse OK.
- `bash -n` on all three sbatch: OK.
- `python3 tools/validate-mission-control.py`: `mission_control_ok`, 98 q-series
  cells (unchanged — no banked sidecar touched).
- `git diff --check`: whitespace clean.
- Adversarial review panel (ultracode workflow, 4 agents): Fisher
  (`inference_reviewer`) certified the MCSE fix correct and the q2 runner
  SOUND_WITH_CAVEATS (DGP<->model alignment numerically confirmed, max abs diff
  0.004 over 200k draws; resumable; denominator honest); Grace
  (`reproducibility_engineer`) certified the copy-back fix correct across all 3
  files; an independent investigator confirmed all 4 q4 defects and the
  blind-fixable subset; Rose (`systems_auditor`) returned GO to bank q2 with
  `moves_disallowed_status = false`.

## 6. Tests of the Tests

- The MCSE fix is pure summary arithmetic: at `p in {0,1}` the binomial MCSE is
  exactly 0, so `wald_mcse > 0` is the precise non-degeneracy predicate, and
  `n_wald_fin >= 475L` is the SR475 denominator floor from the banked pre-grid
  dry-run (`replicates_for_mcse_threshold = 475`).
- The copy-back defect is reachable: each rep is flushed via `append_tsv` inside
  the main loop, and the runner has an explicit `quit(status = 1L)` plus
  OOM/timeout/pkg-load fatal paths outside the per-rep `tryCatch`, so partial
  `.tsv` on `$SCRATCH` at a fatal exit is a real scenario the copy-back must
  survive.
- D4's key was derived through the engine's own label path
  (`phylo_mu_sd_labels` -> `structured_mu_coef_labels` -> `format_structured_label`),
  not guessed; it is marked for live confirmation rather than asserted.

## 7a. Issue Ledger

- Fixed: degenerate MCSE false-pass (both runners).
- Fixed: SLURM copy-back stranding on `set -e` (all 3 sbatch).
- Fixed (q4, held): D2 boundary-censoring not surfaced; D4 estimate_sd all-NA.
- Surfaced for maintainer (not a fix defect): **the SR475 floor and the 0.01
  MCSE bar are in tension** (Fisher). At n=475 the binomial MCSE is 0.01 only at
  p≈0.95; the worst case (p=0.5) is ~0.0229, and 0.01 is reached around n≈2500.
  SR475 sizes the *coverage estimate*, not a passable 0.01-MCSE *gate* — do not
  read the runbook as implying SR475 clears the gate at realistic coverage.
- Deferred to Codex/maintainer (live R): D3 — regenerate the q4 pilot artifact
  (it carries superseded `fit_error` "subscript out of bounds" rows from an
  earlier buggy state; `make_summary` filters to `fit_ok` so coverage is
  unaffected, but `n_fit_error` over-counts). D4 — confirm `names(fit$sdpars$mu)`
  on one phylo + one non-phylo fit.

## 8. Consistency Audit

- q2 L964 and q4 L835 carry the **identical** gate expression.
- The committed q4 smoke-summary
  (`docs/dev-log/simulation-artifacts/2026-06-27-q4-location-coverage-pilot/`)
  still shows `mcse_threshold_met=TRUE` on its 16 degenerate n=6 rows: that file
  **predates this fix** and is a known degenerate-gate artifact pending live
  regeneration (Rose). It is NOT hand-edited; the validator does not read it, so
  green is unaffected. The q2 pilot summaries are NOT stale (their reps were
  non-degenerate, already `FALSE`).
- Honesty note carried into the check-log: the sigma-slope sbatch banked in #677
  was NOT actually copy-back-safe when first banked; this slice closes that.
- No banked dashboard sidecar, validator, or existing test was modified.

## 9. What Did Not Go Smoothly

- A first run of the verification workflow was killed mid-flight by a session
  interruption before the agents submitted structured output; re-launched clean
  rather than salvaging partial transcripts.
- No live R toolchain means D3 (artifact regen) and D4 (key confirmation) cannot
  be closed here; they are honestly handed to Codex/maintainer.

## 10. Known Residuals

- **q4-location stays HELD**: not deploy-ready until D4 is live-confirmed and the
  D3 pilot artifact is regenerated. Do not gate q4 to SR475.
- **MCSE-bar tension** (Fisher): SR475 does not buy a passable 0.01 gate at
  realistic coverage — a maintainer policy decision (more reps, or a different
  bar) when results are analyzed.
- **profile_mcse is reported but not gated**; the `mcse_threshold_met` column is
  Wald-only. Any future profile-MCSE pass must carry the same `n>=475` +
  non-degenerate guard.
- **No coverage evidence exists**; all `coverage_status` stay `planned`. Coverage
  execution remains externally gated to the maintainer's cluster run.

## 11. Team Learning

A reporting column that looks like a gate can silently certify nothing. The
degenerate-MCSE bug passed every smoke run because saturated coverage drives the
binomial MCSE to exactly 0, which trivially clears any `<= threshold` test — the
fix is to require both a real denominator floor and a strictly positive estimate.
The deeper lesson (Fisher): an MCSE *threshold* and a fixed *replicate count* are
not interchangeable knobs — at SR475 the 0.01 bar is only reachable near nominal
coverage, so the replicate budget and the gate threshold must be reasoned about
together before any coverage wording.
