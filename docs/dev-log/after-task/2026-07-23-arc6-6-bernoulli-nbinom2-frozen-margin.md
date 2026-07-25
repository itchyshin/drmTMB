# After Task: Arc 6.6 Bernoulli × ordinary NB2 frozen-margin association

## 1. Goal

Add one fixed-effect, complete-pair Bernoulli × ordinary-NB2 latent-normal
association adapter without changing either fitted margin or making an
inference or capability claim.

## 2. Implemented

`associate_pairs()` accepts literal logit-Bernoulli and ordinary log-mean,
log-scale NB2 fits in either order. It freezes both margins and estimates only
intercept-only latent-normal `eta`. A private versioned descriptor identifies
the pair class; it does not change the public constructor or object class.

## 3. Mathematical Contract

The binary state and NB2 CDF jump form a bivariate-normal rectangle. Production
uses a conditional one-dimensional integral, upper-tail Bernoulli thresholds,
tail-stable NB2 endpoints, log-space inner differences, and a mixed
absolute/relative quadrature-error rule. Unresolved endpoint or integration
rows return diagnostics and withhold `eta`; no clipping or probability flooring
is used. [Design 236](../../design/236-arc6-6-bernoulli-nbinom2-contract.md)
records the exact contract.

## 3a. Decisions and Rejected Alternatives

The slice retains the frozen-margin latent-normal adapter instead of a direct
binary-count kernel. It uses upper-tail Bernoulli thresholds and a direct
conditional integral rather than `qnorm(1 - p)`, four-corner subtraction,
probability flooring, or clipping. Recovery and all inference routes remain
separate owner-gated work.

## 4. Files Touched

- `R/associate-pairs.R` and regenerated `man/associate_pairs.Rd`.
- `tests/testthat/test-associate-pairs-bernoulli-nb2.R`.
- Design 236, the series overview, formula grammar, cross-family vignette,
  a new non-Gaussian same-family article, NEWS, limitations, and check log.

## 5. Checks Run

- `devtools::document()` regenerated the reference Rd file.
- Focused Arc 6.1/6.2/6.6 suite: 121 pass, 0 fail/warn/skip.
- `git diff --check` passed.
- Hosted package CI is recorded on PR #822; its terminal result is required
  before merge and is not claimed here.

## 6. Tests of the Tests

The suite compares production rectangles to an independent `mvtnorm` oracle,
tests the zero-association product identity, response-order/simulation symmetry,
zero and rare/high-tail cells, and deliberately rejected quadrature/endpoint
failures. The endpoint regression verifies a structured
`boundary_unresolved` result instead of an abort.

## 7a. Issue Ledger

`gh issue list --state open --search 'associate pairs OR Bernoulli NB2 OR Arc 6'`
found no overlapping open issue. No issue was created, changed, or closed.

## 8. Consistency Audit

Ran `rg -n -i 'associate_pairs|bernoulli.*nbinom2|nbinom2.*bernoulli|Arc 6\\.6'
README.md ROADMAP.md NEWS.md docs vignettes _pkgdown.yml R tests` and
`rg -n 'only Gaussian.*(Bernoulli|NB2)|6\\.6.*later|first two Arc 6|Gaussian × literal-Bernoulli'
README.md ROADMAP.md NEWS.md docs vignettes _pkgdown.yml R tests`.
NEWS, the cross-family vignette, new same-family article, limitations, grammar,
overview, Roxygen, and the new design contract now state the third pair.
Historical reports retain their then-correct two-pair wording.

## 9. What Did Not Go Smoothly

Initial code used an unstable `qnorm(1-p)` threshold and accepted merely finite
quadrature errors. Review also exposed missing row diagnostics and a post-fit
endpoint abort. Each was repaired with a regression test; the final contract is
stricter rather than silently treating rare tails as ordinary successes.

## 10. Known Residuals

This is construction-level evidence only. Recovery, intervals, coverage,
standard errors, association slopes, random or structured effects, partial
pairs, offsets, weights, missingness, `mi()`, `meta_V()`, REML, Julia, and
generic binary-count support remain outside the contract. Hosted CI and review
remain necessary before source merge.

## 11. Team Learning

Gauss/Noether review showed that an independent rectangle oracle must itself be
tail-stable. Rose's fail-closed audit made endpoint diagnostics part of the
object contract. The reusable lesson is to retain numerical status by row, not
only optimizer summaries.

## 12. Cross-Product Coverage

The focused suite checks the existing Gaussian×Bernoulli and Gaussian×NB2
adapters alongside this Bernoulli×NB2 slice. It does NOT cover NB2×NB2,
Bernoulli×Bernoulli recovery, Arc 6.8 integration, REML, random/structured
effects, missingness, offsets, weights, association slopes, uncertainty,
recovery, capability promotion, Julia, or direct binary-count kernels.

## Next Actions

Wait for PR #822 CI, then review/land the source slice if green. Any S0
campaign needs a separate all-attempt approval and Totoro/DRAC receipt. Arc 6.7
has its own NB2×NB2 contract and cannot inherit this lane's evidence.
