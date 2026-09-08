# Documented user workflow

OWNS: docs/design/01-formula-grammar.md, docs/design/03-likelihoods.md, vignettes/temporal-correlation.Rmd, vignettes/formula-grammar.Rmd, man/temporal.Rd, man/structured_effects.Rd, man/ranef.Rd, man/predict.drmTMB.Rd, man/simulate.drmTMB.Rd, NAMESPACE, README.md, NEWS.md, _pkgdown.yml, docs/dev-log/known-limitations.md, docs/dev-log/internal-roadmap.md, tests/testthat/test-temporal-g13.R, .unlazy/temporal-ar1/render/**

- [ ] G13: Exported workflow, generated docs, rendered article, navigation and scope limits agree with the verified implementation
  CHECK: Rscript --vanilla docs/dev-log/plans/2026-09-08-temporal-ar1/unlazy/check-tests.R G13
  EXPECT: TEMPORAL_G13_PASS
  EVIDENCE: pending

The tests must check a real local render; file presence is insufficient. G15 adds
the independent human-readable/scientific visual review. Roxygen source is final
before this leaf; generated-file expansion is recorded and leased if needed.
