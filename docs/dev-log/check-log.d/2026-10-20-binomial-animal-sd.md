# Native Bernoulli animal-model SD regression

Native Binomial/Bernoulli SD formulas now accept one unlabelled q1 animal-model
location intercept with supplied `A`: `sd(id, level = "animal") ~ z`. The
canonical public target is `sd_animal(id)`, and the existing known-precision
likelihood applies the group-specific scale as `D A D`.

The new synthetic test passed 12 assertions for fit convergence, coefficient
and group-SD extraction, profile-target metadata, save/reload, prediction,
marginal simulation, one seeded log-SD slope recovery, constant-SD equivalence,
and rejection of predictor variation within animal ID. No live Julia test ran. The
source-loaded predictor-dependent SD vignette rendered to
`/private/tmp/predictor-dependent-random-sd-20261020-animal.html`; its Pandoc
option warning is pre-existing. `devtools::document()` and
`pkgdown::check_pkgdown()` completed successfully.

This evidence covers one native Bernoulli q1 intercept with supplied `A`. It
does not establish animal pedigree/Ainv parity, other family or effect shapes,
Julia parity, profile/bootstrap refitting, or interval calibration. See
`docs/dev-log/after-task/2026-10-20-binomial-animal-sd-regression.md`.
