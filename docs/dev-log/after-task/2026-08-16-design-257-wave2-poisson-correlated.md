# After Task: Design 257 Wave 2 — Poisson ordinary correlated slope

**Reader:** the next implementer, plus Fisher / Noether on the later review.
**Lane:** `cursor/ng-correlated-slope-wave2` (worktree `.worktrees/ng-corr-w2`).
**Quiesce:** this branch must not merge to `main` until the 0.7.0 platform
matrix is complete. Draft PR only. Do not request merge.

## Goal

Admit the first Wave-2 family wedge: complete-data ordinary Poisson log
`count ~ x + (1 + x | id)` ML-Laplace at `point_fit_recovery`. Do not reuse
Wave 1 `mc-0717`, do not touch `mc-0061`, and do not open NB2, REML,
missing-response, MSPL, or Ligges / CRAN.

## Implemented

The compiled Poisson `model_type == 6` branch already carried the design-17
map. Wave 2 did not invent new C++ symbols and did not rewrite Poisson onto
the binomial log-sech factorisation.

| Symbol | Extractor |
| --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `0.999999 tanh(eta_cor_mu)` |

`obj$report()` carries `eta_cor_mu` and `rho_mu_re`. It does not carry
`logsech_mu_re`.

New ledger cell **`mc-0718`**, `route_variant = ordinary_correlated_q2`,
`evidence_tier = point_fit_recovery`. `mc-0431` (independent slope) is
unchanged. `mc-0432` remains the labelled/mixed/multi-slope rejected
remainder. `mc-0717` is Wave 1 binomial and is not on this branch.

## Mathematical Contract

```text
y_ij | λ_ij ~ Poisson(λ_ij)
log(λ_ij) = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
ρ = 0.999999 tanh(η)
u_cond,slope = ρ u_intercept + √(1-ρ²) u_slope
```

Group-level correlation is `rho_re`, never residual `rho12`.

R syntax for the cell:

```r
drmTMB(
  bf(count ~ x + (1 + x | id)),
  family = poisson(),
  data = dat
)
```

## Files Changed

- `R/drmTMB.R` — `validate_poisson_mu_random_terms()` admits exactly one
  unlabelled `correlated_slope` for `family_label == "Poisson"`; Poisson
  builder aborts correlated + `miss_control(response = "include")`;
  `split_tmb_corpars()` allowlists `"poisson"` so `corpars$mu` is populated.
- `tests/testthat/test-poisson-ordinary-correlated-q2.R` — parser, design-17
  map, recovery, rejection matrix (REML, missing-response, mixed, NB2).
- `tests/testthat/test-poisson-mean.R` — mixed `(1|id)+(1+x|id)` now expects
  the unlabelled-block message; labelled `(1|p|id)` still expects
  `"Only independent Poisson"`.
- Capability ledger: `mc-0718` plus evidence/transition; `mc-0432` rewritten
  as the rejected remainder; regenerated census and surface.
  `MODEL_SURFACE_COUNT` 699 → 700; implemented 341 → 342.
- C14 current-source receipt refreshed after the `R/drmTMB.R` blob change
  (`2026-08-16-wave2-poisson-c17c2-c14-final-source-compatibility/`).
  `source_fingerprint` left alone; model-15 4/4 PASS.
- Grammar / known-limitations / NEWS / roadmap row 192 / oracle
  `candidates.tsv` (`fm2P`, `fm3ZIP`). Design 257 copied onto this branch
  with the Wave 2 Poisson alignment table.

Not touched: `src/drmTMB.cpp`, `R/missing-data.R`, MSPL, Ligges / CRAN,
`mc-0061`, `mc-0717`, NB2 admission, Totoro/DRAC.

## Checks Run

| Check | Result |
| --- | --- |
| `devtools::test(filter = 'poisson-ordinary-correlated-q2\|poisson-mean')` | FAIL 0 / WARN 0 / SKIP 0 / PASS 161 |
| `python3 tools/capability_ledger.py --check` | OK (31 generated outputs) |
| C14 compatibility runner | 4/4 PASS on mc-0568 / mc-0569 / mc-0576 |
| `python3 -m unittest tools.tests.test_capability_ledger -q` | 77 tests OK |

## Tests Of The Tests

The rejection matrix fails closed on REML, missing-response, mixed
`(1|g)+(1+x|g)`, labelled, multi-slope, and NB2. The recovery test names
`sd0`/`sd1`/`rho_re` and keeps absolute 0.30 gates on `poisson_q2_data()`
(`n_group = 56`, `n_each = 14`, seed `20260816`, `sd0 = 0.65`, `sd1 = 0.42`,
`rho_re = 0.45`).

## Consistency Audit

```sh
rg "mc-0718|ordinary_correlated_q2" docs/dev-log/dashboard/capability-ledger/cells.tsv NEWS.md docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md
rg "Only independent Poisson" tests/testthat/test-poisson-mean.R docs/dev-log/external-oracle/candidates.tsv
rg "rho12" docs/design/257-nongaussian-ordinary-correlated-slope.md docs/design/01-formula-grammar.md
```

Grammar names `mc-0718` as not `mc-0431` and not `mc-0717`. `rho12` appears
only as the residual parameter that this block is not. NB2 stays rejected.
`candidates.tsv` `fm2P` / `fm3ZIP` are now `EXPRESSIBLE`; `fm2NB` stays
`NOT_EXPRESSIBLE`.

## GitHub Issue Maintenance

No new issue. Wave 2 is the second code slice of Design 257 / #1057. Wave 1
draft `#1059` (`mc-0717`) was left untouched. Foreign issues `#1033`
(missing-data) and `#1049` (binomial phylo) were left untouched.

## What Did Not Go Smoothly

Admitting Poisson required a load-bearing `R/drmTMB.R` edit (validator +
`split_tmb_corpars` allowlist). That stale-pinned the C14 current-source
blob for `mc-0568`. Wave 1 reverted a similar one-line edit; Wave 2 could
not, so the committed runner was re-run and the receipt paths were
repointed. `source_fingerprint` was left alone.

`obj$report(opt$par)` is the wrong call on this route ("Wrong parameter
length"); recovery uses `obj$report()`. REML abort tests must match the
backticked `` `REML` `` message, not a `fixed = TRUE` substring that omits
it.

## Team Learning

When the parser change is load-bearing, budget the C14 receipt refresh
(~90 s locally) instead of reverting the R edit. Do not share a cell id
with a parallel Wave 1 PR: this branch uses `mc-0718` / 700 / 342 so it
does not collide with `#1059`'s `mc-0717`. Merge will still conflict on
`NEWS`, grammar, `cells.tsv`, and the count literals.

## Known Limitations

- Ceiling is `point_fit_recovery`. No interval, coverage, or `supported`.
- NB2 correlated remains rejected (next Wave-2 family, one PR later).
- Labelled, mixed, REML, and missing-response stay red.
- Totoro smoke and DRAC certification are the next compute arc, not this one.
- Quiesce merge hold remains.

## Next Actions

1. Keep the draft PR unmerged.
2. After win-builder / platform-clean, Fisher + Noether read the alignment
   table against a fitted object.
3. Totoro smoke only after that review and an explicit compute ask.
4. Do not admit NB2 in this PR.
