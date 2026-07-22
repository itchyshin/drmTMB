# After Task: Bivariate Coscale Confidence Eye

## 1. Goal

Repair the `bivariate-coscale` tutorial so its correlation comparison shows
honest uncertainty, distinguishes interval availability from coverage
validation, remains readable on mobile, and stays focused on its two worked
biological questions.

## 2. Implemented

The grouped example now calls `corpairs(fit_group, conf.int = TRUE)` and exposes
the resulting interval provenance. Residual `rho12` has a finite 95% profile
interval (`0.0677` to `0.2770`) and is drawn as the project-standard pale
Confidence Eye with a hollow estimate circle. The individual mean-mean row
returns `newdata_required` with no interval and therefore remains a hollow
point only.

The article no longer calls the constant residual-correlation profile a
"certified reporting target". It says that the interval is available while
its nominal coverage remains unvalidated. The figure caption makes the same
boundary explicit.

The advanced slope and covariance-capability catalogue was replaced by links
to the model map, formula grammar, and structural-dependence tutorial. Redundant
covariance/profile-target output was condensed. The source decreased from
4,157 to 3,530 words, from 830 to 703 lines, and from 23 to 19 code blocks.

## 3a. Decisions and Rejected Alternatives

Residual `rho12` is within-observation residual coupling after modelling both
responses' means and residual SDs. The individual mean-mean row is the
correlation between the two group-level random intercepts. The two rows are
different estimands and are not interchangeable.

A finite profile interval establishes interval availability, not nominal
coverage. This documentation repair changes no likelihood, parameterization,
formula grammar, estimator, interval algorithm, or capability tier.

The mixed display was chosen over two rejected alternatives. Keeping both rows
point-only would hide a genuine residual profile interval; drawing an eye for
the group row would manufacture reporting evidence that the ledger does not
support. The predictor-dependent `rho12` curve remains a line and ribbon
because a Confidence Eye is a scalar-comparison grammar, not a continuous-
function display.

The tutorial was shortened in place rather than split. Removing its advanced
capability catalogue preserves the established URL and the two worked examples
while sending fast-changing support details to the generated model map.

## 4. Files Touched

- `vignettes/bivariate-coscale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-21-bivariate-coscale-confidence-eye.md`

## 5. Checks Run

- `pkgdown::build_article("bivariate-coscale", new_process = FALSE)`: PASS.
- `devtools::test(filter = "plot-corpairs", reporter = "summary")`: PASS,
  48 expectations.
- `python3 tools/capability_ledger.py --check`: PASS, 30 generated outputs.
- `pkgdown::check_pkgdown()`: PASS, no problems found.
- Desktop render at 1440 x 1000: PASS; no body or table overflow.
- Mobile render at 390 x 844: PASS; no body or table overflow. The final mobile
  page height is 21,687 pixels, down from 24,889 before the repair.
- Both rendered figures were inspected individually from fresh image paths.

## 6. Tests of the Tests

The rendered `corpairs()` table is the positive and negative control: residual
`rho12` reports finite profile bounds, while the modelled group correlation
reports `newdata_required` and `NA` bounds. `plot_corpairs()` therefore receives
one interval-bearing row and one point-only row in the same table. The focused
plot tests exercise Confidence Eyes, optional conventional lines, unsupported
interval statuses, and point-only data.

## 8. Consistency Audit

The audit used:

```sh
rg -n "certified reporting target|keeps both rows point-only|Point estimates only; dotted line|group row is not shown with an interval" README.md ROADMAP.md NEWS.md docs vignettes R tests pkgdown-site
rg -n "rho12.*coverage|coverage.*rho12|profile.*rho12|rho12.*profile" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/implementation-map.Rmd
```

The edited page is internally consistent with the current ledger row
`mc-0181`, which is `interval_feasible` and explicitly lacks a committed
coverage simulation. `vignettes/figure-gallery.Rmd` still contains the phrase
"certified reporting target"; it belongs to that page's separate audit and was
not silently widened into this one-page repair. Historical after-task reports
were left unchanged as historical records.

No formula-grammar, roadmap, NEWS, known-limitations, or navigation update was
needed because implementation and supported syntax did not change.

## 7a. Issue Ledger

Issue #802 is open under the corrected title "No coverage evidence for
row-specific regression-rho12 intervals". This repair does not change that
coverage gap, so no issue comment, closure, or new issue was warranted.

## 9. What Did Not Go Smoothly

The first rendered Confidence Eye used a different fill colour from its hollow
point because ggplot trained the colour and fill scales on different row sets.
The same render also clipped the first subtitle. Manual matching colour/fill
scales and a shorter subtitle fixed both defects. This confirmed that source
inspection alone was insufficient.

## 11. Team Learning

Mixed-evidence figures need mixed displays: an interval-bearing row can use a
Confidence Eye without fabricating uncertainty for its point-only neighbour.
When colour and fill are trained on different subsets, set both scales
explicitly so one estimand keeps one visual identity.

The one-page audit boundary also reduces documentation conflicts: neighbouring
stale wording is recorded for its own audit rather than being folded into an
unreviewed cross-site rewrite.

## 10. Known Residuals

- Neither the constant nor predictor-dependent residual-`rho12` interval has a
  committed coverage campaign in the current capability ledger.
- The group correlation's callable `newdata` profile route remains diagnostic,
  not coverage-backed reporting evidence.
- This task did not rebuild the entire pkgdown site or run a full package check.
- The live site has not yet been updated from this branch.

## 12. Cross-Product Coverage

This task does NOT cover or establish coverage for constant or predictor-dependent
residual-`rho12` intervals, validate a group-correlation reporting interval,
change any likelihood or extractor, rebuild the complete site, run a full
package check, deploy pkgdown, or audit neighbouring pages.

### Next Actions

Review and land this focused branch, deploy pkgdown through the ordinary site
workflow, verify the live article, and then audit the figure-gallery page as a
separate one-page slice.
