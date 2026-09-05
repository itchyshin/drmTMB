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

- 43 capabilities, all `implemented`/`scope-limited`/`point-fit-recovery`/
  `rejected`/`planned` per the mapping above.
- Sources read: `docs/dev-log/dashboard/capability-ledger/cells.tsv`,
  `docs/dev-log/dashboard/capability-ledger/schema.json`,
  `docs/dev-log/dashboard/capability-surface.md`, `NAMESPACE`, and targeted
  `grep` over `R/` (`julia-bridge.R`, `profile.R`, `missing-data.R`,
  `meta-vcov.R`, `methods.R`) to confirm exported symbols.

## Row-name match against DRM.jl (verified 2026-09-05 at pin `430ef64cc`)

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
`430ef64ccca5642c5abebd72194e00895314dfc2` (read with `git show`, never a
working tree):

| | count |
|---|---:|
| rows in this file | 43 |
| rows in DRM.jl's file | 47 |
| **matched exactly (byte-for-byte row name)** | **43** |
| near-misses (differ only by case, punctuation or spacing) | **0** |
| present only in this file | **0** |
| present only in DRM.jl's file | 4 |

**Every row in this file has an exact counterpart in the twin, and no row name
differs only cosmetically.** The join is sound in the direction that matters for
this file.

The four DRM.jl-only rows are:

- `Tweedie random intercept (mean)`
- `Conjugate-EM Gaussian phylo-mean (`algorithm = :em`)`
- `Natural-gradient EM (`algorithm = :natgrad`)`
- `Fisher / observed-info metric (`lc_metric`)`

The last three name **Julia-side algorithm choices**, not model capabilities:
they are alternative optimisers/metrics for problems drmTMB reaches by a
different route, so they have no natural R counterpart and their absence here
is correct rather than a gap.

`Tweedie random intercept (mean)` is different in kind: it is a **model
capability** (an ordinary `(1 | g)` random intercept, and an independent
`(0 + x | g)` random slope, on `mu` for `tweedie()`), which DRM.jl lists as
`implemented` and same-target checked against drmTMB 0.7.0. drmTMB fits the same
cells natively (`validate_tweedie_mu_random_terms()` admits exactly that scope),
but this board folds them into the `Tweedie (compound Poisson-Gamma)` family row
rather than projecting a separate structure row. The earlier version of this
section counted 46 DRM.jl rows and 3 DRM.jl-only rows and described all of them
as algorithm choices; that was stale once the twin added this row, and the
"algorithm choices" sentence above is now scoped to the three rows it is true of.
Whether to add a matching `Tweedie random intercept (mean)` row here is an owner
call; until then it stays a named, explained DRM.jl-only row, not an unexplained
count.

`Non-Gaussian phylogenetic location-scale (μ + log σ)` used to be a further
DRM.jl-only row -- a model capability the twin lists that this board did not
project. It is now in the "Random-effect structure" table above at
`scope-limited`, resolved from `cells.tsv` (`dpar = sigma`,
`structure_provider = phylo`) rather than asserted from this section.

This section is a name-match verification. It promotes nothing, and where this
file and `docs/dev-log/dashboard/capability-ledger/cells.tsv` disagree, the
ledger still wins.
