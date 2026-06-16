# After Task: Start-Candidate Rescue Ladder (drmTMB#570, slice 1)

## Goal

Begin `drmTMB#570` (the Ayumi beak `sigma`-phylogenetic native optimizer/start
failure) by adding the core mechanism it needs: an internal, deterministic
start-candidate ladder that fits one objective from several starting candidates,
records every attempt, and selects the converged attempt with the lowest
objective. This slice delivers the mechanism and small-fixture proof only. It
makes no change to the default `drmTMB()` fit and exposes no public control,
following the "harness and tests, no API change" decision agreed for this slice.

## Why this is the right mechanism

The fit path already runs `drm_optimize_with_preset_retry()`, which records
`fit$optimizer_attempts` and selects an optimum. But that ladder only escalates
the `nlminb()` budget preset (`default -> careful -> robust`) **when a call
throws an error**, and every preset reuses the same starting vector `obj$par`. A
non-erroring false-convergence at the starting basin is accepted immediately.

The beak failure is exactly that case: the full-data univariate beak culmen model
with scale-side phylogenetic variation returns convergence code 1 with the
reported SDs frozen at the cold-start heuristic (`sd_mu_phylo` near
`0.25 * sd(y)`, `sd_sigma_phylo` near `0.2`) and the `sigma` slopes at zero. The
preset ladder cannot help because it never varies the start and never escalates
on a bad-but-non-erroring fit. A start-candidate ladder can.

## Implemented

Three internal functions in `R/drmTMB.R` (no `@export`, no `NAMESPACE` change):

- `drm_log_sd_start_candidates(par, which, factors)` — deterministic candidate
  generator. Returns the cold start first, then variants that scale the targeted
  log-SD entries (`log_sd_phylo`, `log_sd_sigma`, `log_sd_mu`) by fixed factors
  on the log scale. No-op (cold start only) when no targeted name is present.
- `drm_run_start_ladder(obj, control, candidates, optimizer, gradient_fn, warn)`
  — the ladder mechanics. Runs the optimizer from each candidate, records one row
  per candidate (`attempt`, `start_label`, `optimizer`, `optimizer_preset`,
  `status`, `convergence`, `message`, `objective`, `max_gradient`, `elapsed_sec`,
  `eligible`, `selected`), selects the winner, and returns
  `list(opt, selected, attempts, selected_converged)`.
- `drm_attempt_max_gradient(gradient_fn, par)` — guarded maximum absolute
  fixed-gradient at a returned optimum, recorded per attempt.

The ladder builds its own attempt rows; it does not modify
`drm_optimizer_attempt_row()` or `drm_optimize_with_preset_retry()`, so the
existing preset-retry contract and its snapshots are unchanged.

## Mathematical Contract

No model likelihood or parameterization changed. The public terms `sigma`,
`rho12`, `sd(group)`, `phylo()`, `spatial()`, `mu`, and `nu` are untouched.

The selection rule follows `docs/design/35-optimizer-start-map-multistart.md`
(Future Multi-Start / Fallback):

1. an attempt is eligible if it returned without error, has `convergence == 0`,
   and a finite objective;
2. the winner is the eligible attempt with the lowest objective, ties broken on
   the earliest attempt index (deterministic; the cold start is preferred);
3. if no attempt is eligible, the ladder returns the non-errored attempt with the
   lowest finite objective, sets `selected_converged = FALSE`, and warns, so the
   caller can report the failure state.

This is deterministic: no jitter and no random starts, so no seed contract is
needed. `pdHess = FALSE` stays an inference warning; the ladder does not gate on
the Hessian and never discards a point fit on Hessian status.

## Files Changed

- `R/drmTMB.R` (+179): the three internal functions above.
- `tests/testthat/test-optimizer-contract.R` (+241): seven tests.
- `docs/design/169-phase-18-start-candidate-rescue-ladder.md`: slice design.
- `docs/dev-log/check-log.md`: this slice's checks.
- `docs/dev-log/after-task/2026-06-15-start-candidate-rescue-ladder.md`: this
  report.

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'optimizer-contract', reporter = 'summary')"
Rscript -e "devtools::document()"
Rscript -e "devtools::test(reporter = 'summary')"
git diff --check
```

Results:

- `optimizer-contract`: 136 passed, 0 failed (102 prior plus the 7 new
  start-ladder tests; the existing snapshot tests run under `devtools::test`).
- `devtools::document()`: regenerated only the pre-existing `man/rho_latent.Rd`
  drift, which was reverted; the new internal functions add no `Rd` or
  `NAMESPACE` entries.
- Full `devtools::test()`: 0 testthat failures across all test files. One
  pre-existing Julia-bridge stacktrace (`fit_mixed_family` `Xsigma1`/`Xsigma2`
  keyword mismatch against the local `DRM.jl` checkout) printed but did not fail
  its test; it is unrelated to this native-TMB slice and does not run on CI.
- `git diff --check`: no whitespace errors.

## Tests Of The Tests

The ladder mechanics are tested with the same mock-objective / mock-optimizer
pattern the existing `drm_optimize_with_preset_retry` tests use, so the selection
logic is exercised without a TMB build:

- records every candidate and selects the lowest converged objective;
- prefers a converged attempt over a lower but non-converged objective;
- returns the best attempt and flags `selected_converged = FALSE` (with a
  warning) when none converge;
- records an errored candidate without selecting it;
- the candidate generator scales only the targeted log-SD entries, keeps the cold
  start first, and is a no-op when no target is present;
- a small real Gaussian random-intercept fit confirms the ladder integrates with
  a live `obj$fn` / `obj$gr` and never selects a worse objective than the cold
  start.

Each test was written first and watched fail with
`object 'drm_run_start_ladder' not found` /
`object 'drm_log_sd_start_candidates' not found` before the functions existed.

## What Did Not Go Smoothly

- `devtools::document()` surfaced pre-existing drift in `man/rho_latent.Rd`
  unrelated to #570. It was reverted to keep this slice surgical and is reported
  separately; it is a candidate for a tiny standalone regen commit.

## Team Perspective

Ada orchestrated. Gauss owns the optimizer/start mechanism. Fisher and Noether
hold the inference boundary: the ladder selects on objective and convergence and
records `max_gradient`, but it does not advertise a rescued fit as
inference-ready, and `pdHess = FALSE` stays a warning. Rose's scope-honesty rule
is encoded in the deferred list: the real 10k beak rescue is a follow-up sim
runner, not a CRAN claim. No subagents are running.

## Consistency Audit

- Stable public terms unchanged: `sigma`, `rho12`, `sd(group)`, `phylo()`,
  `spatial()`, `mu`, `nu`. No formula-grammar or likelihood change, so
  `docs/design/01-formula-grammar.md` and `docs/design/03-likelihoods.md` need no
  update.
- Reserved control names (`multi_start`, `warm_start`, `start_from`,
  `fallback_optimizer`) remain reserved and unimplemented; the reserved-name test
  still passes.
- The existing `drm_optimize_with_preset_retry()` contract and its snapshots are
  untouched; the ladder builds its own attempt rows.
- `pdHess = FALSE` handling matches the project rule: a Wald-inference warning,
  never an automatic point-fit discard.

## Documentation And pkgdown

No user-facing surface changed. The new functions are internal (no `@export`), so
there are no reference pages, vignette, or `_pkgdown.yml` updates. Design doc 169
and this report document the slice.

## GitHub Issue Maintenance

Draft PR #574 was opened, stacked on `codex/ayumi-beak-start-rescue` (#572), so
the diff shows only the ladder; GitHub will retarget it to `main` when #572
merges, at which point `R-CMD-check` runs (the workflow only triggers for PRs
based on `main`/`master`). A comment summarizing this slice and linking #574 is
drafted for `drmTMB#570`; posting is held pending the maintainer's go-ahead,
because the unattended-action guard declined to publish a public issue comment.
The pre-existing `man/rho_latent.Rd` drift and the Julia-bridge
`Xsigma1`/`Xsigma2` keyword mismatch are noted as separate, out-of-scope items.

## Known Limitations

- The harness returns the selected optimum and attempts table; it does not yet
  build a fitted `drmTMB` object (which would require TMB re-pinning per the
  doc-35 selected-optimum invariant).
- The small-fixture tests prove the mechanism, not the real 10,440-tip beak
  rescue. That demonstration is a follow-up `inst/sim` runner.
- No `check_drm()` reporting yet for divergent converged optima across starts.

## Next Actions (tracked on drmTMB#570)

1. Add an `inst/sim` runner and artifact lane that exercises the ladder on the
   real beak `sigma`-phylo reducer at increasing tip counts (issue slice 1).
2. Add warm-start candidates copied from the reduced no-phylo / location-only
   fits into the richer `sigma`-phylo model (issue slice 3).
3. Surface divergent-optima notes through `check_drm()` (doc 35 safeguard).
4. Add a profile/bootstrap retry policy only after point-fit rescue is stable
   (issue slice 5).
5. Decide whether and how to expose the ladder through `drm_control()` once
   rescue is demonstrated on the real surface.
