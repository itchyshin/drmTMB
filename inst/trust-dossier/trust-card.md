# Trust Card — drmTMB meta-analysis

> One page. Claim, evidence, level, and what is not covered.

**Claim.** `drmTMB` produces the same meta-analysis estimates as `metafor` and
`glmmTMB` on published datasets, and additionally fits a random-effect-in-dispersion
meta-analysis those packages cannot.

**Trust level: L2** — equivalence-to-comparator on published examples.
(L1 = runs; L2 = matches an established comparator; L3 = independent replication.)

| # | What was checked | Comparator | Verdict |
|---|---|---|---|
| S1 | 3-level multilevel MA, `dat.assink2016` | metafor = glmmTMB = drmTMB | ✅ var. comps < 2e-7, effect < 5e-6 |
| S2 | bivariate known-V MA, `dat.berkey1998` | metafor = drmTMB | ✅ SDs & ρ < 1e-6 (means < 3e-5) |
| S3a | location-scale (heterogeneity ~ moderator) | metafor(scale=) = glmmTMB = drmTMB | ✅ agree < 3e-5 |
| S3b | RE-in-dispersion `sigma ~ (1\|study)` | none — simulation from truth | ✅ no detectable bias over 30 reps |
| S4 | Wald coverage (Normal–Normal) | nominal 0.95 | 🟡 intercept/σ ≈ 0.95, slope 0.89 (~2 MCSE low), 100-rep **smoke** only |

**Accuracy bar** (Williams et al., arXiv:2604.04084, Wolfgang co-author): pooled effect
to 6 dp, τ² to 5 dp, SEs match. **Measured:** heterogeneity/variance params to < 1e-6,
pooled effects to < 3e-5 (4–5 dp), SEs to < 5e-5 — comparator equivalence in every slice,
at the practical tolerance the CSVs record (`results/badge.json`), not always the full 6 dp.

**What this does NOT cover.**
- Not calibrated coverage/type-I/power — that grid runs on Totoro (see
  `results/totoro-commission.md`), not in this lane.
- Not an independent replication (that is L3).
- Parity is on estimates, not logLik (REML normalization constant differs).

**Reproduce.** `Rscript run.R` → writes `results/*.csv` + `results/badge.json`.
**Provenance.** Seed, source SHA, and package versions in `results/badge.json`.
**Signer.** Unsigned self-check; L3 signer = an independent run.

**References.** Williams et al., *Meta-analysis with the glmmTMB R package*,
arXiv:2604.04084 (S1–S3 comparison design). Viechtbauer & López-López (2022),
*Location-scale models for meta-analysis* (S3a comparator).
