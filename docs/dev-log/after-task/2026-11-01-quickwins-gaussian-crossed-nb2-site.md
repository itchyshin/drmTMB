# After-task report: Gaussian crossed SD quick win; NB2 site audit

Date: 2026-11-01. Lane: general-sd-regression. Test-only; no source changes.

## What was asked

Two quick wins: (1) Gaussian ordinary crossed intercepts (1 | g) + (1 | h) with
sd(g) ~ w and sd(h) ~ v, checked against an exact marginal oracle; (2) NB2
ordinary (1 | site) beside animal, phylo and relmat intercepts with SD
formulas on both terms, without duplicating existing coverage.

## What changed

New file tests/testthat/test-sd-crossed-and-site-quickwins.R with three tests
(36 expectations, 0 failures on the first run, tolerances fixed beforehand).

1. Crossed Gaussian fit, shuffled levels, two SD slopes of opposite sign.
   Checks coefficient names, predictions keyed by level name (1e-10), signed
   slope recovery (within 0.8), logLik against the dense multivariate-normal
   oracle (1e-6), an independent L-BFGS-B maximum (1e-5), constant-SD
   equivalence with the formula-free fit (2e-5) and nesting, and a one-sided
   SD model. Five emulated bugs each move the oracle by more than 1e-2:
   position-instead-of-name SD vectors for each term, a sign-flipped slope, an
   ignored SD formula, and SD vectors assigned to the wrong term.
2. Term order and sd() order do not change the logLik (1e-6).
3. Refusals with message patterns: duplicate sd(g), sd(g, level = "phylogenetic")
   with no structured term, a predictor varying within g, an unknown variable.

## Item 2 is already covered, so nothing was added

test-nbinom2-batch5-sd-regression.R already tests NB2 (1 | site) with sd(site)
beside relmat K and Q, animal A and Ainv, and phylo, with SD formulas on both
terms and a Laplace check, and it also has a crossed NB2 case. Adding a copy
would duplicate it.

## Not covered

se = TRUE inference, simulate(), coverage, structured providers for the
crossed Gaussian case (the non-unit-diagonal K rule does not apply to ordinary
intercepts), and the Julia engine.

## Neighbours checked

Gaussian batch 5 covers ordinary plus structured; binomial and NB2 already
have crossed tests. The Gaussian crossed ordinary case was the missing cell.
