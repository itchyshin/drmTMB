## 1. Goal

Admit the next bounded native coefficient-SD slices after the first guard batch: Poisson slope-only SD on phylogenetic and relmat providers, Poisson additive and ordinary same-group SD pairs, and NB2 and Gamma same-group independent intercept/slope SD pairs. Add test-only evidence that the Binomial animal probit and cloglog provider pairs already route. Interval coverage remains deferred.

## 2. Implemented

Guard edits in `R/drmTMB.R` only; no C++ change.
- Poisson: `slope_only_structured_mu_types` is now `c("spatial", "animal", "relmat", "phylo")`.
- Poisson: `drm_poisson_sd_mu_targets` passes `allow_independent_same_group = TRUE`. Its mixed-slope fence now refuses only slope terms that span more than one group.
- NB2 and Gamma `mu` calls pass `allow_independent_same_group = TRUE`.
- Gamma: the one-endpoint pre-guard allows a same-group independent intercept/slope pair.
- Binomial animal probit and cloglog provider pairs: no source change. Routes already worked; the new file is test-only.

## 3a. Decisions

Missing implementation is not non-identifiability, so these routes were admitted rather than fenced. No tolerance was loosened to make a test pass. Source was edited by one writer only; the test files were added without touching source. NB2 and Gamma same-group have no exact oracle, so the only evidence for them is constant-SD equivalence and prediction identity. Gamma recovery is weak at 50 groups, so I do not claim recovery for it.

## 4. Files Touched

- `R/drmTMB.R`
- New tests: `test-poisson-phylo-relmat-slope-sd-regression.R`, `test-poisson-additive-ordinary-sd-regression.R`, `test-nbinom2-gamma-same-group-sd-regression.R`, `test-binomial-animal-provider-pairs-nonlogit-sd.R`
- Edited test: `test-poisson-mean.R` (the phylo slope-only refusal assertion now asserts that the spec assembles)

The worktree has extensive other in-flight changes in `R/drmTMB.R`; this report does not claim them.

## 5. Checks Run

- New tests pass, as reported to this report's author when the batch was assembled: Poisson phylo/relmat slope 38, Poisson additive/ordinary 33, NB2+Gamma same-group 34, Binomial animal provider pairs 94. This report's author confirmed only that all four files and the edited `test-poisson-mean.R` exist; none was re-run here.
- Not run: Julia parity, `devtools::document()`, package check, vignettes.
- Wide regression status across the neighbouring test files: unknown to this report. The earlier batch recorded stale-fence failures in the shared dirty tree; whether they remain is not rechecked here.

## 6. Not Claimed

No Julia parity, no calibration, no interval coverage, no receipts, no ledger rows promoted, nothing committed. NB2 and Gamma same-group have no exact oracle. Gamma recovery is weak at 50 groups. Poisson additive and phylo/relmat slope evidence is constant-SD equivalence and prediction identity unless a test states an oracle.
