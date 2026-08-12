# After Task: Reader-workflow audit

## Goal

Test ten article-shaped, exported-API-only drmTMB workflows from tabular data
import through fitting, diagnostics, and a reportable output; retain genuine
reader blocks in a classified gap register.

## Implemented

`tools/run-reader-workflow-audit.R` builds ten small deterministic fixtures,
writes and reads each as CSV, fits the documented model, runs `check_drm()`,
and requests `summary()` plus response-scale `fitted()` output. The generated
TSV records the exact model, estimand, uncertainty route, diagnostics, report
artifact, evidence tier, warnings, and first blocking point. The companion
audit separates missing public estimands, documentation/API defects, missing
inference evidence, and scientifically unsupported requests.

## Mathematical Contract

No likelihood, parameterization, or formula grammar changed. The audit uses
the existing family contracts: Gaussian `sigma` is residual SD; NB2 `sigma` is
dispersion; beta-binomial consumes successes/failures; ordinal cutpoints remain
ordered latent-logistic thresholds; `rho12` is residual correlation; and
`meta_V(V = vi)` supplies known sampling variance.

## Files Changed

- `tools/run-reader-workflow-audit.R`
- `docs/dev-log/reader-workflow-audit/README.md`
- `docs/dev-log/reader-workflow-audit/2026-08-12-reader-workflow-smoke.tsv`
- `docs/dev-log/reader-workflow-audit/2026-08-12-reader-workflow-audit.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-reader-workflow-audit.R`
  — ten of ten workflows passed import, fit, `check_drm()`, and report output;
  no retained warning or first blocker.
- `git diff --check` — passed.
- Namespace/source inspection confirmed `spatial()` and `spatial_coords()` are
  exported; `spatial()` is the formula marker and not a `spatial_*` fit helper.

## Tests Of The Tests

The initial spatial row failed because the audit supplied a bare formula;
drmTMB correctly required `bf()`/`drm_formula()`. The runner was corrected and
then rerun successfully. The first beta-binomial fixture warned at the binomial
boundary; it was replaced by a deterministic overdispersed fixture and rerun
without warning. These are audit-fixture repairs, not package changes.

## Consistency Audit

Searched the public package surface for ordinal cutpoints, response plus
`mi()`, bipartite routes, `prediction_grid()`/`predict_parameters()`, and
direct phylogenetic internal-field use. Existing boundaries agree with the gap
register: ordinal cutpoint profile intervals are not public on main, missing
response and missing predictors remain distinct routes, and broad structured
interval claims remain withheld.

## GitHub Issue Maintenance

`gh issue list` could not reach GitHub from this environment. No issue was
opened or changed; the audit therefore avoids claiming that its P1 items are
new tracker findings. The ordinal gap is already documented in issue #967's
decision memo.

## What Did Not Go Smoothly

The generated fixture initially made two implementation mistakes: an unwrapped
spatial formula and a beta-binomial sample too close to the binomial boundary.
Both failures improved the harness rather than being hidden.

## Team Learning

An article can be visually polished yet still be incomplete as an analysis
workflow. The required reader contract is data import → explicit formula → fit
→ `check_drm()` → uncertainty/status → report output → stated limitation.

## Known Limitations

This is a smoke audit, not recovery, calibration, or capability promotion. It
does not establish cutpoint, phylogenetic, spatial, or bivariate correlation
interval quality; MNAR or response-plus-`mi()` support; or release readiness.

## Next Actions

Address P1 reader gaps as small reviewable documentation/API slices: a
standalone ordinal workflow aligned with the separate cutpoint work, replacement
of phylogenetic internal fields with exported accessors, and a bipartite
diagnostic/status/report endpoint. Then reuse this runner as a regression smoke
whenever the public analysis surface changes.
