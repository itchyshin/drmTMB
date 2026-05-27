# After Task: Profile-Likelihood Model-Workflow Article Slice

## Goal

Integrate one compact profile-likelihood curve into
`vignettes/model-workflow.Rmd`, render the actual pkgdown article, and inspect
the rendered figure before broadening the profile-likelihood work.

## Implemented

The article now shows how to move from `profile_targets()` and interval tables
to a likelihood-shape diagnostic. The new chunk,
`site-sigma-profile-plot`, profiles the existing site random-intercept example:

```r
stats::profile(
  fit_site,
  parm = "sigma",
  level = 0.95,
  trace = FALSE,
  profile_precision = "fast"
)
```

The plot uses `plot.profile.drmTMB()`, `workflow_theme()`, a target-specific
x-axis label, caption, and alt text. The prose names what the reader should
look at: the fitted `sigma`, the likelihood-ratio cutoff, and profile
confidence endpoints.

## Mathematical Contract

No likelihood parameterization changed. The article profiles constant residual
`sigma` from:

```r
drmTMB(
  bf(growth ~ temperature + habitat + (1 | site), sigma ~ 1),
  family = gaussian(),
  data = fish_site
)
```

The x-axis is residual `sigma` on the public positive response scale. The
y-axis is likelihood-ratio distance,
`2 * (profile_nll - min(profile_nll))`. The dashed vertical lines are 95%
profile confidence endpoints from `stats::confint()` on the profile object.

## Files Changed

- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-27-profile-likelihood-model-workflow-article-slice.md`
- `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/figure-audit.md`
- `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/model-workflow-site-sigma-profile-curve.csv`
- `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/model-workflow-site-sigma-profile-plot.png`

## Checks Run

```sh
air format vignettes/model-workflow.Rmd
Rscript --vanilla -e "pkgload::load_all('.', export_all = FALSE, helpers = FALSE, attach_testthat = FALSE); pkgdown::build_article('model-workflow', pkg = '.', lazy = FALSE, new_process = FALSE, quiet = FALSE)"
rg -n "Profile shape for residual sigma|site-sigma-profile-plot|Profile-likelihood curve for constant residual|Residual sigma \\(response scale\\)|Fast full-profile pass" pkgdown-site/articles/model-workflow.html
sips -g pixelWidth -g pixelHeight pkgdown-site/articles/model-workflow_files/figure-html/site-sigma-profile-plot-1.png
wc -l docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/model-workflow-site-sigma-profile-curve.csv
Rscript --vanilla -e "devtools::test(filter = '^profile-plots$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

- Direct `pkgdown::build_article("model-workflow")` failed before
  `pkgload::load_all()` because the local checkout was not installed.
- The article render succeeded after loading the package in the current R
  process.
- The rendered HTML contains the new prose, chunk, caption, and alt text.
- The rendered article figure is 1843 by 1152 pixels.
- The article profile CSV has 30 curve rows plus one header row.

## Tests Of The Tests

The focused `profile-plots` tests from the previous slice were rerun after the
article edit to confirm that the profile and plotting methods still pass. The
article render is the main test for this slice because it executes the exact
vignette code and produces the figure users will see.

## Consistency Audit

The article text keeps the methods separate: Wald intervals come from
optimized-parameter covariance, the profile curve comes from
`TMB::tmbprofile()`, and the displayed endpoints are profile confidence
endpoints. It does not use posterior or credible-interval language.

The figure-audit note now records both the earlier method-evidence plot and
the rendered model-workflow article plot. The article plot fixes the earlier
reader-risk note by naming residual `sigma` in the x-axis and caption.

## GitHub Issue Maintenance

No issue comment was added. Release issue #342 remains the broader release
gate; this slice supplies article evidence but does not complete full release
validation.

## What Did Not Go Smoothly

Direct `pkgdown::build_article()` did not attach `drmTMB` because the package
was not installed in this local checkout. Loading the package with
`pkgload::load_all()` in the same process fixed the render. Record this as the
local article-render command for similar small slices.

## Team Learning

- Ada kept the scope to one compact article figure.
- Fisher checked likelihood-ratio and profile-confidence wording.
- Gauss and Noether checked the `sigma` response-scale target.
- Florence inspected the rendered article PNG.
- Pat checked the reader-facing label and caption.
- Grace rendered the article and checked HTML evidence, image dimensions,
  curve rows, focused tests, pkgdown, and whitespace.
- Rose recorded the local-render command pattern.
- No spawned subagents were running.

## Known Limitations

This slice did not run full `devtools::test()` or `devtools::check()`. It also
does not add real coarse-versus-dense profile comparison to the article; the
current article figure is a single fast full-profile pass for one direct
`sigma` target.

## Next Actions

The next small slice should run `pkgdown::check_pkgdown()` and any missing
focused checks if they have not already passed, then decide whether this
profile-likelihood work is ready to stage or whether one more small cleanup is
needed for NEWS/release issue #342.
