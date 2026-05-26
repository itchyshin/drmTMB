# After Task: Fixed-Effect Zero-One Beta Source Slice

## Goal

Land the first fitted `zero_one_beta()` source slice for continuous proportions
on `[0, 1]` when exact zeroes and ones are structural outcomes, not denominator
counts.

## Implemented

`zero_one_beta()` now fits one-response fixed-effect models with separate
formulas for `mu`, `sigma`, `zoi`, and `coi`. `mu` and `sigma` describe the
interior beta component; `zoi` is the probability of an exact boundary outcome;
and `coi` is the probability that a boundary outcome is exactly one.

The user-facing surface includes the exported family constructor, TMB model
type `15`, coefficient extraction for all four distributional parameters,
response-scale prediction for `zoi` and `coi`, unconditional `fitted()` values,
response and Pearson residuals, simulation, Wald fixed-effect intervals, Rd
documentation, pkgdown reference navigation, NEWS, README, roadmap, design
notes, and the proportion tutorial.

## Mathematical Contract

For observation `i`,

```text
logit(mu_i) = eta_mu_i
log(sigma_i) = eta_sigma_i
logit(zoi_i) = eta_zoi_i
logit(coi_i) = eta_coi_i
phi_i = 1 / sigma_i^2
Pr(Y_i = 0) = zoi_i * (1 - coi_i)
Pr(Y_i = 1) = zoi_i * coi_i
Pr(0 < Y_i < 1) = 1 - zoi_i
Y_i | 0 < Y_i < 1 ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
E[Y_i] = (1 - zoi_i) * mu_i + zoi_i * coi_i
```

`predict(fit, dpar = "mu")` returns the interior beta mean. `fitted(fit)`
returns the unconditional response mean including boundary mass.

## Files Changed

Core implementation changed `R/family.R`, `R/drmTMB.R`, `R/methods.R`,
`R/predict-parameters.R`, and `src/drmTMB.cpp`. Public documentation and
generated files changed `NAMESPACE`, `man/zero_one_beta.Rd`, method Rd files,
`README.md`, `NEWS.md`, `ROADMAP.md`, `_pkgdown.yml`, and the proportion,
formula-grammar, model-map, distribution-family, and implementation-map
vignettes. Design status moved in the family registry, likelihood contract,
formula grammar, family-link contract, pre-simulation matrix, validation-debt
register, worked-example inventory, simulation programme, supported
non-Gaussian evidence goal, and Slice D3/core-family implementation notes.

## Checks Run

```sh
Rscript tools/codex-checkpoint.R --goal "resume zero-one beta slice after compacted validation" --next "inspect git status, check-log, after-task evidence, then commit/push/PR"
Rscript -e "devtools::test(filter = '^(zero-one-beta|family-link-contract)$', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check()"
rg -n "zero_one_beta\\(\\).*random|zero-one beta.*random|zoi.*random|coi.*random|fixed-effect only for .*zero-one|exact 0/1 boundary mass.*planned|zoi/coi.*planned|zero-one.*planned|zero_one_beta.*planned" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man -g '!*.html'
gh issue view 57 --repo itchyshin/drmTMB --json number,title,state,url,comments --jq '{number,title,state,url,comments: [.comments[] | {author:.author.login,createdAt,body}]}'
```

The resumed focused tests passed. The stale-wording scan returned current
claims and planned-neighbour boundaries rather than contradictions. The
recovery checkpoint was created because the previous stream compacted during
closeout; it is ignored under `docs/dev-log/recovery-checkpoints/`.
`pkgdown::check_pkgdown()` reported no problems. `devtools::check()` completed
in 6m 1.9s with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

`tests/testthat/test-zero-one-beta.R` checks parameter recovery from simulated
data, verifies the TMB log-likelihood against an independent mixture
calculation, checks weighted likelihood handling, verifies the unconditional
mean used by `fitted()` and residuals, tests deterministic simulation output,
fits pure-interior and one-sided-boundary cases, and exercises malformed or
unsupported neighbours such as `beta()` with exact endpoints,
`cbind(success, failure)`, random effects in `mu`, `sigma`, `zoi`, and `coi`,
`sd(id) ~ 1`, `meta_V()`, out-of-range responses, all-boundary responses, and
`mvbind()`.

`tests/testthat/test-family-link-contract.R` checks that `zero_one_beta()` uses
`logit` links for `mu`, `zoi`, and `coi`, a `log` link for `sigma`, and the
expected inverse-link behaviour.

## Consistency Audit

Boole checked that `zero_one_beta()` stays within the one-formula-per-parameter
grammar and does not borrow denominator syntax from `beta_binomial()`. Gauss
checked that the TMB likelihood uses stable log probabilities for the discrete
boundary masses and the same beta mean-scale contract as `beta()`. Noether
checked that the equations in `docs/design/03-likelihoods.md`,
`docs/design/02-family-registry.md`, `docs/design/19-family-link-contract.md`,
and `vignettes/proportion-beta-binomial.Rmd` match the implementation.

The exact stale-wording scan used during resumed closeout was:

```sh
rg -n "zero_one_beta\\(\\).*random|zero-one beta.*random|zoi.*random|coi.*random|fixed-effect only for .*zero-one|exact 0/1 boundary mass.*planned|zoi/coi.*planned|zero-one.*planned|zero_one_beta.*planned" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man -g '!*.html'
```

The hits were either current fitted fixed-effect claims, current unsupported
neighbour boundaries, or older Slice D3 design-gate context that is now
superseded by the source slice wording.

## GitHub Issue Maintenance

Issue #57 is the overlapping proportion/tutorial gate. It already has a local
zero-one beta status comment for this branch:
https://github.com/itchyshin/drmTMB/issues/57#issuecomment-4539687125.

The issue remains open because this source slice does not close the broader
non-Gaussian tutorial gate, a fuller reader-facing mixed-model proportion
example, or the later ADEMP/artifact lane for zero-one beta.

## What Did Not Go Smoothly

The previous run compacted after local `pkgdown::check_pkgdown()` and
`devtools::check()` had passed, before the check-log and after-task evidence
were committed. The resumed run therefore started by writing a recovery
checkpoint and rebuilding the closeout evidence from repository state, recent
issue comments, focused validation, and stale-wording scans.

## Team Learning

Ada kept the slice to one fitted family and one source-test surface. Boole,
Gauss, and Noether handled API, likelihood, and equation consistency. Curie
and Fisher kept deterministic recovery and likelihood checks separate from
future broad simulation claims. Pat and Darwin watched the proportion tutorial
language so applied readers can distinguish strict beta, denominator-aware
beta-binomial, and structural boundary mass. Grace closed local package
validation and will watch GitHub Actions. Rose recorded the closeout gap so
future slices do not stop between local green checks and the publish loop.

No spawned subagents were running.

## Known Limitations

The first `zero_one_beta()` slice is fixed-effect only. Random effects in
`mu`, `sigma`, `zoi`, or `coi`, labelled covariance blocks, structured effects,
known covariance, denominator syntax, bivariate or mixed bounded-response
models, and broad simulation artifacts remain planned or unsupported.

## Next Actions

Commit this source slice, push the branch, open or update the pull request,
watch GitHub Actions, and merge or wait before starting another slice.
