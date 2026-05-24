# After Task: Non-Gaussian Structured Issue Ledger Slices 406-420

## Goal

Turn the stretch queue after the remaining non-Gaussian structured planning
gates into route-specific implementation issue drafts and an NB2 q1 ADEMP
skeleton, without opening likelihood, TMB, formula grammar, extractor,
diagnostic, or interval code.

## Implemented

`docs/design/71-nongaussian-structured-issue-ledger.md` now records the route
key for future implementation issues: family, component, structured layer, q,
comparator, boundary rows, and evidence. It also provides issue-ready drafts for
the Poisson q1 implementation route, Poisson q1 smoke runner,
malformed-neighbour tests, and user documentation sync.

The same ledger adds an NB2 q1 ADEMP skeleton. The skeleton follows Morris,
White, and Crowther (2019) and Williams et al. (2024) by naming aims,
data-generating mechanism, estimands, methods, and performance measures before
any runner exists.

The ledger also records public-name and component contracts for future
structured `zi`/`hu`, scale, shape/ordinal, known-covariance versus latent
relatedness, extractor-name, and diagnostic-name issues.

## Mathematical Contract

No fitted mathematical contract changed. The Poisson route remains the only
first-slice structured non-Gaussian fitted route. The NB2 q1 section is a design
skeleton only and does not claim a fitted NB2 structured likelihood.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/71-nongaussian-structured-issue-ledger.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-23-nongaussian-issue-ledger-slices-406-420.md`
- `vignettes/implementation-map.Rmd`

## Checks Run

```sh
air format NEWS.md ROADMAP.md docs/design/71-nongaussian-structured-issue-ledger.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-23-nongaussian-issue-ledger-slices-406-420.md vignettes/implementation-map.Rmd
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

No package tests were added because this is an issue-ledger and planning slice.
The validation target is that ROADMAP, NEWS, the design ledger, implementation
map, check-log, and after-task report all keep slices 406-420 planning-only.

## Consistency Audit

Rose checked the main failure modes:

- NB2 q1 is a future ADEMP skeleton, not a fitted route;
- Poisson q1 issue text does not open slopes, q2/q4, `zi`, `hu`, spatial,
  animal, or `relmat()` support;
- issue drafts require extractors, diagnostics, interval status, user docs, and
  stale scans before fitted claims;
- known sampling covariance and latent relatedness stay separate.

## GitHub Issue Maintenance

No GitHub issues were opened in this slice. The issue bodies are staged in the
design ledger so the next implementation issue can be opened deliberately after
PR review. Related trackers remain #59, #147, and #31.

## What Did Not Go Smoothly

The main risk is issue sprawl. The ledger therefore records full issue bodies
locally instead of opening several GitHub issues during the overnight run.

## Team Learning

Ada should keep overnight issue work local until the route is ready for a real
tracker. Boole should reject broad issue names. Fisher and Curie should require
ADEMP and MCSE language before runner work. Pat should insist that user docs
move only after evidence exists. Grace should keep pkgdown validation in the
same chunk. Rose should keep the language from turning skeletons into claims.

## Known Limitations

No new fitted route exists. The package still does not fit NB2 structured
effects, structured `zi`/`hu`, non-Gaussian structured scale or shape effects,
structured count slopes, non-Gaussian spatial/animal/`relmat()` effects, q2/q4
count covariance, or mixed-response structured non-Gaussian models.

## Next Actions

Continue with slices 421-435 if time permits: profile-target row specifications,
`sdpars`/`ranef()` examples, simulation artifact and warning-ledger schemas,
smoke-grid cells, formal-grid admission criteria, and test-plan drafts.
