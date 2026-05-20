# After Task: Slices 1139-1238 Ledger And Bivariate Mean-Scale Blocks

## Goal

Ada restarted the post-1138 lane with PR #263 as the integration target, kept
the figure and reference promises visible, and closed the missing bivariate
ordinary covariance combination: two independent same-response `mu`/`sigma`
random-intercept blocks plus residual `rho12`.

## Implemented

- Added a durable slice plan:
  `docs/dev-log/slice-plan-1139-1238-visual-reference-convergence.md`.
- Confirmed the open PR is #263, "Consolidate Ayumi stress evidence and Phase
  18 staging", from `codex/slices-363-full-ayumi-starts` to `main`.
- Allowed bivariate Gaussian labelled random intercepts to use separate
  response-specific `mu`/`sigma` labels, such as `mu1`/`sigma1` with label `p`
  and `mu2`/`sigma2` with label `q`, while keeping residual `rho12`,
  `mu1`/`mu2`, and `sigma1`/`sigma2` covariance layers separate.
- Updated `check_drm()` so bivariate same-response `mu`/`sigma` covariance
  diagnostics report one row per response-specific block.
- Synchronized README, NEWS, ROADMAP, formula grammar docs, the formula grammar
  article, and known limitations so they no longer imply that only one
  same-response bivariate `mu`/`sigma` pair can be fitted.

## Mathematical Contract

The fitted two-block model is a pairwise ordinary random-intercept bridge, not
an all-four q=4 block:

```r
drm_formula(
  mu1 = y1 ~ x + (1 | p | id),
  mu2 = y2 ~ x + (1 | q | id),
  sigma1 = ~ z + (1 | p | id),
  sigma2 = ~ z + (1 | q | id),
  rho12 = ~ w
)
```

The `p` block estimates the latent group correlation between `mu1` and
`sigma1`; the `q` block estimates the latent group correlation between `mu2`
and `sigma2`. These labels do not estimate `mu1`/`mu2` or `sigma1`/`sigma2`
same-parameter covariance. Residual `rho12` remains the within-observation
correlation.

## Files Changed

- `R/drmTMB.R`
- `R/check.R`
- `tests/testthat/test-biv-gaussian.R`
- `man/check_drm.Rd`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/slice-plan-1139-1238-visual-reference-convergence.md`

This report sits beside the earlier figure-rescue report for the visual side of
the same 1139-1238 lane.

## Checks Run

```sh
gh pr list --state open --limit 20 --json number,title,headRefName,baseRefName,isDraft,updatedAt,url
air format R/drmTMB.R R/check.R tests/testthat/test-biv-gaussian.R
Rscript -e "devtools::test(filter = '^biv-gaussian$|^check-drm$|^profile-targets$|^summary$')"
Rscript -e "devtools::document()"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- Targeted tests: 1,507 expectations, 0 failures, 0 warnings, 0 skips.
- `devtools::document()`: completed.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: clean.

## Tests Of The Tests

The new bivariate test failed before the implementation change because
different labelled `mu1` and `mu2` blocks were treated as an unsupported
same-parameter covariance request before the same-response `mu`/`sigma` bridge
could pair them. After the fix, the test asserts:

- two `corpars$mu_sigma` rows;
- two `corpairs(class = "mean-scale")` group rows plus one residual `rho12`
  row;
- no accidental `mu1`/`mu2` or `sigma1`/`sigma2` group rows;
- two direct `eta_cor_mu_sigma` profile targets;
- two `check_drm()` bivariate mean-scale diagnostic rows.

## Consistency Audit

Rose's stale wording scan focused on:

```sh
rg -n 'one same-response|first same-response|one labelled random-intercept pair|first mean-scale block|same-response cross-parameter random-intercept covariance block' README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd R/drmTMB.R R/check.R tests/testthat/test-biv-gaussian.R
```

The remaining match is the current NEWS wording that now says "blocks" and
names the two-label example. The old "one pair only" wording was removed from
current user-facing status docs.

## What Did Not Go Smoothly

The original bivariate labelled-covariance validator conflated "different
labels in the same parameter layer" with "unsupported covariance" too early.
That was correct for an unpaired `mu1`/`mu2` request, but wrong when each label
had a matching same-response `sigma` partner.

## Team Learning

- Ada kept PR #263 pinned as the integration target.
- Boole and Noether tightened the formula story so the two-label model is not
  confused with q=4 or same-parameter covariance.
- Fisher kept residual `rho12` and latent group-level mean-scale correlations
  separate.
- Rose required the slice plan because this lane has too many old promises to
  rely on chat memory.
- Grace required pkgdown and `git diff --check` after the documentation sync.

These were role perspectives, not spawned agents.

## Known Limitations

- The two-block path is intercept-only ordinary grouped covariance. Bivariate
  random slopes, slope-level mean-scale covariance, q=6/q=8 endpoints, and
  random effects in `rho12` remain planned.
- The slice ledger does not by itself close the reference-index audit,
  forgotten-promise issue triage, public bootstrap API, or broader Ayumi
  convergence re-tests. It gives those tasks a concrete order and records which
  part closed locally.

## Next Actions

1. Continue slices 1159-1178: rendered reference-index audit and
   forgotten-promise status table.
2. Continue slices 1189-1208: convergence and profile-interval hardening for
   Ayumi-style hard fits.
3. Continue slices 1209-1228: public bootstrap-interval design and Phase 18
   simulation integration, capped at 10 cores.
4. Keep all integration work on PR #263 unless the project owner asks for a new
   PR.
