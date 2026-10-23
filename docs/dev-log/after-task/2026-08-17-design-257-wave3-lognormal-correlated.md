# After Task: Design 257 Wave 3 — lognormal ordinary correlated slope

**Reader:** the next implementer, plus Fisher / Noether on the later review.
**Lane:** `cursor/ng-correlated-slope-wave3-lognormal` (worktree
`.worktrees/design257-1060-rebase`, branched from `origin/main`).
**Quiesce:** this branch must not merge to `main` until the 0.7.0 platform
matrix is complete. Draft PR only. Do not request merge. No `submit_cran`.
No #1033. No mc-0576 campaign.

## Goal

Admit the Wave-3 continuous-family wedge: complete-data ordinary
`lognormal()` `y ~ x + (1 + x | id)` ML-Laplace at `point_fit_recovery`.
Reuse the Poisson/NB2 design-17 map. Do not reuse Wave 2.5 `mc-0719`, do
not touch independent-slope `mc-0380`, and keep Gamma rejected.

## Implemented

Compiled `model_type == 4` previously treated ordinary `mu` REs as
independent. Wave 3 ports the design-17 correlated slope map already used
by Poisson (`model_type == 6`) / NB2 (`model_type == 7`):
`ρ = 0.999999 tanh(η)` and
`u_cond,slope = ρ u_intercept + √(1-ρ²) u_slope`. Report symbols match
Poisson. This wave does **not** inherit the binomial log-sech factorisation.

| Symbol | Extractor |
| --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `0.999999 tanh(eta_cor_mu)` |

`obj$report()` carries `eta_cor_mu` and `rho_mu_re`. It does not carry
`logsech_mu_re`.

New ledger cell **`mc-0720`**, `route_variant = ordinary_correlated_q2`,
`evidence_tier = point_fit_recovery`. `mc-0380` stays the independent-slope
cell. `mc-0719` stays Wave 2.5 NB2. Gamma stays rejected by the shared
positive-continuous validator.

## Mathematical Contract

```text
y_ij | mu_ij, sigma ~ Lognormal(mu_ij, sigma)
mu_ij = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
ρ = 0.999999 tanh(η)
u_cond,slope = ρ u_intercept + √(1-ρ²) u_slope
```

Group-level correlation is `rho_re`, never residual `rho12`. Residual
`sigma` is a fixed-effect intercept.

R syntax for the cell:

```r
drmTMB(
  bf(y ~ x + (1 + x | id), sigma ~ 1),
  family = lognormal(),
  data = dat
)
```

## Files Changed

- `src/drmTMB.cpp` — `model_type == 4` ordinary `mu` RE block now reads
  `eta_cor_mu` / `mu_re_cor_id` / `mu_re_pair_index` like Poisson.
- `R/drmTMB.R` — `validate_positive_continuous_mu_random_terms()` admits
  exactly one unlabelled `correlated_slope` for `{.fn lognormal}` only;
  lognormal builder aborts correlated + `miss_control(response = "include")`;
  `make_tmb_data` wires `n_mu_re_cors = re_mu$n_cors` for lognormal (Gamma
  stays `0L`); `split_tmb_corpars()` allowlists `"lognormal"`.
- `R/mspl-estimator.R` — `drm_lognormal_correlated_q2()` + constant-within-group
  `x` abort via the shared `#1059` helper (unidentified-slope fence, not MSPL).
- `tests/testthat/test-lognormal-ordinary-correlated-q2.R` — parser, design-17
  map, recovery, rejection matrix (REML, missing-response, mixed, labelled,
  Gamma neighbour, constant-x).
- Neighbour tests: binomial / Poisson / NB2 / lognormal-location-scale now
  keep Gamma (or mixed) red instead of treating lognormal as the Wave 3 red.
- Capability ledger: `mc-0720` plus evidence/transition; regenerated census
  and surface. `MODEL_SURFACE_COUNT` 702 → 703; implemented 344 → 345.
- C14 current-source receipt refreshed after the `R/drmTMB.R` +
  `src/drmTMB.cpp` blob change
  (`2026-08-17-wave3-lognormal-c17c2-c14-final-source-compatibility/`).
  `source_fingerprint` left alone; model-15 4/4 PASS;
  `mean_tau_relative_error` digits unchanged versus the binomial-phylo receipt.
- Grammar / known-limitations / NEWS / family docstring / design 257 Wave 3
  alignment table.

Not touched: MSPL, Ligges / CRAN, `#1033`, `mc-0576`, Totoro/DRAC, Gamma
admission, intervals/coverage/`supported`.

## Checks Run

| Check | Result |
| --- | --- |
| Focused `testthat` filter (`lognormal-ordinary-correlated-q2\|lognormal-location-scale\|nbinom2-ordinary-correlated-q2\|poisson-ordinary-correlated-q2\|binomial-correlated-re-mspl-prereq\|nongaussian-mu-random-slopes`) | FAIL 0 / DONE green |
| `python3 tools/capability_ledger.py --check` | OK (31 generated outputs) |
| C14 compatibility runner | 4/4 PASS; tau digits identical to prior receipt |
| `python3 -m unittest tools.tests.test_capability_ledger -q` | 80 tests OK |
| GitHub Actions on tip `f5d464d90` (PR [#1069](https://github.com/itchyshin/drmTMB/pull/1069), main-synced) | `os-matrix` SUCCESS; `ubuntu-latest (release)` SUCCESS in 47m16s (run `32085311878`); prior tip `70550fd48` also green (`32081714283`) |

## Tests Of The Tests

The rejection matrix fails closed on REML, missing-response, mixed
`(1|g)+(1+x|g)`, labelled, multi-slope, Gamma neighbour, and constant-within-group
`x`. The recovery test names `sd0`/`sd1`/`rho_re` and keeps absolute 0.30 gates
on `lognormal_q2_data()` (`n_group = 56`, `n_each = 14`, seed `20260816`,
`sd0 = 0.65`, `sd1 = 0.42`, `rho_re = 0.45`, `sigma = exp(-0.70)`).

## Consistency Audit

```sh
rg "mc-0720|ordinary_correlated_q2" docs/dev-log/dashboard/capability-ledger/cells.tsv NEWS.md docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md
rg "interval_feasible" docs/dev-log/dashboard/capability-ledger/cells.tsv | rg "mc-0380"
rg "mc-0719" docs/dev-log/dashboard/capability-ledger/cells.tsv
```

Grammar names `mc-0720` as not `mc-0380` and not `mc-0719`. `rho12` appears
only as the residual parameter that this block is not.

## GitHub Issue Maintenance

No new issue. Wave 3 is the fourth code slice of Design 257 / #1057. Foreign
issues `#1033` (missing-data), win-builder, and MSPL were left untouched.

## What Did Not Go Smoothly

`test-lognormal-location-scale.R` still expected `(1 + x | id)` to abort with
`"Only independent"`; after the wedge that expectation fitted. Retargeted to
the mixed neighbour `(1 | id) + (1 + x | id)`.

The Dropbox worktree name collision with the stale scratch branch
`cursor/ng-correlated-slope-lognormal` forced the branch name
`cursor/ng-correlated-slope-wave3-lognormal`.

## Team Learning

When a continuous family shares Poisson's design-17 report symbols, write
the alignment row, flip the family-specific validator wedge, and port the C++
carrier only if that family's `model_type` branch is still independent.
Keep Gamma rejected until its own PR. Keep `mc-0380` as the independent-slope
cell; a correlated block is a different estimand.

## Known Limitations

Quiesce holds — leave [#1069](https://github.com/itchyshin/drmTMB/pull/1069)
as draft until Fisher/Noether review and the 0.7.0 platform-matrix hold
lift. No interval, coverage, REML, missing-response, labelled, mixed,
Gamma, or `supported` claim. Local one-seed recovery only; no Totoro
smoke in this overnight slice.
