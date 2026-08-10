# Product contract — drmTMB 0.7.0 CRAN readiness (Gate 0)

**Date:** 2026-08-07  
**Source commit (main merge base):** `8df6f2402` (PR #930)  
**Branch tip including docs:** `7bacb9e2c` + claim-freeze WIP  
**Release type:** first_submission (target version **0.7.0**; `DESCRIPTION` still **0.6.0**)

## What the package is

Univariate and bivariate distributional regression on Template Model Builder.
One formula per distributional parameter (`mu`, `sigma`, shape/zi/hu, `rho12`).
Default engine is bundled TMB; optional experimental `engine = "julia"` via Suggests.

## Settled public claims (evidence)

| Claim | Settled by |
| --- | --- |
| First CRAN number is **0.7.0**; 0.6 never submits | D-86; README; NEWS |
| Not on CRAN yet | cran.r-project.org 404; README |
| Experimental lifecycle | D-41; README badge + banner |
| Profile RE-SD intervals are the default honest path; boundary warning required | D-97; D-117 gate + PR #924 warning; `?confint.drmTMB` |
| D-117 PASS claim **withheld** | D-43 panel; comparator vs lme4 |
| Model-surface census after #930 | **187** `interval_feasible` / **55** `point_fit_recovery` (frozen PFR **54**) |

## Explicit non-goals (this readiness slice)

- CRAN upload / tag `v0.7.0` / DESCRIPTION bump to 0.7.0
- Platform-clean matrix (full 3-OS, win-builder, R-hub sanitizers)
- AGHQ / nested Cox-Reid campaigns
- Missing-data G4+ / MNAR / predictor MI
- WITHHOLD cell re-prereg under the old 135-trace contract
- Reinstating D-117 PASS

## Overclaim search (2026-08-07)

See `docs/dev-log/release-audits/2026-08-07-07-cran-claim-audit.md`. No live
"CRAN ready" / "on CRAN" / D-117 PASS reinstatement found after claim-freeze.

## Profile flags (Gate −1)

| Flag | Value | Note |
| --- | --- | --- |
| compiled_code | true | TMB C++ in `src/` |
| reverse_dependencies | false | first submission |
| system_or_external_services | true | JuliaCall Suggests-only optional path |
| large_data_or_vignettes | true | vignettes + size NOTE expected |
