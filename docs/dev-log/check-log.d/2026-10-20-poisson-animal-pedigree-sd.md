# Native Poisson animal SD regression from pedigree

A seeded test passed for `animal(1 | id, pedigree = pedigree)` with
`sd(id, level = "animal") ~ z`. It generates effects from the dense additive
relationship matrix, while the fitted model uses the sparse pedigree precision
path. The test checks sparse precision against the reordered dense covariance
inverse, SD-slope recovery, group predictions keyed by animal name, and
constant-SD equivalence. All 11 assertions passed. Evidence covers native point recovery only; Julia parity and interval calibration remain open.
