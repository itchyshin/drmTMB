# After-task — Wave 1: runtime honesty guards

Date: 2026-06-16
Branch: `codex/honesty-guards` (off `origin/main` @ `6944451e`)

## Why this wave

A four-lane capability audit (ML, REML, optimizers, difficult-case controls) of
the estimation stack found one issue independently flagged by three of the four
auditors: **several difficult-case rules are written into docs, vignettes, and
`check_drm()` messages but are not enforced in the code path a naive user hits.**
Three of those prose-only rules let a user obtain a silently wrong answer:

1. A non-converged fit was returned looking fine.
2. `AIC()`/`BIC()` on a REML or penalized (MAP) fit returned a meaningless number.
3. A Wald interval at a variance-component / correlation boundary was presented
   as an ordinary interval.

Wave 1 wires each rule into the runtime. Guiding principle (the project's own
honesty gate): **a boundary or weak fit is a warning, never an auto-discard** —
surface it, do not hide it and do not silently drop the estimate.

## What changed

### Guard 1 — fit-time non-convergence warning
- `drm_convergence_label(convergence, message)` interprets the `nlminb` code
  (NULL when converged, else surfaces the PORT message such as "false
  convergence (8)").
- `drm_warn_if_not_converged(opt)` warns at fit time on a non-zero code,
  condition class `drmTMB_convergence_warning`, pointing to `check_drm()` and the
  `robust` optimizer preset.
- `print()` annotates a non-zero code with "(not converged; see check_drm())".
- The warning is classed so callers that do their own convergence bookkeeping can
  muffle just this signal. `phase18_run_replicate()` (the simulation harness)
  filters it, because the summary already tracks per-fit convergence/pdHess;
  without this the harness double-counted the warning as a ledger failure.

### Guard 2 — AIC()/BIC() guard for REML and MAP fits
- `AIC.drmTMB` / `BIC.drmTMB` compute `-2*logLik + k*df` from the fit's stored
  `logLik`/`df` (value unchanged for an ML fit) and route through
  `drm_warn_information_criterion()`, which warns with distinct classes
  (`drmTMB_ic_reml_warning`, `drmTMB_ic_map_warning`) when any compared fit is
  REML (comparable only across identical fixed effects) or MAP (unpenalized
  logLik over a non-effective df). Previously these dispatched to
  `stats::AIC.default`, which reads the logLik value and ignores the estimator.

### Guard 3 — boundary-aware confint(method = "wald")
- `wald_boundary_targets()` flags, by `target_class`, variance-component /
  structured SDs within `sd_boundary` of zero and any correlation within
  `rho_boundary` of `+/-1`; the residual / distributional scale is regular and is
  not flagged.
- `drm_wald_confint()` sets such rows' `conf.status` to `"wald_at_boundary"`,
  keeps the interval (warning, not auto-discard), and warns (class
  `drmTMB_wald_boundary_warning`) pointing to `method = "profile"`.
- Thresholds are exposed as `confint(..., sd_boundary = 1e-4, rho_boundary =
  0.98)`, matching the `check_drm()` defaults (generalization via controls).

### Doc fix
- `docs/design/174` recorded the `log(sigma)` clamp knob (#586) as "planned"; it
  shipped one commit after the doc. Updated to "shipped"; the
  warn-when-active-at-optimum measure remains genuinely planned.

## TDD and fallout

Each guard was strict red -> green with a pure-helper unit layer (deterministic)
plus a real-fit integration layer:
- Guard 1 fallout: 4 simulation-lane FAILs, root-caused to the harness counting
  the new warning as a ledger failure; fixed centrally by classing the warning.
- Guard 2 fallout: none (all four existing AIC/BIC-calling test files clean; the
  comparators REML cells use `logLik`, not `AIC`).
- Guard 3 fallout: none. The boundary flag is opt-in via the estimate magnitude,
  and no existing test fit a target inside the default boundary bands while
  asserting `conf.status == "wald"`.

A class-scoped `allow_nonconvergence()` test helper muffles only the convergence
warning in tests that deliberately fit non-converging / marginal fixtures.

Lesson reused: do not assert optimizer warning *text* or a specific non-zero
convergence code in tests (BLAS-path dependent). The warning paths are tested
with synthetic `opt` / target rows; the boundary fixtures force the branch via
the configurable threshold rather than relying on a collapsed-SD draw.

## Verification

- Guard test files: `test-fit-convergence-warning.R` (13), `test-information-criterion-guard.R` (16), `test-wald-boundary-guard.R` (8) — all pass.
- Full suite after each guard: Guard 1 FAIL=0 / PASS=11156; Guard 2 targeted-clean; Guard 3 FAIL=0 / ERROR=0 / PASS=11180.

## Feeds the later waves

Guard 1 surfaced ~5 marginal test fixtures (small-n Tweedie, beta-binomial,
reference-grid families) whose fits emit a correct convergence warning. These are
honest signal, not regressions, and are concrete inputs for Wave 2 (ML
robustness: better starts / clamp-all-families) and Wave 3 (optimizer
escalation).
