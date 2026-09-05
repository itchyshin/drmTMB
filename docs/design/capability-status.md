# drmTMB capability status (R <-> Julia parity view)

This file is the R-side input to the mission-control R <-> Julia parity board.
It re-projects the raw 676-cell model-surface ledger
(`docs/dev-log/dashboard/capability-ledger/cells.tsv`) and the per-family
reference table in `docs/dev-log/dashboard/capability-surface.md` onto
**model-level** capability names that could plausibly exist in the `DRM.jl`
twin too. The Julia twin publishes the same names in its own
`docs/design/capability-status.md`; the mission-control server matches rows by
name across the two files.

Status words are drawn from the ledger's own vocabulary:

- `implemented` -- capability_status `implemented` with a solid evidence tier
  (`interval_feasible` or better: `inference_ready_with_caveats`, `supported`).
- `scope-limited` -- implemented for some but not all cells inside the named
  capability (a real mix of `implemented` and `rejected_by_design` /
  `not_implemented` rows), per the per-family reference table's own
  "scope-limited (implemented N; rejected M)" phrasing.
- `point-fit-recovery` -- `capability_status = implemented` but the strongest
  evidence tier attached is `point_fit_recovery` or `diagnostic_only`: the
  route fits and recovers known parameters, with no interval, coverage, or
  inference-ready claim yet.
- `rejected` -- `capability_status = rejected_by_design`.
- `planned` -- `capability_status = not_implemented`, or a capability with no
  cells in the census at all.

This is a projection, not a replacement for the ledger. When this file and
`cells.tsv` disagree, the ledger wins.

## Response families

All 18 rows below are drawn from the missing-response execution board in
`capability-surface.md` (18/18 routes at G3, verified) and the model-surface
family census. "Implemented" here means the family fits via `drmTMB()` with a
fixed-effect location-scale (or location-only) formula and has passed direct
sentinel mutation + recovery evidence; it does **not** claim full interval or
structured-random-effect coverage for that family (see the separate
structure/estimator rows below for that).

| Capability | Status |
|---|---|
| Gaussian location-scale (ML) | implemented |
| Bivariate Gaussian coscale (rho12) | implemented |
| Student-t location-scale | implemented |
| LogNormal location-scale | implemented |
| Gamma location-scale | implemented |
| Poisson counts | implemented |
| NegBinomial2 (NB2) counts | implemented |
| Zero-inflated Poisson (ZIP) | implemented |
| Zero-inflated NB2 (ZINB) | implemented |
| Beta proportions | implemented |
| Truncated NB2 (zero-truncated counts) | implemented |
| Hurdle NB2 | implemented |
| Cumulative logit (ordinal) | implemented |
| Beta-binomial proportions | implemented |
| Zero-one-inflated beta | implemented |
| Tweedie (compound Poisson-Gamma) | implemented |
| Skew-normal location-scale | implemented |
| Binomial (logistic) | implemented |

## Random-effect structure

Gaussian carries the deepest structured-random-effect surface, so these rows
are scoped to Gaussian; the non-Gaussian row below summarizes the same
structure providers across the other families.

| Capability | Status |
|---|---|
| Gaussian random intercept (mean) | implemented |
| Gaussian random slope (mean) | implemented |
| Gaussian random effect on sigma (scale) | implemented |
| Gaussian phylogenetic random intercept (mean) | scope-limited |
| Gaussian spatial random intercept (mean) | implemented |
| Gaussian animal-model random intercept (mean) | implemented |
| Gaussian relmat random intercept (mean) | implemented |
| Non-Gaussian phylogenetic random intercept (mean) | scope-limited |
| Non-Gaussian phylogenetic location-scale (μ + log σ) | scope-limited |
| Tweedie random intercept (mean) | implemented |
| Gaussian phylogenetic random intercept + slope, two SDs (mean) | implemented |

`Tweedie random intercept (mean)` is `implemented`:
`validate_tweedie_mu_random_terms()` (`R/drmTMB.R:11640-11662`) admits an
ordinary `(1 | g)` random intercept and an independent `(0 + x | g)` random
slope on `mu` for `tweedie()`, and
`tests/testthat/test-tweedie-location-scale.R:456-483` fits and recovers one.
This row was previously missing here even though DRM.jl lists it as
`implemented`; the capability already existed natively (2026-09-05
Julia-ahead census, `docs/dev-log/evidence/julia-r-parity/2026-09-05-julia-ahead-census.md`).

`Gaussian phylogenetic random intercept + slope, two SDs (mean)` is
`implemented`: `phylo(1 + x | species, tree = tree)` (`R/drmTMB.R:10819`)
always fits the independent two-SD model for Gaussian `mu`, because
`has_phylo_mu_q2_covariance` (`R/drmTMB.R:20063-20067`) is only set to 1 for
`spec$model_type %in% c("nbinom2", "poisson")` -- every other family,
Gaussian included, gets `has_phylo_mu_q2_covariance = 0`, which is the same
five-free-parameter independent model DRM.jl's `#620` replicates. This row
was also missing here (same 2026-09-05 census). The separate, already-known
asymmetry -- Poisson/NegBinomial2 fitting a *correlated* two-SD model under
the same formula (`has_phylo_mu_q2_covariance = 1`) -- is a different
capability, not this row.

`Gaussian phylogenetic random intercept (mean)` is `scope-limited`: the
per-family reference table records "phylo=scope-limited (implemented 4;
rejected 1; not implemented 1)" for gaussian `mu`. `Non-Gaussian phylogenetic
random intercept (mean)` mixes `scope-limited` (lognormal, gamma, poisson,
nbinom2, beta) and `rejected` (student, binomial) cells across families, so it
is reported at the coarser `scope-limited` level here. `Non-Gaussian
phylogenetic location-scale (μ + log σ)` is `scope-limited` on the `sigma`
axis with `structure_provider = phylo` in `cells.tsv`: `implemented` for
`nbinom2` (`interval_feasible`, mc-0421) and `zero_one_beta`
(`point_fit_recovery`, mc-0593), `rejected_by_design` for `beta`,
`beta_binomial`, `gamma`, `hurdle_nbinom2`, `lognormal`, `skew_normal`,
`student`, `truncated_nbinom2`, `tweedie`, and `zi_nbinom2`.

## Estimation and inference

| Capability | Status |
|---|---|
| REML (Gaussian fixed-effect location-scale) | point-fit-recovery |
| REML with ordinary random effects (Gaussian mean) | point-fit-recovery |
| REML bivariate phylogenetic location-scale (q4, all axes) | scope-limited |
| Wald SEs and CIs (observed information) | implemented |
| Profile-likelihood CIs | implemented |
| Parametric bootstrap CIs | implemented |
| AGHQ adaptive-quadrature marginal estimator | planned |
| Variational (VA/ELBO) marginal estimator | planned |
| Chi-bar-square boundary LRT p-value | planned |
| Model comparison suite (LRT/anova/AICc/weights/update) | planned |
| Heritability/repeatability/ICC accessors | point-fit-recovery |

Evidence for the REML rows: `cells.tsv` mc-0261/mc-0263 (fixed-effect Gaussian
REML, `mu`/`sigma`) and mc-0265/mc-0267/mc-0269/mc-0271 (ordinary random
intercept/slope + REML) are all `capability_status = implemented` at
`evidence_tier = point_fit_recovery` -- the routes fit and recover, but no
interval/coverage claim is banked yet, hence `point-fit-recovery` rather than
plain `implemented`. The q4 bivariate-phylogenetic REML row mixes
`interval_feasible` (a subset of `mu1`/`mu2` phylo REML cells),
`point_fit_recovery` (the `sigma1`/`sigma2` phylo REML cells), and `none`
cells -- there is no single verified claim that a REML correction reaches all
four axes (`mu1`, `mu2`, `sigma1`, `sigma2`) together, hence `scope-limited`.

`AGHQ`, chi-bar-square boundary tests, and a named model-comparison suite
(`anova`/`lrtest`/`aicc`/`weights`/`update`) have no implementation in `R/` and
no exported symbol in `NAMESPACE`; AGHQ is explicitly named as a future remedy
in ledger notes ("AGHQ/REML remedies planned"), so `planned` is used rather
than `rejected`. `profile.R` does cite Self & Liang (1987) / Stram & Lee
(1994) for boundary-aware profile-CI flagging
(`conf.status = "wald_at_boundary"`), which is related but not the same
capability as a formal chi-bar-square LRT p-value.

`Heritability/repeatability/ICC accessors` moved to `point-fit-recovery`:
`heritability()`/`icc()`/`repeatability()` (`R/heritability.R`,
`docs/design/259-heritability-icc-repeatability.md`) fit a Gaussian
structured-random-intercept model and recover the known variance ratio within
tolerance across seeded simulations, and report a delta-method Wald interval,
but that interval carries only a small-N sanity check, not a calibrated
coverage study -- hence `point-fit-recovery` rather than plain `implemented`.

## Bivariate structure and missing data

| Capability | Status |
|---|---|
| Bivariate structured random effect on all four axes (q4 PLSM) | point-fit-recovery |
| Cross-family bivariate (different families for y1 y2) | planned |
| Missing-response handling (native, per fitted route) | implemented |
| Missing-predictor imputation (mi()) | implemented |
| R to Julia bridge (engine=julia) | implemented |

`Bivariate structured random effect on all four axes` covers `biv_gaussian`
cells with `structure_provider` in `{phylo, spatial, animal, relmat}` on
`mu1`/`mu2`/`sigma1`/`sigma2` under ML: predominantly `diagnostic_only` /
`point_fit_recovery` evidence tiers, so `point-fit-recovery` overall (the
REML subset of this surface is reported separately above). `Cross-family
bivariate` has no cells in the 676-cell census at all -- the only bivariate
family is `biv_gaussian` -- so `planned`. `Missing-response handling` is
`implemented` on the strength of the independent missing-response execution
board (18/18 routes at G3, `R/missing-data.R`); `mi()` is an exported
NAMESPACE symbol used per-family for one binary missing predictor.
`R/julia-bridge.R` (4,363 lines) plus `tests/testthat/test-julia-bridge.R` and
`test-julia-phylo-q4-corpairs.R` back the bridge row.

## Snapshot

- 45 capabilities, all `implemented`/`scope-limited`/`point-fit-recovery`/
  `rejected`/`planned` per the mapping above.
- Sources read: `docs/dev-log/dashboard/capability-ledger/cells.tsv`,
  `docs/dev-log/dashboard/capability-ledger/schema.json`,
  `docs/dev-log/dashboard/capability-surface.md`, `NAMESPACE`, and targeted
  `grep` over `R/` (`julia-bridge.R`, `profile.R`, `missing-data.R`,
  `meta-vcov.R`, `methods.R`) to confirm exported symbols.

## Row-name match against DRM.jl (verified 2026-09-05 at pin `d3efbad2f`)

Matching by row name is this file's entire purpose — the mission-control server
joins the two twins' boards on it, so a near-miss is silently as bad as an absent
row. That match is therefore verified here rather than assumed, and it is now
GENERATED: `tools/write-parity-matrix.R` re-derives the counts below from both
files on every run and writes the full join, one row per capability with every
cell cited, to `docs/design/parity-matrix.md` (see that file for the per-row
bridge route, ledger status, and boundary). The numbers here are copied from
that artefact; when the two disagree, regenerate the artefact and fix this
section, in that order.

Compared against `DRM.jl` `docs/design/capability-status.md` at the parity pin
`d3efbad2f402cffb01e08eaf4efb25888d5fed96` (read with `git show`, never a
working tree; this is the pin the 2026-09-05 Julia-ahead census used and
verified against `gh api repos/itchyshin/DRM.jl/commits/main`,
`docs/dev-log/evidence/julia-r-parity/2026-09-05-julia-ahead-census.md`):

| | count |
|---|---:|
| rows in this file | 45 |
| rows in DRM.jl's file | 48 |
| **matched exactly (byte-for-byte row name)** | **45** |
| near-misses (differ only by case, punctuation or spacing) | **0** |
| present only in this file | **0** |
| present only in DRM.jl's file | 3 |

**Every row in this file has an exact counterpart in the twin, and no row name
differs only cosmetically.** The join is sound in the direction that matters for
this file.

The three DRM.jl-only rows are:

- `Conjugate-EM Gaussian phylo-mean (`algorithm = :em`)`
- `Natural-gradient EM (`algorithm = :natgrad`)`
- `Fisher / observed-info metric (`lc_metric`)`

All three name **Julia-side algorithm choices**, not model capabilities:
they are alternative optimisers/metrics for problems drmTMB reaches by a
different route, so they have no natural R counterpart and their absence here
is correct rather than a gap.

The 2026-09-05 Julia-ahead census (same file) measured DRM.jl `origin/main`
at 48 rows with **5** DRM.jl-only names at that time -- not this file's
previous count of 47/4 (itself already a correction of an earlier stale
46/3). Two of those five were not Julia-ahead at all: `Tweedie random
intercept (mean)` and `Gaussian phylogenetic random intercept + slope, two
SDs (mean)` are both capabilities drmTMB already fits natively, and the
census traced each to live R source and a passing test (see the two new rows
in the "Random-effect structure" table above, and their citations). Adding
those two rows here brings this file's own row count from 43 to 45 and drops
the DRM.jl-only count from 5 to 3, which is the row-match audit above.
Earlier versions of this section counted 46/3, then 47/4, both stale as the
twin's own row count grew; the "algorithm choices" sentence above is now
scoped to exactly the three rows it is true of, with no unexplained
DRM.jl-only row left.

`Non-Gaussian phylogenetic location-scale (μ + log σ)` used to be a further
DRM.jl-only row -- a model capability the twin lists that this board did not
project. It is now in the "Random-effect structure" table above at
`scope-limited`, resolved from `cells.tsv` (`dpar = sigma`,
`structure_provider = phylo`) rather than asserted from this section.

This section is a name-match verification. It promotes nothing, and where this
file and `docs/dev-log/dashboard/capability-ledger/cells.tsv` disagree, the
ledger still wins.
