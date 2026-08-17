# After Task: Design 257 Wave 2.5 — NB2 ordinary correlated slope

**Reader:** the next implementer, plus Fisher / Noether on the later review.
**Lane:** `cursor/ng-correlated-slope-nb2` (worktree
`/Users/z3437171/local-scratch/lanes/drmTMB-ng-corr-nb2`; Dropbox
`.worktrees/ng-corr-nb2` was abandoned after a reset race).
**Quiesce:** this branch must not merge to `main` until the 0.7.0 platform
matrix is complete. Draft PR only. Do not request merge.

## Goal

Admit the Wave-2.5 family wedge: complete-data ordinary `nbinom2()`
`count ~ x + (1 + x | id)` ML-Laplace at `point_fit_recovery`. Reuse the
Poisson design-17 map. Do not reuse Wave 2 `mc-0718`, do not touch
independent-slope `mc-0402`, and do not open Wave 3 continuous families,
REML, missing-response, MSPL, or Ligges / CRAN.

## Implemented

Compiled `model_type == 7` already matched Poisson `model_type == 6`. Wave
2.5 did not invent new C++ symbols and did not rewrite NB2 onto the
binomial log-sech factorisation. The alignment gate therefore flipped.

| Symbol | Extractor |
| --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `0.999999 tanh(eta_cor_mu)` |

`obj$report()` carries `eta_cor_mu` and `rho_mu_re`. It does not carry
`logsech_mu_re`.

New ledger cell **`mc-0719`**, `route_variant = ordinary_correlated_q2`,
`evidence_tier = point_fit_recovery`. `mc-0402` stays `interval_feasible`
for the independent slope. `mc-0718` stays the Poisson correlated cell.
`mc-0717` stays Wave 1 binomial.

## Mathematical Contract

```text
y_ij | μ_ij ~ NB2(μ_ij, σ)
log(μ_ij) = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
ρ = 0.999999 tanh(η)
u_cond,slope = ρ u_intercept + √(1-ρ²) u_slope
```

Group-level correlation is `rho_re`, never residual `rho12`. Overdispersion
`sigma` is a fixed-effect intercept (`size = 1 / sigma^2`).

R syntax for the cell:

```r
drmTMB(
  bf(count ~ x + (1 + x | id), sigma ~ 1),
  family = nbinom2(),
  data = dat
)
```

## Files Changed

- `R/drmTMB.R` — `validate_poisson_mu_random_terms()` admits exactly one
  unlabelled `correlated_slope` for `family_label %in% c("Poisson", "NB2")`;
  NB2 builder aborts correlated + `miss_control(response = "include")`;
  `split_tmb_corpars()` allowlists `"nbinom2"` so `corpars$mu` is populated.
- `R/mspl-estimator.R` — the Wave 1 constant-within-group `x` abort now
  also fires for ordinary NB2 q2 (`drm_nbinom2_correlated_q2()`). This is
  the unidentified-slope fence, not an MSPL expansion.
- `tests/testthat/test-nbinom2-ordinary-correlated-q2.R` — parser, design-17
  map, recovery, rejection matrix (REML, missing-response, mixed, ZI,
  lognormal as Wave 3 neighbour).
- `tests/testthat/test-nbinom2-location-scale.R` — labelled
  `(1 + x | p | id)` now expects the unlabelled-block message.
- `tests/testthat/test-poisson-ordinary-correlated-q2.R` and
  `test-binomial-correlated-re-mspl-prereq.R` — neighbour rejection moved
  from NB2 to `lognormal()`.
- Capability ledger: `mc-0719` plus evidence/transition; regenerated census
  and surface. `MODEL_SURFACE_COUNT` 701 → 702; implemented 343 → 344.
  `mc-0402` and `mc-0718` claim boundaries were not rewritten.
- C14 current-source receipt refreshed after the `R/drmTMB.R` blob change
  (`2026-08-16-wave25-nb2-c17c2-c14-final-source-compatibility/`).
  `source_fingerprint` left alone; model-15 4/4 PASS; `mean_tau_relative_error`
  digits unchanged versus the Wave 2 receipt.
- Grammar / known-limitations / NEWS / family docstring / oracle
  `candidates.tsv` (`fm2NB`). Design 257 gained the Wave 2.5 alignment table.

Not touched: `src/drmTMB.cpp`, `R/missing-data.R`, MSPL, Ligges / CRAN,
`mc-0402` claim, `mc-0718` claim, Wave 3 continuous families, Totoro/DRAC.

## Checks Run

| Check | Result |
| --- | --- |
| `devtools::test(filter = 'nbinom2-ordinary-correlated-q2\|nbinom2-location-scale\|poisson-ordinary-correlated-q2\|poisson-mean\|binomial-correlated-re-mspl-prereq')` | FAIL 0 / WARN 0 / SKIP 0 / PASS 478 |
| `python3 tools/capability_ledger.py --check` | OK (31 generated outputs) |
| C14 compatibility runner | 4/4 PASS on mc-0568 / mc-0569 / mc-0576 |
| `python3 -m unittest tools.tests.test_capability_ledger -q` | 80 tests OK |

## Tests Of The Tests

The rejection matrix fails closed on REML, missing-response, mixed
`(1|g)+(1+x|g)`, labelled, multi-slope, ZI, and Wave 3 `lognormal()`. The
recovery test names `sd0`/`sd1`/`rho_re` and keeps absolute 0.30 gates on
`nbinom2_q2_data()` (`n_group = 56`, `n_each = 14`, seed `20260816`,
`sd0 = 0.65`, `sd1 = 0.42`, `rho_re = 0.45`, `sigma = exp(-0.70)`).

## Consistency Audit

```sh
rg "mc-0719|ordinary_correlated_q2" docs/dev-log/dashboard/capability-ledger/cells.tsv NEWS.md docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md
rg "interval_feasible" docs/dev-log/dashboard/capability-ledger/cells.tsv | rg "mc-0402"
rg "mc-0718" docs/dev-log/dashboard/capability-ledger/cells.tsv
```

Grammar names `mc-0719` as not `mc-0402` and not `mc-0718`. `rho12` appears
only as the residual parameter that this block is not. `candidates.tsv`
`fm2NB` is now `EXPRESSIBLE` for the complete-data unlabelled wedge only.

## GitHub Issue Maintenance

No new issue. Wave 2.5 is the third code slice of Design 257 / #1057. Wave 1
draft `#1059` and Wave 2 draft `#1060` were left as the stack base. Foreign
issues `#1033` (missing-data), `#1061` (win-builder), and MSPL were left
untouched.

## What Did Not Go Smoothly

The Dropbox worktree `.worktrees/ng-corr-nb2` reset uncommitted edits back
to HEAD (same race Wave 2 documented). The lane moved to
`/Users/z3437171/local-scratch/lanes/drmTMB-ng-corr-nb2`. Do not continue
in the Dropbox worktree.

Admitting NB2 required a load-bearing `R/drmTMB.R` edit (validator +
missing-response abort + `split_tmb_corpars` allowlist). That stale-pinned
the C14 current-source blob for `mc-0568`. The committed runner was re-run
and the receipt paths were repointed. `source_fingerprint` was left alone.

`obj$report(opt$par)` is the wrong call on this route ("Wrong parameter
length"); recovery uses `obj$report()`. REML abort tests must match
`"Gaussian and binomial models"`.

## Team Learning

When NB2 report symbols already match Poisson, write the alignment row and
flip the gate in the same PR. Do not invent a new TMB symbol. Keep
`mc-0402` as the independent-slope cell; a correlated block is a different
estimand.

## Known Limitations

- Ceiling is `point_fit_recovery`. No interval, coverage, or `supported`.
- Zero-inflated or truncated NB2 correlated remains rejected.
- Labelled, mixed, REML, and missing-response stay red.
- Wave 3 continuous families remain planned.
- Totoro smoke and DRAC certification are the next compute arc, not this one.
- Quiesce merge hold remains.

## Next Actions

1. Keep this draft unmerged from this lane. After `#1059` and `#1060`
   land, a sibling may merge `#1065` if the stack stays green.
2. After win-builder / platform-clean, Fisher + Noether read the alignment
   table against a fitted object.
3. Totoro smoke only after that review and an explicit compute ask.
4. Do not admit a Wave 3 continuous family in this PR.
