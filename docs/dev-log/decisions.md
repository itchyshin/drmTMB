# Design Decisions

## 2026-05-06: Build From Scratch

Decision: build `drmTMB` from scratch on TMB rather than forking `glmmTMB`,
`sdmTMB`, or `brms`.

Rationale: the package grammar should be organized around distributional
parameters from day one, especially bivariate `rho12 ~ predictors`.

## 2026-05-06: Keep Hermes Outside the Repo

Decision: Hermes may be useful as optional external lab orchestration, but it is
not project infrastructure and is not required for developing `drmTMB`.

Rationale: reproducibility should depend on R package tooling, GitHub, CI, and
Codex-compatible project-local files.
