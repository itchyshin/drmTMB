# Q8 Profile And Bootstrap Fallback Pilot

This slice checked whether profile likelihood or parametric bootstrap can serve
as the q8 fallback when Hessian-based inference is weak. The reader is the
contributor deciding whether the ordinary Gaussian q8 endpoint route can move
from diagnostic artifacts toward interval, coverage, or power evidence.

## What Changed

The pilot wrote artifacts under
`docs/dev-log/simulation-artifacts/2026-06-08-q8-profile-bootstrap-fallback-pilot/`.
It refit the five hard q8 diagnostic rows with cold q8 and q4-staged q8 starts,
then reran `se = TRUE` probes for the weak-SD-ratio and high-correlation rows.
It also saved the staged-fit `profile_targets()` inventory, one endpoint-profile
interval attempt, one generic public bootstrap attempt, and one unsupported
derived-correlation bootstrap check.

No package source code changed in this slice. The edits are documentation,
artifact, check-log, and after-task closeout.

## Evidence

The q4-staged start rescued the low-replication row again: cold q8 returned
optimizer code 1 with minimum q8 correlation eigenvalue 5.57e-14, while
q4-staged q8 returned optimizer code 0 with minimum eigenvalue 2.26e-7. The
same staged route did not rescue the weak-SD-ratio or residual-`rho12` stress
rows, and it worsened the high-correlation row relative to the cold start.

The `se = TRUE` probe now has mixed rather than uniformly failed Hessian
evidence. The weak-SD-ratio row remained nonconverged with `pdHess = FALSE`.
For the high-correlation row, the cold q8 start returned convergence code 0 and
`pdHess = TRUE`, while the q4-staged q8 fit returned convergence code 1 and
`pdHess = FALSE`.

The interval boundary is direct versus derived. Across five staged q8 fits,
fixed effects, residual `rho12`, and all q8 endpoint SDs were direct
`profile_ready` targets. The 28 q8 group-level correlations per fit were
derived `unstructured_corr` rows with
`profile_note = "derived_unstructured_correlation"`.

One direct q8 endpoint SD profile interval succeeded. For the staged
low-replication fit, `confint(..., method = "profile",
profile_engine = "endpoint", level = 0.70)` returned 0.239 to 0.359 for
`sd:mu:mu1:(1 + x | p | id):(Intercept)`.

The generic public bootstrap route did not rescue that same fit. With `R = 3`,
`confint(..., method = "bootstrap")` returned `bootstrap_unavailable`, with 0/3
successful refits and the warning `NA/NaN function evaluation`. The public
bootstrap route also rejected a q8 group-level correlation before refitting
because derived q8 correlations are not supported bootstrap targets.

## Team Review

Ada: keep q8 at `hold_diagnostic`; the fallback pilot clarifies the next slice
but does not promote q8 intervals.

Fisher: direct endpoint SD profiles are now plausible for selected converged q8
fits, but one scalar interval is not coverage evidence.

Curie: generic bootstrap needs a refit-success audit before it can be used as a
q8 fallback, and derived correlations need a custom statistic-extraction lane.

Rose: documentation should no longer say simply "q8 intervals unavailable";
the accurate boundary is direct SD profile possible, generic bootstrap unstable
in the pilot, derived correlations unsupported.

Grace: no source code changed; validation should focus on artifact presence,
documentation consistency, and stale-claim scans.

## Commands

```sh
Rscript --vanilla - <<'RS'
# q8 profile/bootstrap fallback pilot; wrote
# docs/dev-log/simulation-artifacts/2026-06-08-q8-profile-bootstrap-fallback-pilot/
RS
```

Follow-up validation is recorded in `docs/dev-log/check-log.md`.

## Remaining Limits

Q8 remains fitted and diagnostic-artifact ready only. It is not coverage-ready,
power-ready, or broadly interval-ready. The next q8 slice should either improve
the staged-start route on hard rows or explicitly design a derived-statistic
bootstrap artifact for q8 group-level correlations.
