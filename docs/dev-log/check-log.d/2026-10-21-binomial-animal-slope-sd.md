# Bernoulli animal slope SD regression

Command:

```sh
Rscript -e 'devtools::test(filter = "binomial-animal-(slope-)?sd-regression")'
```

Result: 28 passed, 0 failed, 0 warnings, 0 skipped in 48.6 seconds. The new
16-assertion slope test covers seeded point recovery, group-named SD prediction,
profile-target identity, simulation, save/reload, constant-SD equivalence, and
rejection of within-animal predictor variation. The existing 12-assertion
animal-intercept test also passed. This is native point-recovery evidence for
one supplied-`A` q1 slope cell, not interval calibration or Julia parity.

The individual slope test first failed at the intercept-only validator before
the admission change. A low-information DGP also failed the planned recovery
tolerance; a higher-information design now passes. The source change touches
`R/drmTMB.R`, which is under an active ZIP-slope lease and needs reconciliation
with that owner before source integration is considered settled.

The design pages and G3 ledger now record this partial route. The shared
formula-grammar page, vignette, NEWS, and known-limitations file remain leased
to another slice and are not updated here. See
`docs/dev-log/after-task/2026-10-21-binomial-animal-slope-sd.md`.
