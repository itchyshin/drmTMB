# Big 4 Finish Plan After The Post-#633 Ledger

This plan sequences the next four large work blocks after the post-#633
decision ledger and the Student-t profile-failure decision audit. Its purpose
is to keep capability work moving one defended slice at a time without
collapsing native R/TMB evidence, direct Julia evidence, and Julia-via-R bridge
evidence into one claim.

The active finish-board row remains `drmTMB#59` numerical-guard sensitivity.
The Student-t interval branch is now decided for the current evidence: all
current Student-t profile targets are `blocked_by_method`, and bootstrap
targets remain diagnostic or larger-grid candidates. The next work should
therefore move to scale and covariance sensitivity before reopening broader
family, bridge, or release stories.

## Evidence Rules For Every Block

Each block must leave a small, recoverable artifact trail:

- a reproducible runner under `docs/dev-log/simulation-artifacts/`;
- CSV tables for fitted values, warnings, `check_drm()` rows, failures, and
  run-level metadata;
- a design-doc update with the exact scope and boundary;
- a `docs/dev-log/check-log.md` entry with commands and results;
- an after-task report following `docs/design/10-after-task-protocol.md`;
- dashboard JSON updates when the public mission-control state changes;
- a `drmTMB#59` breadcrumb only after the local validation pass is complete.

Every numerical intervention must travel as data. If starts, clamps, floors,
optimizer presets, retries, profile budgets, bootstrap refits, or fallback
optimizers matter, the artifact must expose them as status, warning, or
configuration fields. A guarded fit can be evidence that a warning is visible;
it cannot become evidence that a model recovered accurately unless the
simulation explicitly measures recovery.

The evidence lanes are separate:

- Native R/TMB evidence supports native `drmTMB` rows.
- Direct Julia evidence supports `DRM.jl` rows and must come from a DRM.jl
  checkout or CI run.
- Julia-via-R evidence needs its own registry row, representative rejection or
  parity test, point-estimate evidence, and CI/status evidence before it can
  support a user-facing `engine = "julia"` bridge claim.

Do not use these blocks to imply release readiness, CRAN readiness, selectable
Julia `engine_control`, q2/q4/q8 promotion beyond the audited slice, power,
coverage, recovery accuracy, random effects in `rho12`, structured correlation
readiness, true `nu <= 2`, or non-Gaussian REML/AI-REML.

## Block 1: Bivariate Scale Clamp Sensitivity

**Purpose.** Deepen the fixed-effect bivariate Gaussian `sigma1`/`sigma2`
clamp diagnostic. The existing 120-fit artifact shows that ordinary cells match
the unclamped reference, high-scale cells trigger default clamp warnings, and a
wide band matches the unclamped reference. The next block adds lower-tail,
near-band, and residual-correlation stress while staying fixed-effect and
native R/TMB only.

**Current status.** The larger native R/TMB diagnostic is now banked at
`docs/dev-log/simulation-artifacts/2026-06-19-biv-scale-clamp-larger-diagnostic/`.
It ran the planned 10 cells x 50 replicates x 3 controls = 1500 fits. It
supports upper-side guard visibility and ordinary/upper-in-band non-interference
for this fixed-effect route, while keeping lower-tail behavior on diagnostic
hold because fixed-gradient warnings, automatic optimizer preset escalation,
and one wide-band lower-tail mismatch remain visible.

**Starting evidence.**

- Source artifact:
  `docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/`.
- Existing runner:
  `docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/run-pilot.R`.
- Existing result: 120/120 requested fits converged with `pdHess = TRUE`; 30
  default `logsigma_clamp_active` warnings occurred in high-scale cells; wide
  and unclamped fits matched to about `1e-11` in log likelihood; default
  high-scale log-likelihood shifts reached `383.851973`.

**Larger diagnostic artifact.**

- Path:
  `docs/dev-log/simulation-artifacts/2026-06-19-biv-scale-clamp-larger-diagnostic/`.
- Model:
  `bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z1, sigma2 = ~ z2, rho12 = ~ 1)`
  with `family = biv_gaussian()`.
- Data size: `n = 180`.
- Replicates: `n_rep = 50`.
- Controls: `logsigma_clamp = NULL`, default `drm_control()`, and wide
  `logsigma_clamp = c(-25, 25)`.
- Total requested fits: 10 cells x 50 replicates x 3 controls = 1500 fits.
- No retries, no profile intervals, no bootstrap intervals, no fallback
  optimizer, no multistart; record `optimizer_preset = "default"`,
  `multi_start = 1`, `fallback_optimizer = NA`, `retry_count = 0`,
  `profile_requested = FALSE`, and `bootstrap_requested = FALSE`.

**Cells.**

| Cell | Purpose |
|---|---|
| ordinary scale, `rho12 = 0` | Check inactive clamp under independent residual axes. |
| ordinary scale, `rho12 = 0.8` | Check inactive clamp with strong positive residual correlation. |
| ordinary scale, `rho12 = -0.8` | Check inactive clamp with strong negative residual correlation. |
| both scales near upper in-band | Check that high but in-band scales do not report clamp activation. |
| both scales near lower in-band | Check lower-side in-band behavior. |
| `sigma1` above default band | Recheck single-axis upper activation with more depth. |
| `sigma2` above default band | Recheck the other upper axis with more depth. |
| both scales above default band | Recheck two-axis upper activation. |
| `sigma1` below default band | Add lower-tail clamp sensitivity. |
| `sigma2` below default band | Add the other lower-tail sensitivity. |

**Required outputs.**

Keep the current bivariate scale schema and add explicit intervention fields:

- `biv-scale-clamp-conditions.csv`;
- `biv-scale-clamp-configs.csv`;
- `biv-scale-clamp-fit-diagnostics.csv`;
- `biv-scale-clamp-comparisons.csv`;
- `biv-scale-clamp-aggregate-summary.csv`;
- `biv-scale-clamp-condition-summary.csv`;
- `biv-scale-clamp-check-drm.csv`;
- `biv-scale-clamp-failures.csv`;
- `biv-scale-clamp-run-summary.csv`;
- `session-info.txt`.

The fitted table should retain raw and reported `log_sigma1`/`log_sigma2`,
upper and lower clamp deltas, `logsigma_clamp_active` status, convergence code
and message, `pdHess`, `max_abs_gradient`, `fixed_gradient_component`,
`rho12_boundary_status`, warnings, elapsed time, and all intervention flags.
Because `check_drm()` reports upper clamp activation directly, lower-tail
activation must also be detected from raw-versus-reported log-scale deltas.

**Validation.**

Run:

```sh
air format docs/dev-log/simulation-artifacts/2026-06-19-biv-scale-clamp-larger-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-biv-scale-clamp-larger-diagnostic/run-pilot.R
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
```

If source code or tests change, also run `devtools::test()` and
`devtools::check(error_on = "never")`. A native-only artifact does not require
direct Julia or Julia-via-R tests, but the docs must say that explicitly.

**Decision after the block.**

The row has moved from first diagnostic to larger diagnostic evidence, but not
to promotion. Ordinary residual-correlation cells and the near-upper in-band
cell remain useful guard non-interference evidence. Upper out-of-band default
rows visibly surface the guard. Lower in-band and lower out-of-band rows retain
fixed-gradient warnings, automatic optimizer escalation, and lower-side
raw-versus-reported scale deltas, so lower-tail behavior needs a follow-up
method audit before any recovery, interval, q2/q4/q8, Julia bridge, release, or
CRAN claim.

## Block 2: Ordinary q2 And Same-Response Covariance Hardening

**Purpose.** Separate ordinary q2 covariance behavior from structured q2 and
q4/q8 ambitions. The existing q2 diagnostics show that fitted-boundary warnings
are visible, but one structured high-correlation cell and several boundary rows
still need stronger interpretation before users see any broader covariance
claim.

**Current status.** The larger native R/TMB ordinary q2 diagnostic is now
banked at
`docs/dev-log/simulation-artifacts/2026-06-19-q2-ordinary-hardening-diagnostic/`.
It ran 3 routes x 7 correlation cells x 100 replicates = 2100 complete-data
primary fits, plus three separated missing-response smoke rows. All primary
fits returned, converged, and had `pdHess = TRUE`, but the artifact retains
many fixed-gradient warnings, `check_drm()` warning/error statuses, and
route-specific fitted-minus-true correlation errors. It supports ordinary q2
fitted-boundary visibility and route-specific recovery screening only. It does
not promote ordinary q2 inference, structured q2, q4/q8 covariance, intervals,
power, direct Julia, Julia-via-R, release, or CRAN claims.

**Starting evidence.**

- `docs/dev-log/simulation-artifacts/2026-06-18-q2-covariance-boundary-guard/`.
- `docs/dev-log/simulation-artifacts/2026-06-18-q2-correlation-grid-diagnostic/`.
- `docs/dev-log/simulation-artifacts/2026-06-18-structured-q2-boundary-diagnostic/`.

**Scope.**

Start with ordinary q2 only:

- univariate same-response `mu`/`sigma` covariance;
- bivariate `mu1`/`mu2` covariance;
- bivariate `sigma1`/`sigma2` covariance.

Do not include structured `spatial()`, `animal()`, or `relmat()` rows in this
block. Do not open q4 or q8 covariance in this block. Do not add random
effects in residual `rho12`.

**Completed design.**

- Use seven true correlations: `-0.95`, `-0.80`, `0`, `0.40`, `0.80`,
  `0.95`, and `0.98`.
- Include negative, ordinary, positive, and near-boundary generating cells.
- Retain route-specific warnings, fitted boundary distances, convergence,
  `pdHess`, gradient summaries, fitted-minus-true correlation errors,
  optimizer-attempt metadata, explicit evidence-lane fields, and
  `check_drm()` rows.
- Record whether starts were clamped or adjusted, even if the only start
  intervention is the package default.
- Keep profile and bootstrap intervals out of the q2 hardening run.
- Keep missing-response smoke rows separate from complete-data primary q2
  summaries.

**Subagent review.**

- Curie designs the simulation denominators and malformed/edge cells.
- Boole reviews formula syntax and route labels.
- Fisher reviews whether recovery wording is supported.
- Grace reviews platform and CI risk before any issue breadcrumb.
- Ada integrates the docs, dashboard, and issue trail.

**Validation.**

Run the q2 artifact runner, `git diff --check`, dashboard JSON validation,
`tools/validate-mission-control.py`, and `pkgdown::check_pkgdown()` if any docs
change. If code or tests change, run `devtools::test()` and
`devtools::check(error_on = "never")`.

**Decision after the block.**

The block banks a route-specific ordinary-q2 larger diagnostic, not a
promotion. `univ_mu_sigma` and `biv_mu` have useful fitted-boundary visibility
evidence, while `biv_sigma` stays diagnostic-hold for inference wording because
gradient status and fitted-minus-true correlation errors remain rough.
Structured q2, q4, q8, interval coverage, power, direct Julia, Julia-via-R,
release, and CRAN language remain planned unless separate artifacts support
them.

## Block 3: q8 Endpoint And Staged-Start Hardening

**Purpose.** Turn the q8 staged diagnostic route into a clearer endpoint-status
and failure-mode artifact before any q8 recovery, coverage, power, or public
workflow claim is considered.

**Starting evidence.**

Use the q8 staged diagnostic artifact already banked after PR #602 and the
current finish-matrix q8 boundary. That artifact is diagnostic-only: it shows
how cold and staged starts behave, not that q8 intervals or recovery are ready.

**Scope.**

- Keep this native R/TMB unless a separate bridge issue is opened.
- Keep endpoint inventory explicit: which SD/correlation endpoints are asked,
  estimated, skipped, failed, or warned.
- Keep cold and staged fits separated.
- Record starts, staged values, convergence code/message, `pdHess`, gradients,
  fitted-boundary warnings, and endpoint availability.
- Do not add profile/bootstrap coverage or power in the first hardening pass.
- Do not claim q8 warm-start support for applied users.

**Subagent review.**

- Gauss reviews numerical optimizer behavior and Hessian interpretation.
- Noether checks that endpoint names, formula terms, and reported covariance
  parameters match exactly.
- Fisher reviews recovery and interval wording.
- Grace checks CI and platform boundaries.
- Ada integrates the capability matrix and dashboard.

**Validation.**

Run the q8 runner, focused q8 tests if present, dashboard validation,
`git diff --check`, `pkgdown::check_pkgdown()`, and full `devtools::test()` if
any package code or tests change. If Julia-via-R wording appears, run the Julia
gate registry and parity tests that cover that wording; otherwise say no Julia
bridge claim is made.

**Decision after the block.**

The desired output is not a q8 promotion. It is a map of q8 endpoint statuses:
which cells can proceed to a later recovery or interval study, which need
method repair, and which should stay diagnostic-hold.

## Block 4: Fixed-Effect Skew-Normal Guard Grid

**Purpose.** Move the skew-normal tail-floor evidence from source/fit-stress
visibility toward a fixed-effect diagnostic grid. This is the next family-side
guard block after scale and covariance because the existing skew-normal
artifacts are deliberately small and include one ordinary-reference
non-converged, non-positive-Hessian fit.

**Current status.** The fixed-effect native R/TMB guard grid is now banked at
`docs/dev-log/simulation-artifacts/2026-06-19-skew-normal-guard-grid-diagnostic/`.
It requested 200 complete-data fits across ordinary, moderate-tail,
extreme-tail, and injected-tail cells. All 200 fits returned, converged, and
had `pdHess = TRUE`; injected generating-scale floor exposure did not become
fitted-scale floor domination, but 27 fixed-gradient warning rows keep the
overall decision at `diagnostic_hold`. This is guard visibility and fit-health
triage evidence only, not skew-normal recovery, interval calibration,
comparator, direct Julia, Julia-via-R, release, or CRAN evidence.

**Starting evidence.**

- `docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-diagnostic/`.
- `docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-fit-stress/`.
- `docs/dev-log/simulation-artifacts/2026-06-17-skew-normal-fixed-effect-pilot/`.

**Scope.**

- Fixed-effect skew-normal only.
- Complete-data only unless a separate missing-data issue is opened.
- Retain ordinary, moderate-tail, and extreme-tail cells.
- Record floor exposure at the source scale and fitted scale separately.
- Record convergence, `pdHess`, gradients, warnings, floor-dominated
  observations, and malformed or unstable cells.
- Do not add random effects, bivariate routes, structured routes, profile or
  bootstrap intervals, or release claims.

**Subagent review.**

- Curie designs the simulation cells and checks denominators.
- Fisher reviews whether any interval or recovery wording is supported.
- Pat reviews whether user-facing warnings tell an applied reader what to do.
- Rose audits stale skew-normal wording across the worklist and dashboard.

**Validation.**

Run the skew-normal artifact runner, dashboard JSON validation,
`tools/validate-mission-control.py`, `git diff --check`, and
`pkgdown::check_pkgdown()` if docs change. Run `devtools::test()` if package
code or tests change.

**Decision after the block.**

The first acceptable decision was `diagnostic_hold` for tail-floor behavior and
fit-health interpretation. Fitted-scale floor domination was not observed in
this grid, so later work can focus on fixed-gradient warning behavior,
operating-characteristic calibration, and comparator evidence. Do not call
skew-normal recovery, intervals, or public release readiness complete from this
block alone.

## Cross-Block Bridge And Companion-Package Gate

After each native R/TMB block, ask whether any claim needs direct Julia or
Julia-via-R support. If the answer is yes, open that as a separate bridge issue
or companion-package task with its own evidence:

- direct DRM.jl point-estimate and status checks in a DRM.jl checkout;
- R-side `engine = "julia"` registry row and representative rejection or
  parity test;
- CI/status evidence for the exact commit that carries the claim;
- dashboard rows that keep native R/TMB, direct Julia, and Julia-via-R separate.

If the answer is no, say so in the artifact boundary and do not run bridge
tests just to imply coverage that does not exist.

## Stop Points

Stop and write a recovery checkpoint when any block finishes its local
validation and issue breadcrumb, before moving to the next block. Also stop if a
block exposes a method problem that changes the next work order, such as q2
boundary warnings that make q8 premature, or skew-normal fit instability that
requires likelihood review before a larger grid.
