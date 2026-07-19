# Trust Dossier #1 — drmTMB reproduces metafor and glmmTMB on meta-analysis

**Who this is for:** a meta-analyst deciding whether to trust `drmTMB` for
meta-analysis — in particular a reviewer who wants estimates checked against
established software, not asserted.

**What it shows, in one sentence:** on three published meta-analysis datasets,
`drmTMB` reproduces the estimates of `metafor` and `glmmTMB` to the accuracy bar set
by Williams et al. (arXiv:2604.04084) — and it fits a random-effect-in-dispersion
meta-analysis that neither `metafor::rma` nor `glmmTMB::dispformula` can, demonstrated
by recovery from known truth (a single simulation scenario; the calibrated grid is
deferred to Totoro).

## How to run

From this directory (or the package root):

```r
Rscript run.R
```

Needs (all on CRAN): `drmTMB`, `metafor`, `glmmTMB`, `metadat`. It sources the
in-package simulation harness from `inst/sim/`. Runtime ≈ 10 s. Every result below is
written to `results/` (one CSV per slice) plus `results/badge.json`.

## The evidence

| slice | model | comparison | result |
|---|---|---|---|
| **S1** | 3-level multilevel MA (`dat.assink2016`) | `metafor::rma.mv` = `glmmTMB(equalto)` = `drmTMB(meta_V)` | variance components agree to **< 2e-7**, pooled effect to < 5e-6, SE to < 5e-5 |
| **S2** | bivariate known-V MA (`dat.berkey1998`) | `metafor::rma.mv` = `drmTMB(meta_vcov_bivariate)` | between-study SDs & ρ to **< 1e-6**; means to < 3e-5 |
| **S3a** | location-scale MA, heterogeneity ~ moderator (`dat.bangertdrowns2004`) | `metafor::rma(scale=)` = `glmmTMB(dispformula)` = `drmTMB(sigma~x)` | log-heterogeneity coefs to **< 3e-5** |
| **S3b** | **random effect in dispersion** (`sigma ~ 1 + (1\|study)`) | none exists — simulation from truth | no detectable bias over 30 reps (\|bias\| < 3·MCSE) |
| **S4** | coverage smoke (Normal–Normal) | Wald coverage vs nominal 0.95 | intercept & σ ≈ 0.95; slope 0.89 (~2.7 SE low); 100-rep smoke |

### The Wolfgang-facing headline (S1)

The comparison design here is the one Williams et al. use to validate `glmmTMB`'s new
`equalto` structure: produce estimates that match `metafor`. This dossier reproduces
that design and adds `drmTMB` as a third, numerically-matching column. On the three-level
`dat.assink2016` model the pooled effect and both variance components agree across all
three packages: the two variance components to better than 2e-7 and the pooled
effect to under 5e-6. This is the part a comparator-minded reviewer
cannot argue with, so it leads.

### Where a comparator does not exist (S3b)

`metafor::rma`'s `scale=` models location-scale heterogeneity only as a *fixed* effect;
`glmmTMB::dispformula` admits no random effects. Modelling the heterogeneity magnitude
itself as a study-level random effect (`sigma ~ 1 + (1|study)`) has **no external
comparator**. The trust argument there is not "no comparator, trust us" — it is
recovery from known truth: data are simulated with a known dispersion random-effect SD
and `drmTMB` recovers it (bias within Monte-Carlo error over 30 replicates). This is a
single-scenario recovery *demonstration*; the calibrated coverage grid is commissioned
to Totoro (`results/totoro-commission.md`), not claimed here.

## Scope — what this dossier does NOT claim

- **Not** a coverage/type-I/power validation. S4 is a smoke that proves the harness
  runs and coverage is near nominal on 100 replicates (the intercept and σ land on
  0.95; the slope sits ~2.7 SE low, consistent with Monte-Carlo noise across three
  parameters or mild Wald slope under-coverage — the grid resolves it). The calibrated grid (4 effect
  measures × wide DGP range × ≥2000 reps) is the core simulation evidence and runs on
  Totoro/DRAC (D-50: never GitHub Actions).
- **Not** an independent replication. Trust level is **L2** (equivalence-to-comparator
  on published examples). **L3** requires an independent run by a third party.
- The logLik differs from `metafor` by a REML/location-scale normalization constant
  even where estimates are numerically indistinguishable; the parity claim is on
  **estimates**, not logLik.

## Provenance

`results/badge.json` records the trust level, the per-slice criteria and their measured
max-abs-diffs, the datasets, the master seed, the source commit SHA, and the exact
package versions. Regenerate everything with `Rscript run.R`.

Reference: Williams, McGillycuddy, Brooks, Bolker, Mizuno, Yang, Viechtbauer, Warton,
Nakagawa, *Meta-analysis with the glmmTMB R package*, arXiv:2604.04084. Location-scale
comparator: Viechtbauer & López-López (2022), *Location-scale models for meta-analysis*.
