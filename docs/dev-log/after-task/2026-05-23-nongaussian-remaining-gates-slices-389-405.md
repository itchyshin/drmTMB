# After Task: Non-Gaussian Structured Remaining Gates Slices 389-405

## Goal

Close the remaining non-Gaussian structured-dependence planning rows after the
Poisson q1 ADEMP front gate, while keeping the package scope unchanged: no new
likelihood, TMB, formula grammar, extractor, diagnostic, interval, or user-facing
fitted model surface.

## Implemented

Roadmap rows 389-405 now close as planning gates. They record the boundaries for
non-Gaussian scale, shape, ordinal, known sampling covariance versus latent
relatedness, extractors, diagnostics, simulations, intervals, user fallbacks,
error messages, formula grammar, documentation, issue templates, Poisson first
issue, NB2 first issue, `zi`/`hu` future issues, Phase 18 admission, and
planning closeout.

`docs/design/66-implementation-map-slices-356-405.md` now has a row-by-row
389-405 table and a reusable implementation issue template. The template forces
future work to name one family, one distributional parameter, one structured
layer, one q, one fitted formula, one nearest fallback, extractor names,
interval status, diagnostics, malformed-neighbour errors, ADEMP or recovery
runner, user docs, and stale-claim scans.

The implementation-map article now gives users extra fallback rows for
non-Gaussian structured scale or shape effects, known covariance versus latent
relatedness, and unsupported structured count syntax.

## Mathematical Contract

No mathematical contract changed. The first fitted non-Gaussian structured route
remains the existing ordinary Poisson q1 phylogenetic `mu` intercept:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree)),
  family = poisson(link = "log"),
  data = dat
)
```

The remaining non-Gaussian structured routes stay planned or blocked until their
own likelihood, extractor, diagnostic, interval, simulation, documentation, and
malformed-input evidence exists.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/66-implementation-map-slices-356-405.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-23-nongaussian-remaining-gates-slices-389-405.md`
- `vignettes/implementation-map.Rmd`

## Checks Run

```sh
air format NEWS.md ROADMAP.md docs/design/66-implementation-map-slices-356-405.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-23-nongaussian-remaining-gates-slices-389-405.md vignettes/implementation-map.Rmd
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'NB2 .*structured.*(now fits|now fit|is fitted|implemented)|spatial\(.*poisson.*(now fits|now fit|is fitted|implemented)|animal\(.*poisson.*(now fits|now fit|is fitted|implemented)|relmat\(.*poisson.*(now fits|now fit|is fitted|implemented)|structured count slopes.*(now fit|now fits|fitted|implemented)|structured `zi` random effects.*(now fit|now fits|fitted|implemented)|structured `hu` random effects.*(now fit|now fits|fitted|implemented)' README.md ROADMAP.md NEWS.md docs/design vignettes -g '!*.html'
git diff --check
```

Outcomes:

- To be completed before commit.
- `air format` completed without output.
- `pkgdown::check_pkgdown()` reported no problems.
- The narrowed false-support scan returned no hits.
- `git diff --check` was clean.

## Tests Of The Tests

No new tests were added because this is a planning, documentation, and
issue-template slice only. The validation target is consistency: the roadmap,
design ledger, implementation-map article, NEWS, check-log, and after-task note
must agree that slices 389-405 are planning gates and not fitted support.

## Consistency Audit

Rose checked the main overclaiming risks:

- structured non-Gaussian scale and shape effects remain planned;
- `meta_V(V = V)` known sampling covariance remains distinct from latent
  `relmat()` relatedness;
- `zi` and `hu` structured random effects remain future probability-component
  issues;
- unsupported syntax should be designed to fail early rather than reaching TMB;
- Phase 18 broad non-Gaussian structured grids wait for one narrow route to
  pass recovery, diagnostics, intervals, and docs.

## GitHub Issue Maintenance

This slice extends PR #316 rather than opening new issues. Related trackers
remain open: #59, #147, and #31. Future implementation issues should use the
route-specific template in `docs/design/66-implementation-map-slices-356-405.md`
instead of a broad non-Gaussian structured parity issue.

## What Did Not Go Smoothly

The first long-run boundary is sequencing: PR #316 is green and open, but not
merged. The overnight work therefore stays on the same branch and remains
planning-only so it does not build new implementation on top of unmerged
documentation state.

## Team Learning

Ada should keep overnight slices chunked by validation boundary, not by ambition.
Boole should require one route per implementation issue. Fisher and Curie should
keep ADEMP and MCSE language attached to every simulation-admission claim. Pat
should require fallback text for applied users before a planned row closes.
Grace should keep cheap validation commands close to each chunk. Rose should
continue scanning for accidental fitted claims whenever planning rows move.

## Known Limitations

The package still does not fit NB2 structured effects, non-Gaussian structured
scale or shape effects, structured `zi` or `hu` random effects, structured count
slopes, non-Gaussian spatial/animal/`relmat()` effects, q2/q4 count covariance,
or mixed-response structured non-Gaussian models.

## Next Actions

Continue, time permitting, with stretch slices 406 and onward: create
route-specific issue ledgers, draft the Poisson phylogenetic q1 implementation
issue body, draft the smoke-runner issue body, and add the malformed-neighbour
test checklist.
