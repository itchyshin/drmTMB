# After Task: Non-Gaussian Structured q1 Planning Slices 1-10

## Goal

Do the first ten items in the next slice set after PR #315: merge and sync the
green deprecation/status PR, refresh tracker state, and turn the first
non-Gaussian structured-dependence planning rows into concrete design evidence.
The package should still fit no new likelihood in this slice.

## Implemented

PR #315, "Deprecate meta_known_V and refresh status docs", was squash-merged.
The new branch `codex/non-gaussian-q1-planning-1-10` was created from the
updated `origin/main` at `1877b825`.

Roadmap rows 381-388 now close as planning rows. They separate non-Gaussian
families, distributional components, and structured layers before any new
likelihood work. The first route remains one non-zero-inflated Poisson `mu`
phylogenetic q1 intercept; NB2 q1 is the next practical count candidate, while
`zi`, `hu`, structured slopes, q2/q4 count covariance, spatial, animal,
`relmat()`, scale, shape, ordinal, bounded-response, and mixed-response routes
remain planned.

`docs/design/70-phase-18-poisson-structured-q1-ademp.md` is the new ADEMP
sheet. It names aims, data-generating mechanism, estimands, fitted method,
ordinary grouped comparator, performance measures, smoke-runner file layout,
and user-facing fallback examples for the Poisson phylogenetic q1 route.

The Phase 18 programme, pre-simulation readiness matrix, validation-debt
register, implementation-map article, `docs/design/66-implementation-map-slices-356-405.md`,
`docs/design/67-sdstar-p8-poisson-q1.md`, `ROADMAP.md`, and `NEWS.md` now point
to that ADEMP gate.

No spawned subagents were used. Ada coordinated branch and tracker state. Boole
checked formula and component naming. Fisher and Curie shaped ADEMP, recovery,
and smoke-runner expectations. Pat checked fitted alternatives for users.
Grace checked pkgdown and vignette validation. Rose checked stale claims and
kept the slice as planning rather than implementation.

## Mathematical Contract

No formula grammar, likelihood, TMB parameterization, extractor, interval, or
diagnostic code changed.

The fitted surface remains exactly the existing ordinary Poisson q1
phylogenetic `mu` intercept:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree)),
  family = poisson(link = "log"),
  data = dat
)
```

The ADEMP sheet describes this model as:

```text
a ~ Normal(0, sd_phylo^2 A)
eta_mu_i = offset_i + beta0 + beta1 * x_i + a_species[i]
mu_i = exp(eta_mu_i)
count_i ~ Poisson(mu_i)
```

The planned smoke runner should estimate fixed `mu` coefficients and the direct
structured SD target. It should not create latent correlation rows for q1, and
it should not admit NB2, zero-inflated, hurdle, spatial, animal, `relmat()`,
slope, q2, q4, `sigma`, shape, ordinal, bounded-response, or mixed-response
structured routes.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/66-implementation-map-slices-356-405.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/70-phase-18-poisson-structured-q1-ademp.md`
- `docs/dev-log/check-log.md`
- `vignettes/implementation-map.Rmd`

## Checks Run

```sh
gh pr merge 315 --repo itchyshin/drmTMB --squash --delete-branch --subject "Deprecate meta_known_V and refresh status docs (#315)"
git fetch origin
git checkout -b codex/non-gaussian-q1-planning-1-10 origin/main
air format NEWS.md ROADMAP.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/66-implementation-map-slices-356-405.md docs/design/67-sdstar-p8-poisson-q1.md docs/design/70-phase-18-poisson-structured-q1-ademp.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-23-nongaussian-q1-planning-slices-1-10.md vignettes/implementation-map.Rmd
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::build_vignettes()"
Rscript -e "pkgdown::build_site()"
rg -n "Poisson q1.*broad|NB2 .*structured.*fitted|spatial\\(.*poisson|animal\\(.*poisson|relmat\\(.*poisson|structured count slopes.*fitted|structured `zi` random effects|structured `hu` random effects" README.md ROADMAP.md NEWS.md docs/design vignettes -g '!*.html'
git diff --check
```

Outcomes:

- `pkgdown::check_pkgdown()` reported no problems.
- `devtools::build_vignettes()` completed successfully.
- `pkgdown::build_site()` completed successfully.
- The stale-claim scan returned no false broad-support hits.
- `git diff --check` was clean.

## Issue Maintenance

The slice touches open Phase 18 and structured-dependence trackers, but it does
not close them. The relevant open issues remain:

- #59, "Phase 18: comprehensive simulation framework and reporting"
- #147, "Implement animal() and relmat() known-relatedness structured effects"
- #31, "Phase 6b: upgrade tutorials and user-facing learning path"

Issue comments should point maintainers to the eventual PR once this branch is
opened.

## Next

The next ten slices should cover rows 389-398: scale and shape gates, ordinal
mixed-model gates, known-covariance boundaries, extractor names, diagnostic
requirements, simulation and interval contracts, user-route fallback text, and
error-message gates. Code should still wait until the issue template for one
family-layer-component route is closed.
