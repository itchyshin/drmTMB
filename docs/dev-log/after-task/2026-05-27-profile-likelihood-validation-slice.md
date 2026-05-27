# After Task: Profile-Likelihood Validation Slice

## Goal

Run the broader validation gate for the profile-likelihood helper, tests,
reference documentation, pkgdown navigation, and model-workflow article before
staging or release issue updates.

## Implemented

No new feature surface was added in this slice. It validated the existing
profile-likelihood bundle:

- `profile.drmTMB()` and `plot.profile.drmTMB()` registrations and reference
  pages;
- `tests/testthat/test-profile-plots.R`;
- the model-workflow `site-sigma-profile-plot` article chunk; and
- durable figure-audit evidence under
  `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/`.

## Mathematical Contract

The validation keeps the same contract from the previous slices:
profile-likelihood curves plot likelihood-ratio distance,
`2 * (profile_nll - min(profile_nll))`, against the public profile-target
scale. The model-workflow article profiles constant residual `sigma` on the
positive response scale and shows 95% profile confidence endpoints.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-27-profile-likelihood-validation-slice.md`

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgload::load_all('.', export_all = FALSE, helpers = FALSE, attach_testthat = FALSE); pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
sips -g pixelWidth -g pixelHeight pkgdown-site/articles/model-workflow_files/figure-html/site-sigma-profile-plot-1.png
rg -n "profile\\.drmTMB|plot\\.profile\\.drmTMB|Profile shape for residual sigma|Residual sigma \\(response scale\\)|Profile-likelihood curve for constant residual" pkgdown-site/reference pkgdown-site/articles/model-workflow.html
git diff --check
```

- Full `devtools::test()` passed.
- Full `pkgdown::build_site(preview = FALSE)` passed.
- `pkgdown::check_pkgdown()` reported no problems.
- The rebuilt article profile plot is 1843 by 1152 pixels.
- Rendered-site scans found `profile.drmTMB`, `plot.profile.drmTMB`, and the
  new model-workflow profile figure.
- `git diff --check` was clean.

## Tests Of The Tests

The earlier profile-plot test slice already produced a failing first run before
the colour-mapping and S3-dispatch fixes. This validation slice reran the full
test suite and confirmed that the new focused tests pass inside the package's
complete test set.

## Consistency Audit

The full pkgdown build confirms that the new reference topics are reachable
from the rendered Reference index and that the model-workflow article renders
with the profile figure. The rendered wording still says confidence intervals
and profile confidence endpoints; it does not drift into Bayesian or posterior
language.

## GitHub Issue Maintenance

No GitHub issue was updated in this validation slice. Release issue #342 is
still the natural place to record this profile-likelihood demonstration once
the bundle is staged or committed.

## What Did Not Go Smoothly

The full site build was slower than the focused article render, as expected,
but completed without errors. No new failures were found.

## Team Learning

- Ada kept the slice to validation only.
- Grace ran full tests, full pkgdown build, pkgdown check, rendered-site scans,
  image-dimension checks, and whitespace checks.
- Florence rechecked the generated article/reference images as nonblank and
  legible.
- Fisher checked that rendered language stays in frequentist
  confidence/profile terminology.
- Rose marked the bundle ready for staging or a final release-issue update,
  with `devtools::check()` still available as a separate CRAN-style gate.
- No spawned subagents were running.

## Known Limitations

`devtools::check()` was not run in this slice. The bundle has full tests and
full pkgdown validation, but not a complete R CMD check.

## Next Actions

Stage this profile-likelihood bundle or, if a CRAN-style validation gate is
desired before staging, run `devtools::check()` as its own small slice.
