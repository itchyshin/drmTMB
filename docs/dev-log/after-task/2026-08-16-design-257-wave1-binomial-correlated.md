# After Task: Design 257 Wave 1 — binomial ordinary correlated slope

**Reader:** the next implementer, plus Fisher / Noether on the later review.
**Lane:** `cursor/ng-correlated-slope-impl` (worktree `.worktrees/ng-corr-w1`).
**Quiesce:** this branch must not merge to `main` until the 0.7.0 platform
matrix is complete. Draft PR only. Do not request merge.

## Goal

Make the existing complete-data binomial logit unlabelled `(1 + x | g)`
ML-Laplace path an honest `point_fit_recovery` cell, without reusing
`mc-0061` and without opening REML, missing-response, MSPL, or Wave 2.

## Implemented

The compiled log-sech Cholesky already reports the three Design 257
estimands. Wave 1 did not invent new C++ symbols and did not rewrite the
map to design 17's `√(1-ρ²)` form.

| Symbol | Extractor |
| --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` = `tanh(eta_cor_mu)` at `opt$par` |

`obj$report()` still carries `eta_cor_mu`, `rho_mu_re`, and `logsech_mu_re`.
After `sdreport()`, `report()` can sit on TMB `last.par`; the recovery test
therefore binds `rho_re` to `parList(opt$par)`, matching the existing parser
test. That is not a Noether gap.

New ledger cell **`mc-0717`**, `route_variant = ordinary_correlated_q2`,
`evidence_tier = point_fit_recovery`. `mc-0060` / `mc-0061` / `mc-0062` are
unchanged.

## Mathematical Contract

```text
logit(p_ij) = X_ij β + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
```

`Σ_g` uses the existing binomial log-sech factorisation
(`docs/design/257-nongaussian-ordinary-correlated-slope.md`). Group-level
correlation is `rho_re`, never residual `rho12`.

R syntax for the cell:

```r
drmTMB(
  bf(cbind(success, failure) ~ x + (1 + x | id)),
  family = binomial(),
  data = dat
)
```

## Files Changed

- `tests/testthat/test-binomial-correlated-re-mspl-prereq.R` — named
  `sd0`/`sd1`/`rho_re` extractors; added the rejection matrix
  (REML, missing-response+q2, mixed `(1|g)+(1+x|g)`, labelled, Poisson).
- Capability ledger: `mc-0717` plus evidence/transition; regenerated census
  and surface. `MODEL_SURFACE_COUNT` 699 → 700; implemented 341 → 342.
- Grammar / known-limitations / NEWS honesty. Design 257 copied onto this
  branch.
- `R/drmTMB.R` left untouched after a one-line message edit tripped the
  C14 current-source receipt. Fences stay in
  `validate_binomial_mu_random_terms()` and
  `drm_validate_binomial_q2_context()`.

Not touched: `R/missing-data.R`, MSPL estimator code, Ligges / CRAN, Wave 2
families, Totoro/DRAC.

## Checks Run

| Check | Result |
| --- | --- |
| `devtools::test(filter = 'binomial-correlated-re-mspl-prereq')` | FAIL 0 / WARN 0 / SKIP 0 / PASS 56 |
| `devtools::test(filter = 'reml-binomial-coxreid')` | FAIL 0 / WARN 0 / SKIP 0 / PASS 8 |
| `python3 tools/capability_ledger.py --check` | OK (30 generated outputs) |
| `python3 -m unittest tools.tests.test_capability_ledger -q` | 78 tests OK |

## Tests Of The Tests

The new rejection matrix fails closed on REML, missing-response+q2, mixed
same-group intercept plus correlated block, labelled blocks, and one Wave 3
family (Poisson). The recovery test names `sd0`/`sd1`/`rho_re` and keeps the
existing 0.30 absolute gates on the frozen `mspl_q2_data()` fixture
(`n_group = 56`, `n_each = 14`, seed `20260811`).

## Consistency Audit

```sh
rg "experimental q=2 point-fit slice|mc-0061" docs/design/01-formula-grammar.md docs/dev-log/known-limitations.md NEWS.md
rg "rho12" docs/design/257-nongaussian-ordinary-correlated-slope.md docs/design/01-formula-grammar.md docs/dev-log/after-task/2026-08-16-design-257-wave1-binomial-correlated.md
rg "mc-0717|ordinary_correlated_q2" docs/dev-log/dashboard/capability-ledger/cells.tsv
```

Grammar now calls the ML-Laplace cbind route `point_fit_recovery` and names
`mc-0717` as not `mc-0061`. `rho12` appears only as the residual parameter
that this block is not. MSPL remains experimental.

## GitHub Issue Maintenance

No new issue. Wave 1 is the first code slice of Design 257 / #1057. Foreign
issues `#1033` (missing-data) and `#1049` (binomial phylo) were left
untouched.

## What Did Not Go Smoothly

A one-line honesty edit in `validate_binomial_mu_random_terms()` changed the
`R/drmTMB.R` blob and failed the C14 current-source receipt for `mc-0568`.
The edit was reverted. Grammar and the ledger carry the honest claim; the
parser `i` hint still says "experimental q = 2".

## Team Learning

Pinned C14 receipts make even a user-facing message in `R/drmTMB.R` a
receipt-refresh job. Prefer docs/ledger honesty for Wave 1 unless the
message is load-bearing.

## Known Limitations

- Ceiling is `point_fit_recovery`. No interval, coverage, or `supported`.
- Bernoulli `y01 ~ x + (1 + x | g)` is a sibling, not this cell.
- Probit / cloglog inherit the parser only; they do not inherit `mc-0717`.
- Wave 2 (Poisson / NB2) is a later PR.
- Totoro smoke and DRAC certification are the next compute arc, not this one.
- Quiesce merge hold remains.

## Next Actions

1. Keep the draft PR unmerged.
2. After win-builder / platform-clean, Fisher + Noether read the alignment
   table against a fitted object.
3. Totoro smoke (`n_each ∈ {4, 8, 14}`, iid control + one external oracle)
   only after that review and an explicit compute ask.
4. Do not open Wave 2 in this PR.
