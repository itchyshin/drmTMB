## 1. Goal

Check whether native Poisson animal slope-only SD regression already works with supplied `Ainv` and with pedigree input, and record test evidence for it. Interval coverage remains deferred.

## 2. Implemented

No source change. A probe-first test showed the existing gate admits both inputs. New file `tests/testthat/test-poisson-animal-slope-ainv-pedigree-sd-regression.R` covers `animal(0 + x | id, Ainv = Q)` (deliberately permuted matrix order) and `animal(0 + x | id, pedigree = pedigree)`, each with `sd(id, level = "animal") ~ z`.

## 3a. Decisions

Test-only, because the probe passed on first run; there was no red phase, so these tests did not drive a code change. The two likelihood-equality checks against the `A =` fit and the constant-SD equivalence checks are what make them able to fail on a real regression.

## 4. Files Touched

- `tests/testthat/test-poisson-animal-slope-ainv-pedigree-sd-regression.R` (new)

## 5. Checks Run

17 expectations pass (`NOT_CRAN=true`): convergence, coefficient names, `z` coefficient within 0.4 of the simulated 0.35 (single fixture, loose), SD predictions in provider row order and by label, log-likelihood equal to the `A =` fit within 1e-4, and constant-SD log-likelihood equal to the base fit within 2e-5. Not run: neighbouring Poisson files, Julia parity, `devtools::document()`, package check.

## 6. Not Claimed

No ledger row promoted and no receipt written, so the queue's "closes 3 native rows" is not claimed here. Linking a receipt needs the source-hash step. No Julia parity, no calibration, nothing committed.
