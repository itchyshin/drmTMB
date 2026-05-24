# After Task: Crash Recovery Consolidation

## Goal

Recover after another Codex crash, verify the mixed dirty tree from repository
evidence, and consolidate the status wording before any commit or further
feature work.

## Implemented

Ada wrote
`docs/dev-log/recovery-checkpoints/2026-05-24-090255-codex-checkpoint.md` and
audited the dirty tree as three current surfaces: pkgdown logo spacing,
ordinary NB2 q=1 phylogenetic `mu`, and ordinary NB2 log-`sigma` random
intercepts.

The consolidation pass tightened current-facing wording where the NB2
phylogenetic q1 report, NEWS, ROADMAP, worked-example inventory, or readiness
matrix could imply that all NB2 `sigma` random effects remained planned. The
current claim is narrower: ordinary NB2 log-`sigma` random intercepts fit, while
NB2 `sigma` slopes, structured `sigma`, zero-inflated/truncated/hurdle scale
routes, and NB2 `sigma` phylogeny remain planned.

## Mathematical Contract

No likelihood parameterization changed in this consolidation pass. The checked
contracts are:

```text
NB2 phylogenetic q1:
y_i | a ~ NB2(mu_i, size_i = 1 / sigma_i^2)
log(mu_i) = offset_i + x_i beta_mu + a_species[i]
log(sigma_i) = z_i beta_sigma
a ~ Normal(0, sigma_phylo^2 K_phylo)

NB2 log-sigma random intercept:
y_i | b ~ NB2(mu_i, size_i = 1 / sigma_i^2)
log(mu_i) = offset_i + x_i beta_mu
log(sigma_i) = z_i beta_sigma + b_id[i]
b_id ~ Normal(0, sd_sigma^2)
```

`sigma` remains the public NB2 overdispersion scale, with
`Var(y_i) = mu_i + sigma_i^2 * mu_i^2`.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-slices-496-510.md`
- `docs/dev-log/after-task/2026-05-24-crash-recovery-consolidation.md`
- `docs/dev-log/recovery-checkpoints/2026-05-24-090255-codex-checkpoint.md`

## Checks Run

```sh
Rscript tools/codex-checkpoint.R --goal "resume after crash; consolidate NB2 sigma random-intercept, NB2 phylo q1, and pkgdown dirty tree" --next "if continuing now, first review/split the mixed dirty tree into focused commits; rerun focused NB2 and pkgdown checks only if evidence freshness is needed"
Rscript -e "devtools::test(filter = 'nbinom2-location-scale|nongaussian-scale-boundary', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'poisson-mean|phase18-poisson-mu-random-effect|nongaussian-structured-boundary|emmeans-methods', reporter = 'summary')"
air format NEWS.md ROADMAP.md docs/design/37-worked-example-inventory.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-slices-496-510.md
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n 'NB2 `sigma`,|NB2 `sigma` random effects remain planned|NB2 `sigma` remains fixed-effect only|Non-Gaussian `sigma` random effects, structured slopes|keep NB2 `sigma`,|NB2 `sigma`, structured slopes' NEWS.md ROADMAP.md docs/design vignettes docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-slices-496-510.md -g '!*.html'
rg -n 'NB2 <code>sigma</code>,|NB2 <code>sigma</code> random effects remain planned|NB2 <code>sigma</code> remains fixed-effect only|Non-Gaussian <code>sigma</code> random effects, structured slopes|keep NB2 <code>sigma</code>,|NB2 <code>sigma</code>, structured slopes' pkgdown-site -g '*.html'
rg -n 'NB2 `sigma` phylogeny|ordinary NB2 log-`sigma` random intercepts|NB2 log-`sigma` focused recovery|bf\(count ~ x, sigma ~ z \+ \(1 \| id\)\)' NEWS.md ROADMAP.md README.md docs/design vignettes pkgdown-site/news/index.html pkgdown-site/ROADMAP.html pkgdown-site/index.html pkgdown-site/articles/implementation-map.html pkgdown-site/articles/distribution-families.html pkgdown-site/articles/count-nbinom2.html -g '!*.json'
git diff --check
```

Results:

- The checkpoint script wrote the new recovery checkpoint.
- The focused NB2 and scale-boundary test run passed.
- The adjacent Poisson, non-Gaussian structured boundary, and `emmeans` tests
  passed.
- `air format` completed without output.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed after the final wording patch.
- The stale-claim scans found no current false claim that all NB2 `sigma`
  random effects remain planned or fixed-effect only. Remaining hits were
  historical command text, expected boundary wording, or unrelated figure-label
  text.
- The positive scan found the ordinary NB2 log-`sigma` random-intercept wording
  and the NB2 `sigma` phylogeny boundary in source and rendered pages.
- `git diff --check` was clean.

## Tests Of The Tests

This was a consolidation pass, so no new test file was added. The relevant
tests had already been added in the feature slices. The pass reran the focused
NB2 test file, the non-Gaussian scale-boundary test file, adjacent Poisson and
structured-boundary tests, and pkgdown checks after the crash.

## Consistency Audit

README, ROADMAP, NEWS, formula grammar, family registry, likelihood notes,
validation-debt, readiness, implementation map, model map, source map, count
tutorial, family tutorial, generated pkgdown pages, and after-task reports now
tell the same current story: ordinary NB2 q=1 `phylo()` in `mu` fits; ordinary
NB2 log-`sigma` random intercepts fit; richer NB2 scale, structured,
zero-inflated, spatial, animal, `relmat()`, q2/q4, and bivariate count routes
remain planned or blocked.

## GitHub Issue Maintenance

No new issue action was taken in this consolidation pass. The two feature
after-task reports already record direct searches for NB2 phylogenetic q1,
`nbinom2` phylogenetic wording, and NB2 `sigma` random-intercept issues. The
consolidation changes only reconciled same-day local wording.

## What Did Not Go Smoothly

The crash left a broad dirty tree with at least three task surfaces. A first
stale-wording scan mixed expected boundary text with real stale phrases, so
Rose separated false positives from phrases that could mislead a current reader.

Grace accidentally ran `pkgdown::check_pkgdown()` concurrently with
`pkgdown::build_site()`. The check returned no problems and the site build
completed successfully, but future consolidation passes should run them
sequentially when rendered files are being rebuilt.

## Team Learning

When two same-day slices revise the same family boundary, Rose should audit the
earlier after-task report for "within this slice" wording. Pat should keep
public docs focused on what an applied user can fit now: NB2 `mu` phylogeny and
NB2 log-`sigma` random intercepts are separate first gates, not one broad NB2
structured-dependence claim.

## Known Limitations

No full `devtools::test()` or `devtools::check()` was run in this consolidation
pass. The validation is focused on the touched NB2, Poisson-adjacent, boundary,
and pkgdown surfaces.

No formal NB2 q1 phylogenetic or NB2 log-`sigma` random-intercept simulation
grid has been run. Both remain focused-test or smoke-level evidence.

## Next Actions

Create a focused commit for the consolidated dirty tree, then start the next
small evidence lane only after the commit boundary is clean. The next modelling
lane should be a small NB2 log-`sigma` random-intercept smoke grid or an
overdispersion-aware NB2 q1 phylogenetic ADEMP/runner lane, not another broad
feature jump.
