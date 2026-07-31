# C6 contract — NB2 sigma phylo-interaction q1

## Exact target

Only ordinary univariate NB2 admits

```r
bf(count ~ x,
   sigma ~ phylo_interaction(1 | plant:pollinator,
                             tree1 = plant_tree,
                             tree2 = pollinator_tree))
```

The latent pair effect is a single q1 field on the log-sigma predictor:
`u ~ N(0, tau^2 (Q_pollinator kron Q_plant)^-1)`. The estimand is its latent
SD `tau`; the fixed NB2 location and fixed log-sigma intercept remain ordinary
fixed-effect parameters. No covariance, slope, correlation, or additional
random-effect parameter is admitted.

## Evidence boundary

The C++ q1 structured endpoint already routes `phylo_mu_dpar == 1` to the
NB2 log-sigma predictor. C6 adds the narrow R parser/specification/extraction
route, endpoint-aware method classification, and a direct profile target marked
`profile_ready = FALSE` with `profile_note = "point_fit_only_count_sigma_interaction"`.
The status makes the scalar visible without permitting profile computation.

Focused formula/extraction/status tests and the retained C7 local fixture are
the evidence for this cell. The route remains ordinary NB2, `sigma` only,
unlabelled q1, one phylo-interaction term, matching pair group and trees, with
no `zi`, no `mu` structured term, and no ordinary sigma random effect. It is
not interval, coverage, calibration, bivariate, association, or general
count-scale support.
