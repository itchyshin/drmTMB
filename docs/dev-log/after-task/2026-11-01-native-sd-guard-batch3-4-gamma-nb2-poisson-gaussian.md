## 1. Goal

Admit or record, natively, the next bounded slices from the ranked priority-family queue: Gamma crossed intercepts, NB2 relmat and phylo slope-only SD, Poisson iid plus structured intercept, Gaussian mu plus sigma joint random-effect SDs; and record test evidence for routes that already worked (Gamma relmat plus iid, Binomial animal plus spatial under probit and cloglog). Interval coverage remains deferred.

## 2. Implemented

Guard edits in `R/drmTMB.R` only; no C++ change:
- Gamma: the one-endpoint pre-guard now allows scalar ordinary `mu` intercept/slope terms on different groups (crossed), not only one group.
- NB2: `slope_only_structured_mu_types` is now `c("animal", "relmat", "phylo")`.
- Gaussian: the sigma-endpoint SD guard no longer refuses mu random effects or mu SD formulas; it still refuses structured terms, missing data, aggregation and non-scalar sigma terms. Its message was reworded to match.
- Poisson: new `poisson_iid_structured` predicate (one unlabelled ordinary intercept plus one unlabelled q1 relmat/animal/phylo intercept, no `zi`, complete response). It relaxes three guards: the structured-SD requirement of no ordinary `sd()`, the structured-plus-ordinary type list, and the ordinary-SD no-structured rule. A probe extraction of the ordinary terms runs before the first guard.

## 3a. Decisions and Rejected Alternatives

- Public base-model widening, accepted: NB2 `phylo(0 + x | g)` and `relmat(0 + x | g)` slope-only fit without any `sd()`, as the Poisson slope-only widening already did; Poisson relmat/animal/phylo `(1 | id)` plus one ordinary `(1 | site)` intercept fits without `sd()`. Both are limited to the stated shapes.
- Held, not applied: NB2 sigma-endpoint phylogenetic SD. It needs three edits, admits a new public base route `sigma ~ phylo(1 | sp)`, and touches a function shared with the Gaussian path. Needs a decision.
- Not applied: NB2 spatial slope-only; marginal `simulate(re.form = NA)` for NB2 slope SD (the whitelist near `R/methods.R:7078` excludes NB2).
- Gamma iid plus animal/phylo/spatial stays refused; Gamma relmat plus iid already worked.

## 4. Files Touched

- `R/drmTMB.R`
- New tests: `test-gamma-batch3-sd-regression.R`, `test-gamma-batch4-sd-regression.R`, `test-nbinom2-phylo-relmat-slope-sd-regression.R`, `test-poisson-iid-structured-sd-regression.R`, `test-gaussian-mu-sigma-joint-sd.R`, `test-binomial-batch3-sd-regression.R`, `test-binomial-batch4-sd-regression.R`
- Edited existing tests (stale refusals these edits lifted): `test-nbinom2-location-scale.R` (phylo slope-only now assembles), `test-poisson-mean.R` (ordinary plus phylo intercept now assembles), `test-nongaussian-structured-boundary.R` (Poisson phylo slope-only now assembles), `test-poisson-slope-sd-assembly.R` (same-group now builds)

The worktree has extensive other in-flight changes in `R/drmTMB.R`; this report does not claim them.

## 5. Checks Run

- New test files pass: Gamma crossed 21, Gamma relmat plus iid 30, NB2 phylo and relmat slope 38, Poisson iid plus structured 170, Gaussian mu plus sigma joint 29, Binomial pairs 90 and 88. The last two and the Gamma relmat file needed no source edit.
- Oracles: dense Laplace oracle at fitted values for Gamma, NB2, Poisson and Gaussian joint (sensitivity checked by reversing SDs in the Poisson file); Binomial uses a dense Laplace oracle independent of the Ainv and pedigree code. NB2 and Gamma same-group have no oracle, only constant-SD equivalence and prediction identity.
- Neighbours rerun after the edits: Poisson structured set, `count-structured-mu`, Gaussian sigma SD files, `nbinom2-location-scale`, `nbinom2-animal-slope-sd-regression`: pass except the failures listed below.
- Not run: Julia, `devtools::document()`, package check, vignettes, docs and NEWS entries for batches 3 and 4 (not written).

## 5b. Failures NOT caused by these edits

- `test-nbinom2-location-scale.R:314`, `:338` (NB2 sigma random-slope refusal wording; `validate_nbinom2_sigma_random_terms` untouched).
- `test-nongaussian-structured-boundary.R:297` (Beta relmat refusal; Beta untouched).
- Earlier-listed Poisson and beta-binomial fences in the milestone file.

## 6. Not Claimed

No Julia parity, no calibration, no ledger rows promoted, nothing committed. NB2 marginal simulation for slope SD refuses by design. Recovery is single fixtures with loose bands. Receipt linking is separate and unreviewed.
