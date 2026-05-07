# drmTMB Agent Instructions

`drmTMB` is an R package for fast univariate and bivariate distributional
regression using Template Model Builder.

## Core Scope

- Support one-response and two-response models only.
- Use one formula per distributional parameter.
- Prioritize location, scale, shape, zero inflation, random-effect scale, and
  residual correlation.
- Higher-dimensional multivariate models belong to `gllvmTMB`, not `drmTMB`.
- Meta-analysis is Gaussian regression with known sampling covariance; do not
  introduce `meta_gaussian()` or `tau ~` syntax without an explicit design
  decision.
- `rho12` is the canonical residual bivariate correlation parameter. `rho` may
  become an alias later, but docs and tests should use `rho12`.
- Bivariate models should prefer separate response formulas (`mu1 = y1 ~ ...`,
  `mu2 = y2 ~ ...`). `mvbind()` is only shorthand for identical location
  formulas.

## Design Rules

1. Do not add a new family without simulation tests.
2. Do not add user-facing functions without roxygen2 documentation.
3. Do not change formula grammar without updating
   `docs/design/01-formula-grammar.md`.
4. Do not change likelihood parameterization without updating
   `docs/design/03-likelihoods.md`.
5. Do not add random effects before fixed-effect likelihoods are tested.
6. Keep pull requests small and focused.
7. Every meaningful change should update `docs/dev-log/check-log.md`.
8. Every completed task or phase should create an after-task or after-phase
   report following `docs/design/10-after-task-protocol.md`.
9. If code is ported from `gllvmTMB` or another package, document provenance in
   `inst/COPYRIGHTS` before treating the change as complete.

## Standard Commands

```r
devtools::document()
devtools::test()
devtools::check()
pkgdown::check_pkgdown()
```

## Definition of Done

A feature is done only when implementation, tests, documentation, examples,
check logs, after-task notes, and review are all present.

## Multi-Agent Collaboration

Codex and Claude Code may both contribute to this repository. All agent work
must follow the same project rules:

- preserve the univariate/bivariate scope;
- avoid unreviewed likelihood or formula-grammar changes;
- update design docs when architecture changes;
- add tests with implementation;
- do not revert changes made by another agent or human unless explicitly asked;
- prefer small, reviewable commits or pull requests.

When an agent hands work to another agent, leave enough context in
`docs/dev-log/check-log.md` or the relevant issue/PR for the next agent to
continue without rediscovering the whole problem.

Claude Code should read this file first. It should not introduce a parallel
agent configuration system inside the package unless the project owner asks for
one.

## pkgdown Policy

The pkgdown site is a first-class project artifact. User-facing features should
include reference documentation and, when substantial, an article or tutorial.
Keep `_pkgdown.yml` synchronized with exported functions and vignettes.

## Hermes Policy

Hermes is optional external lab orchestration. It is not a package dependency
and should not be installed inside this repository or required for development.
