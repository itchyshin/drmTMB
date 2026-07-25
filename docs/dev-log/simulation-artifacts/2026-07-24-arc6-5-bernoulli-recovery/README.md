# Arc 6.5 Bernoulli x Bernoulli Totoro HOLD receipt

## Purpose

This receipt authenticates the owner-approved Arc 6.5 recovery campaign without
turning its result into a passing recovery or capability claim. The campaign
tested the fixed-effect, complete-pair, intercept-only frozen-margin
Bernoulli-logit association route at source commit
`51647467196f9f212dea0bcb323fe649462f570d`.

## Retained artifacts

The campaign artifacts remain local on Totoro, as required for simulation
campaign evidence:

```text
/home/snakagaw/hsq_work/arc65-runs/2026-07-24-51647467-r10/
```

| File | SHA-256 |
| --- | --- |
| `git-sha.txt` | `12739b8f6a4bf77a219f98297a5acfe18052e7faf7ec3e77bf2e26cc3a45eac4` |
| `hold-design.csv` | `02024e47b0de2b4e59030eab20664aafa14078ea56614d5bbb8d1b8bb71bf657` |
| `raw-attempts.csv` | `37edfbda9b7dc2894815c69eb07294e0d4ac75b7f7c333cd38645498e66ae97d` |
| `session-info.txt` | `8634f008e419f919638d60e5e870d6fb5bd9d39f2da582269a62029925249126` |
| `summary.csv` | `139d5506388e826bf76a8deb0a6cd786aa5af646c3071171ed5947880e8ac586` |

The recorded session is R 4.5.3 on Ubuntu 24.04.4 with `drmTMB` 0.6.0,
`testthat` 3.3.2, and TMB 1.9.21.

## Verification

Read-only inspection of `raw-attempts.csv` found 220 retained attempts: 180
interior rows and 40 predeclared rare/near-boundary HOLD rows. The interior
summary contains 18 cells: 17 pass the predeclared rule of 10/10 returned
estimates and absolute mean bias no greater than 0.10; one fails.

The failed cell is `n = 120`, asymmetric prevalence, true `eta = 0.5`,
replicate 1, seed 650016. It is `boundary_unresolved`, so the cell has 9/10
returned estimates. The raw ledger contains 28 boundary-unresolved rows in
total: this one interior row plus 27 rare-HOLD rows. The runner exits nonzero
when any interior summary cell fails, so this record is an all-attempt HOLD.

## Interpretation and boundary

The receipt verifies the reported HOLD; it does not weaken its denominator,
rescore the failed fit, or authorize a merge-time capability change. It does
not establish standard errors, intervals, profiles, coverage, random effects,
missing-data behavior, REML, or broad mixed-family support. A future recovery
attempt needs a new owner decision, a new frozen design, and a separately
retained all-attempt receipt.
