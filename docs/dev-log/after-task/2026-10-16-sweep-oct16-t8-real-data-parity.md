# After Task: sweep-oct16 t8 real-data parity (15 unused datasets)

Reader: the next drmTMB/DRModels.jl agent who has to post the t8 GitHub comments or extend the Oct real-data catalogue.

## Goal

Fit the natural location-scale model for 15 datasets that the 3 Oct sweep (#1463) did not use, on pins drmTMB `ca3ddef` and DRModels.jl `f71b292`, and score logLik / coefficients / SEs against a 1e-4 / 1e-4 relative / 1e-3 bar. File GitHub issues as findings appear. Commit the receipt on `sweep-oct16/t8` only. No PR, no merge, no push to `main`.

## Implemented

No package source change. The lane added a timed harness under `sweep-oct16/t8/` (prepare, Julia fit, compare, `run_case.sh`) and scored 15 cells. 13 PASS. Owls fails because Julia still estimates `offset()` as a free coefficient (#1097). GasolineYield fails because Julia stops 0.017 nats short of the drmTMB/glmmTMB Beta optimum and prints SEs while not converged.

## Mathematical Contract

Unchanged. Laplace vs GHQ: Julia `:Laplace` was requested only where the pin implements it (NB2/Binomial/Poisson/Gamma/Beta ordinary `(1|g)`). Gaussian mean RE uses Woodbury (equals TMB Laplace). BetaBinomial RE has no Laplace route; on cbpp the herd SD collapsed (~1e-8) so default GHQ matched drmTMB to 4.5e-10. `rho12` and `sigma` naming were not touched.

## Files Changed

`sweep-oct16/t8/**` (harness, prepared CSVs, fit JSON, `results.csv`, `RECEIPT_t8.md`, postable issue bodies). `docs/dev-log/after-task/2026-10-16-sweep-oct16-t8-real-data-parity.md`. `docs/dev-log/check-log.md` (this lane's entry).

## Checks Run

Per-cell `timeout(1)` fits: no hang, no exit 124. `results.csv` vs pass bar as in the receipt. GitHub MCP `add_issue_comment` and `issue_write` create returned 403 (PAT). `gh issue comment` as the Cursor GitHub App returned 403 (integration). Comment/issue bodies were therefore written to `sweep-oct16/t8/issues/` instead of the tracker. No `devtools::test()` / `devtools::check()`: no R/ or src/ edit.

## Tests Of The Tests

The two FAIL_BAR cells were re-checked as standalone fits, not harness artefacts. Owls: Julia `coeftable` contains `mu: offset(logBroodSize) = 0.755` while drmTMB/glmmTMB hold the offset at 1 and agree to 2e-11 in logLik. GasolineYield: drmTMB matches glmmTMB to 2.9e-10; Julia is 0.0168 short. An earlier BOTH_FAIL on GasolineYield was the harness (unexported `betareg` object, then numeric `batch`); after `data()` + `g`-prefix both engines fit 21 coefficients.

## Consistency Audit

No package docs, NEWS, or formula-grammar files were edited. Patterns `meta_gaussian|tau ~|rho ~` were not introduced. `graft build` was not run (no indexed source change).

## GitHub Issue Maintenance

Intended comments on DRModels.jl#1097, drmTMB#1451, DRModels.jl#940, DRModels.jl#943, drmTMB#1554, and one new DRModels.jl issue for GasolineYield. Write API 403 blocked posting. Bodies: `sweep-oct16/t8/issues/`. Known issues not re-filed: #1451, #1097, #938, #943, #1452, #1470, #1478, #1554.

## What Did Not Go Smoothly

GitHub issue write from this cloud task has no usable token (MCP PAT and Cursor App both 403), so the standing "file as you go" rule could not land on GitHub. The first Owls ZI+RE Julia probe used `marginal = :Laplace` and reported the zi-Laplace refuse rather than the ZI+RE gap; a default-integrator retry recovered the #940 message. Digit-only factors need a `g` prefix or CSV.jl silently changes the model.

## Team Learning

A real-data parity harness has to freeze factor storage before CSV.jl sees it, write JSON at full precision, and treat Julia `:Laplace` as a per-family capability, not a global switch. Issue filing needs a token with `issues:write` before the next sweep lane, or the receipt-only fallback repeats.

## Known Limitations

ZI+RE still refused (#1451 / #940). Julia `offset()` still a free coefficient (#1097). BetaBinomial and Gaussian-mean `:Laplace` still refused (#943 neighbour). GasolineYield is weakly identified; drmTMB is honest about the Hessian, Julia is not, and they do not share an optimum.

## Next Actions

Post the six bodies in `sweep-oct16/t8/issues/` once a token can write issues. Do not open a PR for this lane unless asked. Do not treat GasolineYield as a collinear-sigma duplicate of #1470.
