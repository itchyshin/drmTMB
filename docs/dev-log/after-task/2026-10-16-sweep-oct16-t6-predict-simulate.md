# 2026-10-16: sweep-oct16 lane t6, `predict()` and `simulate()` methods

Reader: the maintainer triaging the 16 Oct sweep, and the next agent touching
`predict()`, `simulate()`, `fitted()` or the Julia bridge's prediction path.

## What changed

Nothing in package code. The lane adds test material under `sweep-oct16/t6/`,
which `.Rbuildignore` keeps out of the build:

- seeded data for 14 families × {fixed, `(1 | g)`};
- `SPEC_t6.md`;
- the R, Julia and bridge harnesses;
- per-finding repros and their logs;
- `RECEIPT_t6.md`.

## What was found

The full table is in `sweep-oct16/t6/RECEIPT_t6.md`.

- **drmTMB native:** passes every SPEC test (P1–P8) in all 28 cells.
  - Docs: in-sample quantile, exceedance and quantile residuals on `(1 | g)` fits are conditional on the modes, while the Rd says population level (#1568).
  - Executed confirmation of #1536 (`predict(se.fit =)` and `simulate(newdata =)` silently ignored).
- **Bridge (`engine = "julia"`):**
  - `fitted()` is DRModels.jl's value, not `?fitted.drmTMB`'s (#1566);
  - Gaussian `(1 | g)` with a factor fixed effect is refused (#1567);
  - the admission docs disagree with the registry (#1569);
  - there is no `simulate()` / `predict_parameters()` method (#1570);
  - #1551 also affects nbinom2, beta and binomial.
- **DRModels.jl:** four issues and five comments. See the receipt. Two of these are silent wrong answers:
  - the response-scale inverse links (DRModels.jl#1120);
  - crossed-route LogNormal `simulate()` (comment on DRModels.jl#1102).

## Checks run

- Every filed claim was re-run from a standalone repro in a fresh process at
  both pins (drmTMB `ca3ddefa`, DRModels.jl `f71b2923`).
- An adversarial refuter pass then moved several candidates from new issues to
  comments.
- Environment: R 4.3.3 from Ubuntu binaries, and Julia 1.12.7 from conda-forge.
  CRAN and the Julia package servers are blocked in this container.

## Follow-ups for the owner

- Decide the in-sample convention for distributional outputs on random-effect
  fits (#1568, which mirrors DRModels.jl#1101).
- Decide whether bridge `fitted()` should follow drmTMB's contract (#1566).
- Cross-engine SE parity needs about a 1e-5 relative bar, because TMB's
  `sdreport` Hessian is finite-difference. 1e-8 is too tight.
