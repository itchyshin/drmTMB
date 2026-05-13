# After Task: Slice 10 Phylo-Only Batch Audit

## Goal

Close the autonomous phylo-only batch without drifting into spatial work.

## Implemented

This slice did not add a new likelihood path. It audited the batch created after
slice 5:

- slice 6: `profile_targets()` inventory for bivariate phylogenetic SD and
  correlation labels;
- slice 7: `summary(fit)$covariance` row for the fitted phylogenetic
  mean-mean covariance;
- slice 8: direct `confint(..., method = "profile")` smoke coverage for
  `eta_cor_phylo`;
- slice 9: reader-facing tutorial and model-map guidance for the fitted
  phylogenetic mean-mean layer.

## Mathematical Contract

The implemented layer is still the first fitted bivariate phylogenetic location
slice:

```text
u_species = [u_mu1, u_mu2]'
u_species ~ MVN(0, Sigma_phylo)
rho_phylo = cor(Sigma_phylo[1, 2])
```

It is distinct from residual `rho12`, ordinary group-level covariance,
non-phylogenetic species covariance, and future spatial covariance.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-10-phylo-only-batch-audit.md`

This audit also verified the already-touched code, tests, docs, and generated
reference files from slices 6--9.

## Checks Run

- `Rscript -e 'devtools::test(filter = "profile-targets|summary|corpairs|check-drm|phylo-gaussian")'`
- `Rscript -e 'devtools::test()'`
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'spatial.*implemented|spatial.*now fits|bivariate phylogenetic.*planned|bivariate phylo\(\) syntax remains planned|q=4.*implemented|full q=4.*implemented' NEWS.md README.md ROADMAP.md docs vignettes man R tests`
- `rg -n 'corpars\$phylo|cor:phylo|summary\(fit.*\)\$covariance|biv_phylo_mu_covariance|phylogenetic.*mean-mean' NEWS.md README.md ROADMAP.md docs vignettes man R tests`
- `git diff --check`

The final focused audit tests passed with 606 expectations. The full suite after
the code/profile changes passed with 2,758 expectations and no failures,
warnings, or skips. The touched vignettes rendered, and `pkgdown::check_pkgdown()`
reported no problems.

## Tests Of The Tests

The focused audit run covers the fitted bivariate phylogenetic likelihood,
`corpairs()`, `summary()`, `check_drm()`, and profile-target/profiling surfaces
together. The stale-wording scans check the main failure mode for this batch:
overstating spatial or q=4 support.

## Consistency Audit

The repository now presents one current status: matching intercept-only
`phylo()` terms in bivariate Gaussian `mu1` and `mu2` are fitted, reported,
diagnosed, and profile-smoke-tested. Spatial remains deferred.

## What Did Not Go Smoothly

The crash recovery made it easy to mix the spatial sibling lane back into the
plan. The correction was to keep spatial wording as planned-only and restrict
all new code, tests, and examples to phylogenetic support.

## Team Learning

Rose should force a final status split after every autonomous batch: fitted now,
reported now, profiled now, and planned later. That split prevented the
phylogeny work from becoming an accidental spatial claim.

## Known Limitations

Still planned: spatial models, phylogenetic slopes, phylogenetic `sigma`, q=4
phylogenetic location-scale covariance, non-phylogenetic species covariance,
random effects in `rho12`, and derived covariance intervals.

## Next Actions

The safest next phylo-only implementation boundary is not spatial. It is either
one larger simulation-recovery check for the fitted bivariate phylogenetic
mean-mean correlation, or a small ordinary species-plus-phylo separation design
slice before any non-phylogenetic species covariance code.
