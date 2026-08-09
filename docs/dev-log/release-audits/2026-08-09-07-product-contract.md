# Product contract — drmTMB 0.7.0 candidate (Gate 0)

**Date:** 2026-08-09 · **Lane:** Claude task 1, Stage A
**Source commit:** `origin/main@ac363cadb605a2eda567de9027b873eebc4788c5`
**Release type:** `first_submission` · target **0.7.0** · `DESCRIPTION` still **`0.6.0`** (D-86)
**Status:** provisional. The final contract is re-read against the post-separation merged
`main` in Stage B.

> **Supersedes `2026-08-07-07-product-contract.md`**, whose census (187 `interval_feasible`
> / 55 `point_fit_recovery`, frozen 54) was measured at `8df6f2402` and predates the #953
> capability-truth reconciliation. Do not cite the older file for 0.7.

## What the package is

Univariate and bivariate distributional regression on Template Model Builder. One formula
per distributional parameter (`mu`, `sigma`, shape / `zi` / `hu` / `zoi` / `coi`, `nu`,
`rho12`). Default engine is bundled TMB; `engine = "julia"` is optional, experimental, and
`Suggests`-only.

Its distinctive contribution is **modelling the scale and shape with predictors**, not only
the mean — including residual log-SD carrying phylogenetic structure, and bivariate residual
correlation.

## Capability census — measured 2026-08-09

`docs/dev-log/dashboard/capability-ledger/cells.tsv`, 723 rows:

| `capability_status` | n | | `evidence_tier` | n |
| --- | ---: | --- | --- | ---: |
| implemented | 365 | | none | 364 |
| rejected_by_design | 348 | | **interval_feasible** | **192** |
| not_implemented | 10 | | point_fit_recovery | 74 |
| | | | diagnostic_only | 60 |
| | | | inference_ready_with_caveats | 29 |
| | | | **supported** | **4** |

`effect_type`: 449 structured · 100 fixed · 80 ordinary_re_slope · 76 ordinary_re_intercept
· 18 response_missingness. Separately: `missing_response` = 18 routes, all G3-verified.

**The contract-critical reading:** of 365 implemented cells, **33** carry a coverage-checked
interval claim (29 caveated + 4 supported). **192** return a computable interval with **no**
coverage certification. Any public wording must not blur those two.

## Settled public claims

| Claim | Settled by |
| --- | --- |
| First CRAN number is **0.7.0**; `0.6` is the dev cycle and never submits | D-86; `README`; `NEWS` |
| Not on CRAN yet | `cran.r-project.org/package=drmTMB` 404; `README` |
| Experimental lifecycle | D-41; README badge + banner |
| A successful fit is **not** permission to report an interval | `vignettes/capability-and-limits.Rmd:69-97`; the tier ladder |
| Profile is the default honest interval route for RE SDs; boundary warning required | D-97; D-117; `drmTMB_profile_boundary_warning`; `?confint.drmTMB` |
| D-117 PASS **withheld** | D-43 panel; lme4 comparator agreement to 4 dp |
| Binomial REML: fixed-only and multiple-term routes fail early; exactly one ordinary unlabelled intercept or one independent slope is `diagnostic_only` | PR #953 |
| `mc-0227` is public ML-Laplace `point_fit_recovery`; O3 (AGHQ + Cox-Reid) is **internal**, non-reportable | PR #953 |
| Julia is optional and unsupported for 0.7 | `DESCRIPTION` Suggests; `vignettes/julia-engine.Rmd` |

## Explicit non-goals for 0.7.0

CRAN upload · tag `v0.7.0` · `platform-clean` claim · D-43 panel · AGHQ/O3 as a public route
· broader non-Gaussian REML · correlated / labelled / structured slopes beyond admitted cells
· Q-series interval calibration · GVA / EVA / new estimators · missing-data G4+/MNAR ·
predictor multiple imputation · mixed-family bivariate · estimated spatial range · full
double-hierarchical individual-difference models · reinstating D-117 PASS.

## Overclaim search — 2026-08-09

Four defects found. **All are Stage B byte changes; none is applied in Stage A.**

| # | Defect | Location | Severity |
| --- | --- | --- | --- |
| 1 | **`offset()` documented for `truncated_nbinom2()`; a live fit rejects it.** Verified by fitting five families. | `R/drmTMB.R:22-23` → `man/drmTMB.Rd:169-171` | **contract defect** |
| 2 | README directs new users to install `@v0.5.0`; `vignettes/drmTMB.Rmd:64-67` calls that tag an unsupported install target | `README.md:84-90` | high visibility |
| 3 | Bivariate spatial-REML route still described "Recovery-only" after `mc-0199`/`mc-0672` were promoted to `inference_ready_with_caveats` on 2026-08-03 | `vignettes/capability-and-limits.Rmd:161` | stale prose |
| 4 | `inst/CITATION` version fallback string is `"0.1.4"` | `inst/CITATION` | cosmetic |

Full analysis of #1: [`2026-08-09-07-870-offset-analysis.md`](2026-08-09-07-870-offset-analysis.md).
Prepared diffs: [`2026-08-09-07-stage-b-byte-fixes.md`](2026-08-09-07-stage-b-byte-fixes.md).

**No live "CRAN ready", "on CRAN", or D-117-PASS-reinstatement wording was found.**

## Reader-surface finding carried forward

A four-lens blind review ([`2026-08-09-07-pre-release-user-gap-review.md`](2026-08-09-07-pre-release-user-gap-review.md))
found that **the evidence tier is not visible at the point of use** — `confint()` and
`summary()` print identically for certified and uncertified intervals, and
`summary.drmTMB`'s own roxygen concedes the tier is "a documentation-level curation, not a
runtime guard" (`R/methods.R:4032-4033`).

This is a **scope decision for Shinichi**, not a packaging defect, and it is deliberately
**not** resolved in Stage A. It is recorded here because the product contract is where a
gap between what the package claims about itself and what it shows the user belongs.

## Gate -1 profile flags

| Flag | Value | Basis |
| --- | --- | --- |
| `compiled_code` | true | `src/drmTMB.cpp`, `src/init.c`, 3 headers; `LinkingTo: RcppEigen, TMB` |
| `reverse_dependencies` | false | first submission |
| `system_or_external_services` | true | optional `JuliaCall` path must degrade cleanly |
| `large_data_or_vignettes` | true | 37 vignettes; installed size 31.2 MB (predecessor measurement) |

## Open owner decisions blocking the contract's finalisation

1. **Separation disposition** (Claude task 2) — MERGE / DEFER / DEFECT. Hard freeze gate.
2. **#870 `offset()`** — Option 1 (correct the docs) vs Option 2 (implement for
   `truncated_nbinom2`). Recommendation: Option 1.
3. **Tier surfacing** — ship 0.7 as-is, or take the one narrow bootstrap-boundary warning.
4. **D-93 / D-117** — publish/discharge remains Shinichi's call; candidate preparation does
   not answer it.
