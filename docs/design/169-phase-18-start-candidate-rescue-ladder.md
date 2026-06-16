# Start-Candidate Rescue Ladder (Internal Harness)

## Purpose

This note records the first implementation slice for `drmTMB#570`, the Ayumi
beak `sigma`-phylogenetic native optimizer/start failure. The reader is the next
`drmTMB` engine contributor (Gauss/Ada) and the DRM.jl coordination team.

The goal of this slice is narrow: add an **internal, deterministic
start-candidate ladder** that fits a model from several starting-value
candidates, records every attempt, and selects the converged attempt with the
lowest objective. It does **not** change the default `drmTMB()` fit, and it does
**not** expose any public control. It is the "diagnostics before convenience"
step that `docs/design/35-optimizer-start-map-multistart.md` asks for before a
public multi-start interface.

## The real gap on the current base

The fit path already runs `drm_optimize_with_preset_retry()`
(`R/drmTMB.R`), which records `fit$optimizer_attempts` and selects an optimum.
But that ladder only escalates the `nlminb()` budget preset
(`default -> careful -> robust`) **when a call throws an error**, and every
preset reuses the *same* starting vector `obj$par`. A non-erroring
false-convergence at the starting basin is accepted immediately.

The beak failure is exactly that case. The full-data univariate beak culmen
model with scale-side phylogenetic variation returns convergence code 1 with the
reported SDs frozen at the cold-start heuristic (`sd_mu_phylo` near
`0.25 * sd(y)`, `sd_sigma_phylo` near `0.2`; see `gaussian_phylo_start()` and
`gaussian_sd_phylo_start()` in `R/drmTMB.R`) and the `sigma` slopes at zero. The
optimizer never leaves the start. Smaller pruned fits (`n = 100`, `n = 1000`)
move and sometimes converge, so the formula is not impossible; the blocker is a
start/basin problem on the stiff full-data surface.

The preset ladder cannot help here because it never varies the start and never
escalates on a bad-but-non-erroring fit. A start-candidate ladder can.

## What this slice adds

Two internal functions in `R/drmTMB.R` (no `@export`, no `NAMESPACE` change):

- `drm_log_sd_start_candidates(par, which, factors)` — a deterministic
  candidate generator. Given a named start vector `par`, it returns an ordered
  list of labelled candidates: the cold start first, then variants that scale the
  targeted log-SD entries (`log_sd_phylo`, `log_sd_sigma`, `log_sd_mu`) by fixed
  factors (SD x 0.25, x 0.5, x 2, x 4) on the log scale. Non-targeted entries are
  untouched. If no targeted name is present it returns the cold start only.

- `drm_run_start_ladder(obj, control, candidates, optimizer, gradient_fn, warn)`
  — the ladder mechanics. For each candidate it runs the optimizer from that
  candidate's start, captures status/convergence/objective/elapsed and the
  maximum absolute fixed-gradient at the returned parameters, and records one row
  per candidate. It then selects the winner and returns
  `list(opt, selected, attempts, selected_converged)`.

The ladder reuses the existing `nlminb` call shape but builds its **own** attempt
rows (`attempt`, `start_label`, `optimizer`, `optimizer_preset`, `status`,
`convergence`, `message`, `objective`, `max_gradient`, `elapsed_sec`, `eligible`,
`selected`). It does **not** modify `drm_optimizer_attempt_row()` or
`drm_optimize_with_preset_retry()`, so the existing preset-retry contract and its
snapshots are unchanged.

## Selection rule (honours doc 35)

Following `35-optimizer-start-map-multistart.md` (Future Multi-Start / Fallback):

1. An attempt is **eligible** if it returned without error, has
   `convergence == 0`, and a finite objective.
2. The winner is the eligible attempt with the **lowest objective**. Ties break
   on the earliest attempt index (deterministic, cold-start preferred).
3. If **no** attempt is eligible, the ladder returns the non-errored attempt with
   the lowest finite objective and sets `selected_converged = FALSE`, so the
   caller can report the failure state. Inference must stay tied to that selected
   optimum.

This is deterministic: no jitter and no random starts, so no seed contract is
needed in this slice.

## Scope boundary

- No change to the default `drmTMB()` fit path or to any public control. The
  reserved names `multi_start`, `multistart`, `warm_start`, `start_from`,
  `fallback_optimizer` (doc 35) remain reserved and unimplemented.
- `pdHess = FALSE` stays an inference warning, not an automatic point-fit
  discard. The ladder selects on objective and convergence; it does not gate on
  the Hessian.
- The harness returns the selected optimum and the attempts table; it does not
  itself build a fitted `drmTMB` object. Wiring the selected optimum into a fit
  (with TMB re-pinning per the doc-35 selected-optimum invariant) and surfacing
  divergent-optima notes through `check_drm()` are the next slices.

## Mapping to the #570 acceptance gates

- "Full-data beak fit no longer returns the starting-like basin" — this slice
  delivers the *mechanism* (start-candidate ladder + objective selection) and a
  small-fixture proof; the full 10,440-tip demonstration is a follow-up sim
  runner (issue slices 1 and 5), not a CRAN unit test.
- "Selected optimum, convergence, objective/logLik, warnings, and optimizer
  attempts are stored" — the ladder returns `opt`, `selected`, and the full
  `attempts` table with objective, convergence, and `max_gradient`.
- "`pdHess = FALSE` remains an inference warning, not an automatic discard" —
  honoured; the ladder does not discard on Hessian status.
- "Any rescue path has a test on a small fixture and a check-log/after-task
  entry before being advertised" — unit tests on a mock objective and on a small
  real Gaussian random-intercept model, plus a check-log and after-task entry.

## Update: this ladder does not rescue the Ayumi beak case

Subsequent investigation (the `log(sigma)` overflow guard in doc 170, and the q4
validation in doc 171) established that the catastrophic full-data beak
`sigma`-phylo failure is **not a start-basin problem**: at every starting point
the objective is pathological (`obj ~ 5e5`, `max|grad| ~ 1e6`) because the
scale-side phylogenetic field is numerically and structurally degenerate with one
observation per tip. A start-candidate ladder therefore **cannot rescue that case
by construction** — no start escapes it. The real answers are the `log(sigma)`
overflow guard (so the fit is finite and assessable) and the **Model A**
recommendation (phylogeny on the mean, fixed-effect scale).

This slice should therefore be read as a **general, internal start-candidate
diagnostic harness** — useful for genuine start-basin / multi-start situations and
as the selection-and-provenance plumbing for later warm-start work — not as the
fix for the beak. The selection rule above implements the selection-and-tie half
of the doc-35 multi-start/fallback contract; the contract's further requirement
that a non-converged best-attempt fallback be reported through `check_drm()` is
**deferred** (item 6) because the harness is not yet wired into the `drmTMB()` fit
path.

## Deferred (explicit follow-ups, tracked on `drmTMB#570`)

1. A `inst/sim` runner + artifact lane that exercises the ladder on the real
   beak `sigma`-phylo reducer at increasing tip counts (issue slice 1).
2. Warm-start candidates copied from the reduced no-phylo / location-only-phylo
   fits into the richer `sigma`-phylo model (issue slice 3).
3. `check_drm()` reporting when several starts converge to meaningfully different
   optima (doc 35 multi-start safeguard).
4. Profile/bootstrap retry policy, only after point-fit rescue is stable (issue
   slice 5).
5. A decision on whether and how to expose the ladder through `drm_control()`
   once rescue is demonstrated on the real surface.
6. Wire the ladder into the `drmTMB()` fit path and `check_drm()` fallback-state
   reporting (the doc-35 precondition for returning a non-converged best attempt)
   if a genuine start-basin case warrants it; until then the harness is
   standalone and does not return fits to users.
