# Dataset inventory for reader-facing comparator workflows (Phase 19)

Curie · scoped for PR 2 (comparator vignette work), no new dependency.
Worktree: `.worktrees/external-oracle`, drmTMB 0.7.0 (`DESCRIPTION:3`).
Commands run are R scripts executed via
`R_PROFILE_USER=/dev/null Rscript --no-init-file <script>`; all under a few
seconds each, well inside the 5-minute budget.

## (a) DESCRIPTION `Suggests` inventory

`DESCRIPTION:39-59` lists the candidate packages named in the task, all
already present with no version pin conflict:
`ape, glmmTMB, lme4, MASS, metafor, ordinal, palmerpenguins`. Every one
resolved and loaded locally (`requireNamespace(..., quietly = TRUE)` all
`TRUE`).

`data(package = "<pkg>")$results` enumeration (full listing captured in the
scratch script output; summarised per-package below). Note that `metafor`
itself lists **no** package-local datasets (`data(package = "metafor")`
returns an empty `Item` column) — its example data moved to the `metadat`
package, which `metafor` `Depends` on and which is therefore reachable
without a new Suggests entry once `metafor` is loaded
(`library(metafor)` auto-attaches `metadat`).

## (b) Datasets shipped by drmTMB itself

`ls data/` and `ls inst/extdata/` in this worktree: **no `data/` directory
exists**, and `inst/extdata/` contains only `julia-capabilities.tsv` and
`julia-gates.tsv` (Julia engine capability ledgers, not example data).
drmTMB ships zero example datasets of its own; every vignette that shows
real-world data pulls from a Suggests package or simulates it with an
internal `simulate_*_guide_data()` helper (see `grep -n 'data(' vignettes/*.Rmd`
— every hit outside `bivariate-nongaussian.Rmd` is a `simulate_*()` call,
e.g. `animal-models.Rmd:298`, `relmat-known-matrices.Rmd:441`,
`spatial-models.Rmd:363`).

## (c) Datasets already used by existing vignettes

Only **one** real external dataset is currently used anywhere in
`vignettes/*.Rmd`:

- **`palmerpenguins::penguins`** — `vignettes/bivariate-nongaussian.Rmd:12,80-105`.
  Fits `family = drmTMB::biv_lognormal()` on
  `log(body_mass_g)` and `log(flipper_length_mm)` (a direct bivariate
  log-residual-correlation model; `rho12` is the point of the example),
  gated behind `has_penguins <- requireNamespace("palmerpenguins", quietly = TRUE)`.
  **PR 2 must not repeat this exact `biv_lognormal(body_mass_g, flipper_length_mm)`
  pairing** — a different response, family, or distributional axis (e.g. a
  univariate `sigma ~ species` model on `body_mass_g` alone, or a different
  variable pair) would not duplicate it, but reusing the identical bivariate
  fit would.

Every other vignette (`animal-models.Rmd`, `relmat-known-matrices.Rmd`,
`spatial-models.Rmd`, `phylogenetic-spatial.Rmd`, `meta-analysis.Rmd`, etc.)
uses internally simulated data, **including `meta-analysis.Rmd`**, whose
worked example (`vignettes/meta-analysis.Rmd:83,141,264,295,327` etc.) fits
`bf(yi ~ 1 + meta_V(V = vi), sigma ~ 1)` on a `dat` object that is simulated
in-vignette, not a real meta-analysis dataset — so a real `metadat`/`metafor`
effect-size dataset is free to use without duplicating anything.

## Candidate datasets

Structures below are from `str()` on each object, run in
`inspect_datasets.R` (scratch script, not part of the repo).

| Dataset | Source pkg | n (groups) | Response | Grouping var | Best-fit drmTMB family / distributional angle |
|---|---|---|---|---|---|
| `sleepstudy` | `lme4` | 180 (18 `Subject`) | `Reaction` (continuous, ms) | `Subject` | **Best pick.** `gaussian()`, `mu ~ Days + (1+Days\|Subject)`, `sigma ~ Days`. Real, well-known heteroscedasticity story (reaction-time variance grows with days of sleep deprivation) — a genuine `sigma` submodel demo, not a toy. Not used anywhere in the repo yet. |
| `cbpp` | `lme4` | 56 (15 `herd`) | `incidence`/`size` (binomial counts) | `herd`, `period` | `binomial()` or a beta-binomial/overdispersion family; classic overdispersed-binomial teaching example. Distributional angle: dispersion varying by `period`. Not used yet. |
| `Owls` | `glmmTMB` | 599 (27 `Nest`) | `SiblingNegotiation` (count) + `offset(log(BroodSize))` | `Nest`, `FoodTreatment` | `nbinom2()`/zero-inflated count family with a dispersion submodel `~ FoodTreatment`; classic glmmTMB teaching dataset, directly showcases drmTMB's count-family dispersion axis against a `glmmTMB::glmmTMB()` comparator fit. Not used yet. |
| `Salamanders` | `glmmTMB` | 644 (23 `site`, 7 `spp`) | `count` | `site`, `spp`, `mined` | `nbinom2()`/ZI count family with dispersion `~ spp`; the canonical glmmTMB zero-inflation dataset, good comparator target since `glmmTMB` ships the exact same model class. Not used yet. |
| `dat.bcg` | `metadat` (auto-attached by `library(metafor)`) | 13 (2×2 tables per trial) | needs `metafor::escalc()` to build `yi`/`vi` (log risk ratio + sampling variance) from `tpos/tneg/cpos/cneg` | `alloc` (random vs alternate allocation), `ablat` (latitude, continuous) | `gaussian()` + `meta_V(V = vi)`, with `sigma ~ alloc` — replaces the currently-simulated `meta-analysis.Rmd` example with a real, citable dataset (Colditz et al. 1994 BCG-vaccine meta-analysis) and gives that vignette a genuine subgroup-heterogeneity distributional story. Needs one extra call to `metafor::escalc()` (already a Suggests dependency) but no new package. |
| `wine` | `ordinal` | 72 (9 `judge`, 8 `bottle`) | `rating` (5-level ordinal) | `judge`, `temp`, `contact` | `cumulative_logit()` with a scale submodel `~ temp`; small, fast, classic proportional-odds teaching dataset (Randall 1989) with a real non-proportional-odds candidate covariate (`temp`), so it can motivate a `sigma`/scale term on the ordinal link. Not used yet. |
| `VerbAgg` | `lme4` | 7584 (316 `id`, 24 `item`) | `resp` (3-level ordinal) | `id`, `btype`, `situ`, `mode` | `cumulative_logit()`, large and crossed (subject × item), good for a random-intercept ordinal demo but not needed for the distributional-scale story; heavier fit (7584 rows) — subset before use to stay well inside the 5-minute fit budget. Not used yet. |
| `grouseticks` | `lme4` | 403 (118 `BROOD`, 63 `LOCATION`) | `TICKS` (count) | `BROOD`, `LOCATION`, `YEAR` | `nbinom2()`/ZI count family; classic Elston et al. 2001 overdispersion dataset, alternative to `Owls`/`Salamanders` if a non-glmmTMB-branded count example is preferred. Not used yet. |
| `penguins` | `palmerpenguins` | 344 (3 `species`, 2 `island`... ) | `body_mass_g`, `bill_length_mm`, etc. | `species`, `island`, `sex` | Already used (see §c) for the bivariate `rho12` demo. A *univariate* reuse (e.g. `lognormal(body_mass_g) ~ species, sigma ~ sex`) is possible without duplicating the existing bivariate fit, but starting from an unused dataset is cleaner for PR 2. |

## Recommendation

For a distributional (`sigma`) submodel demo that is (i) real, (ii) not
already used anywhere in the repo, (iii) fast (well under 5 minutes to fit),
and (iv) has an obvious external comparator:

1. **`lme4::sleepstudy`** — a Gaussian `mu`+`sigma` model
   (`sigma ~ Days`) directly demonstrates drmTMB's point of difference from
   plain `lme4::lmer()`, which cannot model residual-variance trends. Small
   (180 rows, 18 subjects), instantly fittable, and the reaction-time/sleep-
   deprivation variance story is well known to the target ecology/applied
   audience via the `lme4` teaching literature.
2. **`glmmTMB::Owls`** or **`metadat::dat.bcg`** as a second dataset if PR 2
   wants two worked examples: `Owls` gives a count-family dispersion
   submodel with a direct `glmmTMB` comparator fit; `dat.bcg` would replace
   the simulated data in `meta-analysis.Rmd` with a real, citable
   meta-analysis and adds a `sigma ~ alloc` heterogeneity story.

None of these require a new package: `lme4`, `glmmTMB`, and
`metafor`/`metadat` are already in `DESCRIPTION` Suggests (`DESCRIPTION:44,
48, 51`).

## Evidence trail

- `DESCRIPTION:39-59` — Suggests list.
- `data(package = "<pkg>")$results` per package (scratch script
  `/private/tmp/claude-503/.../scratchpad/list_metafor.R` and inline
  `-e` calls; not committed to the repo).
- `ls data/`, `ls inst/extdata/` in this worktree — no shipped datasets.
- `grep -n 'data(' vignettes/*.Rmd` — only `simulate_*_guide_data()` calls
  plus the one `palmerpenguins::penguins` use.
- `grep -n 'penguins' vignettes/bivariate-nongaussian.Rmd` — exact fitted
  model (`biv_lognormal()` on `body_mass_g`/`flipper_length_mm`).
- `grep -n 'metafor\|dat\.\|meta_V' vignettes/meta-analysis.Rmd` — confirms
  the meta-analysis vignette's `dat` is simulated in-vignette, not a real
  dataset, and that `metafor::rma()` is already used as an ML cross-check
  comparator at `vignettes/meta-analysis.Rmd:236-242`.
- `str()` output for `cbpp`, `sleepstudy`, `VerbAgg`, `grouseticks`, `Owls`,
  `Salamanders`, `wine`, `soup`, `dat.bcg`, `penguins` — captured in scratch
  script `/private/tmp/claude-503/.../scratchpad/inspect_datasets.R`
  (temporary file, not part of this repo).

## Not investigated further

`MASS` and `ape` were enumerated (`data(package = "MASS")`,
`data(package = "ape")`) but no candidate stood out over the picks above:
`MASS` datasets skew toward classic teaching examples without an obvious
sigma-submodel story better than `cbpp`/`sleepstudy`, and `ape`'s datasets
are phylogenetic trees/matrices without an attached response variable
suited to a distributional-regression demo (drmTMB's existing phylogenetic
vignettes already use `simulate_*_guide_data()` helpers for that role, not a
real trait+tree pairing from `ape`). If PR 2 later wants a real
phylogenetic comparator dataset, that is a separate, unscoped search.
