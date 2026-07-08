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
> at n_each=3 REML underperforms — weak-identification tail). Tests: `test-reml-ordinary-sigma.R`.
> Scoped to univariate; the bivariate ordinary sigma-RE cell is a separate future slice.

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
| 10 | biv q4 **dense** (one shared label) | ✅ | ⛔ GATE | **deliberate** — dense scale-side phylo rejected under REML (mean-scale cross-cov → sign-flip + collapse, doc 221). |

## Reading

- **ML is complete** across every combination tested — nothing is missing on the ML side.
- **REML gaps (3), none of them a bug:**
  - Rows 5–6: ordinary **sigma** random effects under REML are gated off (one gate,
    `drm_validate_reml_spec` ~:1973). This is the **S5** slice (relax + validate with a replication
    ladder). ML already supports them, so this is a REML-parity fill, not new ML work.
  - Row 10: dense q4 is **intentionally** rejected under REML (identifiability, not a gap).

**Bottom line for Shinichi:** the REML-parity principle is satisfied — no combination has REML
without ML, and ML is implemented for every combination on the ladder. The remaining REML gaps are
exactly the S5 (ordinary sigma-RE) work and the deliberate dense-q4 hold.
