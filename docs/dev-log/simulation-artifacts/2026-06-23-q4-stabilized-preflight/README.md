# Q4 Stabilized Preflight Artifact

This artifact records the compact q4 phylogenetic location-scale preflight that
first produced positive-Hessian rows with finite Wald direct-SD intervals after
the smaller q4 probes remained Hessian-boundary blocked.

Run from the repository root:

```sh
Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run.R
```

The script writes `q4-stabilized-preflight-results.tsv` in this directory.
The companion `q4-stabilized-denominator-extension-results.tsv` records the
clean exploratory extension for seeds `202606903` and `202606904`.
The companion `q4-stabilized-profile-smoke-results.tsv` records the first
single-target fast profile smoke on a positive stabilized row.
The companion `q4-stabilized-all-direct-profile-results.tsv` records the
all-four direct q4 SD profile smoke on the same positive stabilized row.
The companion `q4-stabilized-eligible-profile-results.tsv` records the
all-four direct q4 SD profile pass for the three remaining profile-eligible
denominator rows.

## Design

- Model: bivariate Gaussian q4 `phylo(1 | p | species)` in `mu1`, `mu2`,
  `sigma1`, and `sigma2`.
- Tree: deterministic balanced 32-tip ultrametric tree.
- Replication: eight observations per species.
- Seeds: `202606901`, `202606902`.
- Scale-axis signal levels: `0.35`, `0.50`.
- Among-axis target correlation: `0.05` on each off-diagonal.
- Residual `rho12`: `0.10`.

## Result

Two seed-902 rows reached optimizer convergence with `pdHess = TRUE`, interior
fitted correlations, and 4/4 finite Wald direct-SD interval rows. The two
seed-901 rows still had singular convergence and `pdHess = false`.

The denominator extension adds four rows: one additional finite-Wald row and one
additional singular-convergence row at scale `0.35`, and two additional
finite-Wald rows at scale `0.50`. The scale `0.50`, seed `202606903` row also
has a gradient warning (`max_gradient = 0.0048295879`), so it remains
denominator evidence rather than a promotion row.

The profile smoke used the scale `0.50`, seed `202606902` row and direct target
`sd:mu:sigma1:phylo(1 | p | species)`. A fast `TMB::tmbprofile` interval
returned finite endpoints (`0.2956858`, `0.7575208`) with
`conf.status = profile` and `profile.boundary = FALSE`.

The all-direct profile smoke used the same row. Fast `TMB::tmbprofile`
intervals returned finite ordered endpoints for all four direct q4 SD targets:
`sd:mu:mu1:phylo(1 | p | species)`, `sd:mu:mu2:phylo(1 | p | species)`,
`sd:mu:sigma1:phylo(1 | p | species)`, and
`sd:mu:sigma2:phylo(1 | p | species)`. Derived q4 correlation intervals remain
unpromoted and require separate reconstruction and denominator evidence.

The eligible-profile extension profiled the three remaining eligible
denominator rows: seed `202606902` at scale `0.35`, seed `202606903` at scale
`0.35`, and seed `202606904` at scale `0.50`. All twelve direct q4 SD profile
rows returned finite ordered endpoints with `conf.status = profile` and
`profile.boundary = FALSE`. The run emitted two `regularize.values()` duplicate
`x` warnings, so the result remains diagnostic profile evidence rather than
interval-reliability or coverage evidence.

This is preflight evidence only. It does not promote q4 interval reliability,
interval coverage, q4 REML, HSquared AI-REML, profile/bootstrap intervals,
broad bridge support, a public optimizer control, a commit, a PR, or an
Ayumi-facing reply.
