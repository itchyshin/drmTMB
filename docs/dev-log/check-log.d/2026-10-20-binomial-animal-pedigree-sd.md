# Native binomial animal SD regression from pedigree

A seeded binary-response test passed for the pedigree animal intercept with a
predictor-dependent SD formula. It checks sparse pedigree precision against
the reordered dense covariance inverse, log-SD slope recovery, name-keyed group
predictions, and constant-SD likelihood equivalence. All 10 assertions passed
with no warnings, failures, or skips. This is native point-recovery evidence
for one family-provider cell; Julia parity and interval calibration remain
open. The combined neighboring regression filter passed 105 assertions with one existing sd_phylo() deprecation warning and no failures or skips. Independent static review passed.
