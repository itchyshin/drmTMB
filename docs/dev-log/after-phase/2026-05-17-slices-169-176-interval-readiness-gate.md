# After Phase: Slices 169-176 Interval-Readiness Gate

## Goal

Close the current profile/bootstrap interval-readiness revisit before the
Gaussian random-slope block, while keeping q4 derived intervals and bootstrap
intervals clearly out of the implemented surface.

## Implemented

Slices 169-176 make three boundaries explicit:

- q4 ordinary and phylogenetic endpoint correlations, plus covariance products,
  remain derived interval-unavailable rows;
- public bootstrap interval methods are not implemented yet and now error
  before interval-table creation;
- `summary()`, `confint()`, `corpairs()`, prediction tables, and plotting
  consumers share the same interval status/source vocabulary.

The implementation adds `validate_interval_method()`,
`interval_status_levels()`, and `interval_source_levels()`, uses the shared
method validator from `confint()`, `summary()`, and `corpairs()`, and keeps
`plot_parameter_surface()` aligned with the current interval-status values.

## Mathematical Contract

A q4 endpoint correlation is derived from a covariance matrix:

```text
rho_ij = Sigma[i, j] / sqrt(Sigma[i, i] * Sigma[j, j])
```

and a covariance product is:

```text
cov_ij = sd_i * sd_j * rho_ij
```

These are nonlinear functions of several optimized covariance coordinates, not
single direct atanh-correlation targets. They stay
`derived_interval_unavailable` until `drmTMB` has a reparameterized or
fix-and-refit derived interval method with recovery tests.

The bootstrap audit did not pass. A public bootstrap method needs a deterministic
simulate-refit harness, a target extractor with stable ordering, a failure
ledger, and runtime/reproducibility controls before it can be exposed.

## Files Changed

- `R/profile.R`
- `R/methods.R`
- `R/plot-parameter-surface.R`
- `tests/testthat/test-profile-targets.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `vignettes/model-workflow.Rmd`
- `vignettes/model-map.Rmd`
- `man/confint.drmTMB.Rd`
- `man/summary.drmTMB.Rd`

## Checks Run

- `air format R/profile.R R/methods.R R/plot-parameter-surface.R tests/testthat/test-profile-targets.R README.md NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md vignettes/model-workflow.Rmd vignettes/model-map.Rmd docs/dev-log/check-log.md docs/dev-log/after-phase/2026-05-17-slices-169-176-interval-readiness-gate.md`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/confint.drmTMB.Rd` and `man/summary.drmTMB.Rd`.
- `Rscript -e 'devtools::test(filter = "profile-targets|summary|predict-parameters|plot-parameter-surface|corpairs|covariance-block-registry|phylo-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-map.Rmd", output_dir = tempfile("model-map-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e 'pkgdown::build_site(preview = FALSE)'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new unsupported-bootstrap tests check the public method boundary before any
interval table can be produced. The new shared-vocabulary test combines
`confint()`, `summary()`, and `predict_parameters()` outputs in one fit and
checks that their `conf.status` and `interval_source` values stay inside the
internal allowed sets. Existing q4 ordinary and phylogenetic tests continue to
check that derived endpoint correlations report
`derived_interval_unavailable`.

## Consistency Audit

The status inventory was updated in `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/12-profile-likelihood-cis.md`,
`vignettes/model-workflow.Rmd`, and `vignettes/model-map.Rmd`.

Stale scans checked that no source or generated pkgdown page claims implemented
bootstrap intervals or q4 profile intervals. The expected remaining hits say
that bootstrap is not implemented or that q4 intervals remain unavailable.

## What Did Not Go Smoothly

The bootstrap lane was tempting to prototype, but the audit made clear that a
narrow public method would be premature without a stable simulate-refit harness
and failure ledger. The correct Slice 171-172 outcome is deferral, not a shallow
API.

## Team Learning

- Ada kept the slice block scoped to a closeout gate and added a follow-up
  integration checkpoint for the PR stack.
- Fisher kept q4 and bootstrap claims conservative.
- Curie added tests around the method boundary and status vocabulary.
- Grace escalated validation to the full package test suite after focused tests
  and pkgdown checks passed.
- Pat kept the reader-facing workflow practical: use Wald for routine fixed
  effects, profile for direct profile-ready targets, and separate simulation
  studies when bootstrap coverage is the scientific target.
- Rose checked that the roadmap and known limitations close the gate rather
  than leave bootstrap as a vague promise.
- Boole kept method and status names stable.

## Known Limitations

- Public bootstrap intervals are not implemented.
- q4 endpoint-correlation and covariance-product intervals remain derived
  unavailable.
- Profile diagnostics still do not implement one-sided profile intervals or
  automatic recovery from non-monotone profiles.
- Full coverage simulations comparing Wald, profile, and bootstrap intervals
  remain later long-run work.

## Next Actions

Start Slice 177 by auditing ordinary Gaussian location random-slope support
against `(1 + x1 + x2 + ... | id)`, then pause for an integration checkpoint on
the open PR stack before piling up more slice branches.
