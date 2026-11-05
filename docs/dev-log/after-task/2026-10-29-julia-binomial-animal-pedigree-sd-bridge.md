# After Task: Julia Binomial Animal Pedigree SD Bridge

## Goal

Allow the Julia engine to fit predictor-dependent Bernoulli animal-intercept SD models from pedigree input, with consistent group ordering and marginal simulation.

## Implemented

The bridge converts the pedigree to the existing additive relationship covariance, then aligns and subsets it to the observed animal groups before passing it to DRM.jl. The Julia Binomial simulator now admits animal-intercept-only SD fits and draws from that saved covariance using the fitted group SDs.

## Mathematical Contract

For observed animals, the latent field has covariance `D A_obs D`, where `A_obs` is the observed-animal principal submatrix of the full pedigree relationship matrix and `D` contains predictor-dependent SDs. This marginalizes unobserved ancestors. The Bernoulli SD remains on the link scale.

## Files Changed

- `R/julia-bridge.R`: pedigree conversion and logit/probit/cloglog admission.
- `R/julia-simulate.R`: animal-intercept SD simulation admission.
- `tests/testthat/test-julia-binomial-animal-pedigree-sd-bridge.R`: independent pedigree fixtures and bridge/recovery/output checks.
- `vignettes/formula-grammar.Rmd`: bounded Julia pedigree-support status update.
- `docs/design/01-formula-grammar.md`: structured-animal support and parity boundary.
- `news/binomial-animal-pedigree-sd-bridge.md`: user-facing scope note.
- `docs/dev-log/check-log.md`: concise check receipt.

The drmTMB candidate started at `425bee81572c625a634b2b083050c5c57c1dc1f1`; the paired DRM.jl candidate was `70dbf564eb670144c63c08f61ea099084d95add2`. Both worktrees contain other in-progress changes; this report covers only the listed slice.

Candidate SHA-256 values at this check: `R/julia-bridge.R` `f39895240d7196f937e2def0b82fb16c833f0ec9ac5b63532202a2d781d78765`; `R/julia-simulate.R` `3d2973bb08e719f51471fb8e15fcfcba1538f4ad29e83889304d3b57d9bb110c`; the focused test `4de3444aa08f0ff64f741b2429f064d239f26292750a83829cc9d3935c8602b7`; `vignettes/formula-grammar.Rmd` `30721a40acc9d7f9b51013e2f01926ed6247a87a9abffad7f4b2b047709ab7e7`; and `docs/design/01-formula-grammar.md` `73489588e8dd378bd88d9972c550a86e0dccaa6d157b15a74ff7f7c9df0e895c`.

## Checks Run

`env PATH="/Users/z3437171/.juliaup/bin:$PATH" NOT_CRAN=true JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' Rscript -e 'pkgload::load_all("."); testthat::test_file("tests/testthat/test-julia-binomial-animal-pedigree-sd-bridge.R", reporter = "summary")'` passed with a live Julia 1.10.0 bridge run. The fixed-seed test covers logit, probit, and cloglog; native/Julia SD-slope recovery, matching likelihoods, observed-group covariance order, fitted group SD predictions, and marginal binary simulation.

`rmarkdown::render("vignettes/formula-grammar.Rmd", output_file = "formula-grammar-20261029.html", output_dir = tempdir(), quiet = TRUE)` completed. Pandoc reported the existing `--mathjax` deprecation warning. `git diff --check` passed for the modified tracked files. The focused test passed after its final code changes; no full package suite, site build, or interval calibration ran.

Recovery checkpoint: `docs/dev-log/recovery-checkpoints/2026-10-29-074906-codex-checkpoint.md`.

## Tests Of The Tests

Before the simulator admission change, the new test failed with the simulator's unsupported-route error for an animal intercept. It passed after that narrow admission was added. The test also checks that probit and cloglog admission accepts the pedigree route and that the payload covariance matches the observed-animal submatrix after group reordering.

## Consistency Audit

The code, simulator, test, formula-grammar row, and design-grammar row use the same additive covariance and group ordering. The user-facing note states the family/link boundary. The exact status scans were `rg -n 'full.*rejected|block.*rejected|only diagonal|planned.*implemented|animal-model.*direct-SD' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/animal-models.Rmd` and `rg -n --max-columns 240 --max-columns-preview 'Binomial animal.*pedigree|pedigree input.*animal|animal.*predictor-dependent SD|General pedigree marshalling' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/animal-models.Rmd _pkgdown.yml`. The first scan found stale wording in the formula-grammar row, which this change narrowed. The second scan found the Gaussian-only public design row, which now records this exact Julia Binomial route. The required-row universe remains open; its direct-SD claim column is not promoted here. Shared animal help and the broader capability inventory remain to be reconciled after checking their active documentation lane. `graft` was unavailable in this shell, so the source graph was not refreshed. No coverage claim is made.

## GitHub Issue Maintenance

No issue was updated or closed as part of this bounded slice. Check for an existing issue before expanding the route to another provider or random-effect type.

## What Did Not Go Smoothly

The first recovery fixture had too few independent families for the fixed recovery bound under one link. Increasing the number of families yielded a passing all-link check. Julia was not initially on the test shell path; the rerun set the Juliaup path explicitly. The first standalone test invocation used the defunct `devtools::test_file()` wrapper and was replaced by `testthat::test_file()`.

## Team Learning

For a new structured bridge route, test simulation as well as fitting and prediction. A payload can contain the correct covariance while a simulator's independent route gate still refuses the model.

## Known Limitations

This establishes one Bernoulli family, one animal intercept, pedigree input, and three links in the candidate R/Julia bridge. It does not establish coverage calibration, interval validity, every animal layout, other provider parity, broader distribution support, or release readiness. Coverage validation remains deferred by the user's decision.

## Next Actions

Reconcile the narrow support note with the shared animal help and capability inventory after checking their active documentation lane. Then take the next uncovered Bernoulli structured-SD row from the required universe.
