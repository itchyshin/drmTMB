# ML vs REML coverage audit (2026-07-07)

Shinichi's check: *every combination must have ML; no combination should have REML without ML.*
Empirical admission audit (`scratchpad/ml_reml_parity_audit.R`) — for each model SHAPE, does it fit
under **ML** (`REML = FALSE`) and under **REML** (`REML = TRUE`)? A small replicated fixture
(n_tip=40 × n_each=5) so admitted models actually fit; classification = fit / GATE (validation
reject) / err.

> **UPDATE 2026-07-08.** Rows 5–6 (univariate ordinary sigma random effects under REML) are now
> **CLOSED** — the gate `drm_validate_reml_spec` (~R/drmTMB.R:1973) was relaxed to admit an ordinary
> sigma random intercept `(1|id)`, an independent random slope `(0+x|id)`, and the correlated
> mu-sigma block `(1|p|id)`. Recovery ladders (`scratchpad/reml_ordinary_sigma_re_probe.R`): REML
> debiases the scale-RE SD vs ML uniformly across all three shapes **with replication** (n_each≥~8;
> at n_each=3 REML underperforms — weak-identification tail). The **bivariate** labelled scale-side
> sigma block `(1|s|id)` on sigma1/sigma2 is also now admitted under REML (biv gate ~R/drmTMB.R:2046;
> `scratchpad/reml_biv_sigma_re_probe.R` — both scale-RE SDs recover under ML and REML). Tests:
> `test-reml-ordinary-sigma.R`. Still gated: bivariate mean-scale (`mu`-`sigma`) RE correlations.

## Result — the parity invariant HOLDS

**No REML-without-ML anywhere.** Every cell REML admits, ML also admits. REML is a clean **subset**
of ML (as it must be — REML adds the fixed-effect marginalization on top of the same ML machinery).
ML covers the full ladder tested (10/10 shapes fit).

| # | model shape | ML | REML | note |
|---|---|:--:|:--:|---|
| 1 | q1 univariate phylo-mean | ✅ | ✅ | |
| 2 | q2 univariate matched mean+scale | ✅ | ✅ | **landed this session (S1)** |
| 3 | univariate ordinary loc-intercept `(1\|id)` | ✅ | ✅ | |
| 4 | univariate ordinary loc-slope `(1+x\|id)` | ✅ | ✅ | |
| 5 | univariate ordinary loc+scale **correlated** `(1\|p\|id)` both | ✅ | ✅ | **landed 2026-07-08** (gate 1973 relaxed; debiases with replication) |
| 6 | univariate ordinary scale-slope (indep) `sigma~x+(0+x\|id)` | ✅ | ✅ | **landed 2026-07-08** (same) |
| 7 | biv rung1 phylo-means | ✅ | ✅ | |
| 8 | biv rung2 direct-SD phylo scale `sd_phylo1/2(sp)~z` | ✅ | ✅ | |
| 9 | biv q4 **block-diagonal** (mu-label ⊥ sigma-label) | ✅ | ✅ | **landed this session (S3)** |
| 10 | biv q4 **dense** (one shared label) | ✅ | ✅ | **landed 2026-07-08** — the "sign-flip" was an under-powered-fit artifact (mapping verified correct); needs n_tip≥~200 AND n_each≥~10, where REML beats ML (higher pdHess, debiased SDs). |
| 11 | biv mu-sigma RE correlation (`1\|p\|id` across mu+sigma) | ✅ | ✅ | **landed 2026-07-08** |
| 12 | q>2 labelled LOCATION block (`1+x1+x2\|id`) | ✅ | ✅ | **landed 2026-07-08** (REML consistently less biased than ML) |
| 13 | **correlated residual-scale slope** block (`sigma ~ x + (1+x\|id)`) | ⛔ | ⛔ | **not implemented in ML either** — new engine work (the q12 piece) |

## Reading (as of 2026-07-08)

- **ML/REML parity is COMPLETE for every implemented cell.** Every combination that ML fits, REML
  now also fits (rows 1–12). No REML-without-ML anywhere, and no ML-without-REML either.
- **The only remaining gap (row 13) is missing from *ML* too:** correlated residual-scale slope
  blocks (`sigma ~ x + (1 + x | id)`) are not implemented in the engine at all — only *independent*
  residual-scale slopes exist. This is the q12 piece and it is **new ML engine work**, after which
  REML follows.
- **Two prior verdicts were overturned by evidence this session:**
  1. The q2 "REML degrades the mean, needs Cox-Reid" verdict — a below-floor small-`N` artifact.
  2. The dense-q4 "sign-flip + always collapses" verdict — an **under-powered-fit** artifact. The
     DGP↔endpoint mapping is provably correct, and with adequate information REML is *strictly
     better* than ML on the dense q4 (higher pdHess/convergence, debiased SDs).
- **Standing caveat (data, not algorithm):** REML debiases scale-side variance components only with
  adequate within-group replication. Below the floor it can underperform ML. Each cell's floor is
  quantified in its ladder (`scratchpad/reml_*_ladder.R`, `scratchpad/q4_signflip_diagnostic.R`).
