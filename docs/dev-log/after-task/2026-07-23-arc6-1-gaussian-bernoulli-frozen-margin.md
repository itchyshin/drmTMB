# After Task: Arc 6.1 Gaussian × Bernoulli frozen-margin association

## 1. Goal

Implement the approved first Arc 6.1 proof: an explicit, post-fit
Gaussian-copula latent-normal association between two frozen fixed-effect
drmTMB margins, one Gaussian and one literal Bernoulli, while preserving the
separate meanings of `rho12` and `corpair()`.

## 2. Implemented

`associate_pairs()` now constructs a `drm_pair_association` object from two
identical complete analysis data sets. Callers must declare both
`kernel = latent_normal()` and `association = ~ 1`. It snapshots the margins,
their response-scale predictions, row provenance, and fingerprints; it never
refits either margin. The only admitted pair is Gaussian × literal 0/1 logit
Bernoulli, in either input order. `association()` returns a point estimate of
latent-normal `eta` only when the optimizer diagnostics support a unique
interior or flagged near-boundary solution.

## 3a. Decisions and Rejected Alternatives

The public direction is a composable post-fit association object, not a new
bespoke `biv_*` family. Arc 6.1 admits only the reviewed Gaussian × Bernoulli
slice; direct Bernoulli odds-ratio and shared-intensity count likelihoods stay
independent later lanes. Gaussian × NB2 remains queued behind a fresh owner
approval and symbolic review.

### Mathematical Contract

The implemented likelihood and its symbol-to-code table are in
`docs/design/231-arc6-1-gaussian-bernoulli-contract.md`. The production kernel
uses the Gaussian density times the conditional latent-normal Bernoulli
probability. The targeted tests compare it with an independent numerical
integration of the bivariate normal density, test the `eta = 0` product-margin
limit, and reproduce the frozen-margin simulator deterministically.

## 4. Files Touched

The new implementation is `R/associate-pairs.R`, with generated Rd files and
NAMESPACE registrations. The focused tests and snapshots are under
`tests/testthat/`. The public development boundary is synchronized in NEWS,
the formula grammar, likelihood design note, cross-family vignette, known
limitations, and Arc 6 design/decision documents.

## 5. Checks Run

- `devtools::document()` completed after each roxygen change.
- `devtools::test(filter = "^associate-pairs-gaussian-bernoulli$")` passed
  38 assertions, 0 failures, 0 warnings, 0 skips.
- `git diff --check` passed.
- `devtools::check()` built, installed, loaded with stated dependencies,
  checked namespace/S3/Rd/code, and ran examples before it was stopped at the
  repository's long legacy simulation-oriented test phase. It first exposed
  and then, on rerun, cleared imports for `stats::quantile()` and
  `stats::fitted()`. The no-vignette rerun also retained existing repository
  spelling/vignette comparison artifacts; they are unrelated to Arc 6.1.
- The full suite was deliberately not allowed to become a substitute for the
  separately owner-approved smoke or recovery gate.

## 6. Tests of the Tests

The new oracle is independent of the production conditional-probability helper:
it integrates the bivariate normal density directly. The suite also checks
malformed margins, nonidentical rows, literal-binomial trial rejection,
weights, offsets, REML, random/structured terms, incomplete rows, explicit
argument requirements, boundary diagnostics, unsupported extractor errors,
and no-newdata prediction.

## 7a. Issue Ledger

Read-only search of open issues found no issue specific to this frozen-margin
association slice. Existing issues #806, #499, #531, and #802 concern Julia,
bridge, existing Gaussian correlation syntax, or coverage and were left
unchanged; no issue was opened or edited.

## 8. Consistency Audit

The status inventory was searched with:

```sh
rg -n 'associate_pairs|latent_normal|mixed-family rho12|cross-family.*implemented|corpair\\(\\)' README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml vignettes/cross-family.Rmd
rg -n 'biv_pair|biv_dip_poisson|biv_bernoulli|rho_latent' README.md ROADMAP.md NEWS.md docs vignettes R
```

The historical `biv_pair()` proposals remain deliberately marked superseded
inside Arc 6 records. Existing Julia `rho_latent` code is a separate deferred
surface; Arc 6.1 does not claim or alter it. `corpair()` remains the formula
marker and `corpairs()` the extractor throughout the new material.

## 9. What Did Not Go Smoothly

An accidental `air format .` spill touched 247 unrelated files. With owner
approval, those exact paths were restored while retaining the Arc 6.1 edits.
The first full check also found two namespace imports absent in a minimal load;
both are now generated from roxygen and verified before the long suite phase.
Review further caught hidden defaults, incomplete optimizer acceptance, and
method-boundary gaps before closeout.

## 10. Known Residuals

The broad legacy test suite was not completed because its simulation-oriented
phase is outside the owner-approved Arc 6.1 verification boundary. The local
check therefore proves build, namespace, documentation, and examples, while
the targeted suite proves the new behavior. A separately approved smoke is the
next evidence gate.

## 11. Team Learning

For one-dimensional post-fit association optimization, multistart agreement
must compare both objective values and fitted parameter values. A boundary
diagnostic is not enough when symmetric or otherwise distinct maxima can have
the same objective. The new independent bivariate-density oracle is retained
as the regression guard.

## 12. Cross-Product Coverage

This is post-0.6 development only and is un-smoked. It has no standard errors,
intervals, profiles, coverage, capability tier, or generic mixed-family claim.
Gaussian × NB2 is queued only after a new symbolic review and owner approval.
No smoke, recovery campaign, Julia, meta_V, or CRAN work occurred.

This arc covers only fixed-effect ML Gaussian × literal-Bernoulli complete
pairs, the frozen fitted rows, and intercept-only `eta`. It does NOT cover
REML, penalties, Julia/other engines, missing or partial pairs, aggregation,
weights, offsets, `mi()`, `meta_V()`, random/phylogenetic/structured effects,
association covariates, uncertainty, prediction on new rows, any NB2/count
margin, direct exact binary/count kernels, or capability-ledger cells.

## Next Actions

The owner must decide whether to approve a narrowly specified Arc 6.1 smoke.
That decision does not authorize recovery, capability promotion, Gaussian ×
NB2, or any other pair class. If no smoke is approved, retain this exact
development implementation and its point-estimate-only ceiling.
