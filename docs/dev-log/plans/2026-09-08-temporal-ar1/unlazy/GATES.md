# Temporal AR1 scope

OWNS: R/temporal.R, R/parse-formula.R, R/drmTMB.R, R/methods.R, R/check.R, R/profile.R, src/drmTMB.cpp, src/temporal-ar1.hpp, tests/testthat/test-temporal-*.R, tests/testthat/helper-temporal-reference.R, inst/validation/temporal-ar1-recovery.R, docs/design/01-formula-grammar.md, docs/design/03-likelihoods.md, vignettes/temporal-correlation.Rmd, vignettes/formula-grammar.Rmd, man/temporal.Rd, man/structured_effects.Rd, man/ranef.Rd, man/predict.drmTMB.Rd, man/simulate.drmTMB.Rd, NAMESPACE, README.md, NEWS.md, _pkgdown.yml, docs/dev-log/known-limitations.md, docs/dev-log/internal-roadmap.md, docs/dev-log/check-log.md, docs/dev-log/plans/2026-09-08-temporal-ar1/**, docs/dev-log/after-task/2026-09-08-temporal-ar1-implementation.md, docs/dev-log/plan-actual/2026-09-08-temporal-ar1.md, .Rbuildignore

Scope: Proposed ownership only. S0 must resolve foreign ownership before claiming
any implementation file, especially profile/methods. Sequential leaves transfer
shared paths; the two disjoint leaves 04 and 05 may run together after leaf 03.
No implementation lease or user approval is asserted by this file.

The runnable gates are in `gates/leaf-*.md`. The top-level manual G0 below applies
to every leaf. Use `--scope temporal-ar1 --status` to parse the whole scope.
Do not claim the top-level ownership list as a parallel worker: it is the proposed
whole-arc boundary. Each active worker claims only its eligible leaf after S0.

- [ ] G0: The user approved this exact scope; a fresh Terra task holds safe shared-file leases and the guard-owner receipt
  EVIDENCE: pending

Manual: Ada records actual user approval, immutable plan revision, fresh task
identity, root and lease results. Include entry point, behaviour, guard file and
owner for the full method table. A checked box, launch or --approve command is not
user consent. No inference/bootstrap/repeatability path is implicitly transferred.
