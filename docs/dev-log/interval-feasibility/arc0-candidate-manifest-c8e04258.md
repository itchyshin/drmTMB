# Arc 0 Current-Source Interval Candidate Manifest

## Frozen denominator

This manifest is derived from the immutable Git object
`c8e04258d9d550384b037b1e2a91734c22aaaab5`, not the modified working tree.
That source contains 100 `point_fit_recovery` rows; removing the 18
missing-response rows leaves 82 model-surface candidates. The earlier handover
said 81 because `mc-0578` landed before this source was reconciled.

| Execution class | Cells |
|---|---:|
| Promoted in this Codex arc | 5 |
| Retained STOP | 16 |
| Remaining executable | 18 |
| Profile-fenced | 23 |
| Estimator/row-structure hold | 4 |
| q12 excluded | 16 |
| **Total** | **82** |

Each cell has one selected primary direct target. A multiple-target cell keeps
sibling SD targets outside the primary claim; derived correlations never stand
in for a direct SD target.

## Promoted: five exact targets

| Cell | Estimator and direct target | Frozen fixture |
|---|---|---|
| `mc-0260` | ML `fixef:mu:x` | Gaussian location-scale, `n=240` |
| `mc-0262` | ML `fixef:sigma:x` | Same Gaussian location-scale fixture |
| `mc-0260m` | ML `fixef:mu:(Intercept)` | `meta_V`, `K=48`; heterogeneity SD excluded |
| `mc-0266` | ML `sd:sigma:(1 \| id)` | Gaussian sigma RE, `g=48`, `each=20` |
| `mc-0269` | REML `sd:mu:(0 + x \| id)` | Gaussian independent slope, `g=64`, `each=12` |

Every row has three immutable Totoro receipts. These are interval-existence
claims only; coverage and calibration remain withheld.

## Retained STOP: 16

These exact targets require a new information rung or interval-method design,
not another run of the same contract.

| Cells | Primary targets and binding failure |
|---|---|
| `mc-0273`, `mc-0286`, `mc-0298`, `mc-0310` | `sd:mu:{phylo,spatial,animal,relmat}(0 + x \| {species,site,id,id})`; retained Gaussian q1 slope tail/boundary/finite-interval failures |
| `mc-0275`, `mc-0288` | `sd:sigma:{phylo,spatial}(1 \| {species,site})`; retained boundary/profile failures |
| `mc-0289` | `sd:sigma:spatial(0 + x \| site)`; finite-Wald rate `0.936`, below the frozen `0.95` gate |
| `mc-0278`, `mc-0291`, `mc-0303`, `mc-0315` | matched Gaussian q2 primary `sd:mu:mu:{phylo,spatial,animal,relmat}(1 \| group)`; denominator/correlation-target failure |
| `mc-0279`, `mc-0292`, `mc-0304`, `mc-0316` | matched q2 primary `sd:sigma:sigma:{provider}(1 \| group)`; same retained failure |
| `mc-0438` | `sd:mu:phylo_interaction(1 \| plant:pollinator)`; nonfinite endpoints at both 8 and 20 observations per pair |

## Remaining executable ranking: 18

### Rank 2 — low-dimensional REML

- `mc-0186`: `rho12`; freeze `biv_reml_fixture(n=150)` from
  `tests/testthat/test-reml-bivariate.R`.
- `mc-0263`: `fixef:sigma:x`; freeze `reml_hetero_fixture()` and first assert
  that the sigma coefficient remains an active direct target under the exact
  REML specification.

### Rank 3 — Gaussian REML phylogenetic targets

- q1: `mc-0274` → `sd:mu:phylo(1 | species)`; `mc-0277` →
  `sd:sigma:phylo(1 | species)`.
- matched q2: `mc-0282` → `sd:mu:mu:phylo(1 | species)`; `mc-0283` →
  `sd:sigma:sigma:phylo(1 | species)`.

Use `reml_phylo_location_fixture()` from
`tests/testthat/test-reml-phylo-location.R`; keep q1 and q2 separate and use a
predeclared q2 information rung of at least 250 observations.

### Rank 4 — existing q6 spatial contract

- `mc-0123`: primary `sd:mu:mu1:spatial(1 | p | site)`; siblings are the direct
  `x` and `z` slope SDs. Use
  `tools/b2-q6-q12-admission-contracts.R:b2_q6q12_fixture`, spatial q6,
  `n=72`, `each=20`.

### Rank 5 — unattempted q1 family/provider cells

- `mc-0013`: `sd:mu:animal(0 + x | id)`; Beta-animal slope fixture.
- `mc-0015`: `sd:sigma:animal(1 | id)`; Beta sigma-animal fixture.
- `mc-0321`: `sd:mu:phylo_interaction(1 | plant:pollinator)`; Gaussian
  pair-level fixture.
- `mc-0409`: the same direct interaction target under NB2; rank below
  `mc-0321` because the same geometry already stopped for Poisson `mc-0438`.

### Rank 6 — NB2 sigma-provider cohort

- `mc-0421`, `mc-0422`, `mc-0423`, and `mc-0424` select
  `sd:sigma:{phylo,spatial,animal,relmat}(1 | {species,site,id,id})`.

Freeze four genuinely provider-specific intercept-only DGPs; the existing
phylo intercept-plus-slope recovery fixture cannot bind the other providers.

### Rank 7 — unresolved simultaneous-provider row

- `mc-0417` has no unique target: it aggregates any two of four providers.
  Bind or split the row before profiling. The proposed freeze is spatial plus
  relmat, with primary `sd:mu:spatial(1 | site)` and companion
  `sd:mu:relmat(1 | id)`.

### Rank 8 — bivariate ordinary REML block

- `mc-0205`: `sd:mu:mu1:(1 | p | id)`.
- `mc-0206`: `sd:sigma:sigma1:(1 | p | id)`.

The proposed `sim3()` DGP in `scratchpad/reml_parity_gaps_3A_ladder.R` must
first become a committed current-source fixture.

## Profile-fenced: 23

These targets are identifiable from the fitted model but deliberately have
`profile_ready=FALSE`; they require a new profile-policy goal.

- Count labelled q2: `mc-0418`, `mc-0436` →
  `sd:mu:phylo(0 + x | p | species)`; `mc-0446` → spatial/site;
  `mc-0450` → animal/site; `mc-0454` → relmat/site.
- Count sigma interactions: `mc-0425`, `mc-0653` →
  `sd:sigma:phylo_interaction(1 | plant:pollinator)`.
- Zero-one-beta ordinary RE: `mc-0568`, `mc-0569`, `mc-0570` → sigma, zoi,
  coi intercept SDs; `mc-0576`, `mc-0577`, `mc-0578` → their `0 + x` slope
  SDs.
- Zero-one-beta structured mu: `mc-0583`, `mc-0584`, `mc-0585`, `mc-0586`,
  and `mc-0587` → phylo, animal, relmat, spatial, and phylo-interaction
  intercept SDs.
- Zero-one-beta structured sigma: `mc-0593`, `mc-0594`, `mc-0595`, `mc-0596`,
  and `mc-0597` → the same provider
  order on sigma.

## Estimator or row-structure hold: four

- `mc-0182` (`fixef:mu1:x`), `mc-0183` (`fixef:mu2:x`), and `mc-0261`
  (`fixef:mu:x`) have no active direct target because Gaussian REML marginalizes
  the mean fixed effects. They need an estimator-aware interval method.
- `mc-0207` is unresolved: one representative row spans q4/q6/q8 labelled
  ordinary blocks and has neither a unique formula/target nor a committed
  fixture. Split it before targetwise work.

## q12 excluded: 16

All use `tools/b2-q6-q12-admission-contracts.R:b2_q6q12_fixture`. Direct SDs
exist, but q12 execution is explicitly outside this arc.

- `mc-0103`, `mc-0104`, `mc-0105`, and `mc-0106`: phylo/species primary intercept SDs for
  `mu1`, `mu2`, `sigma1`, `sigma2`.
- `mc-0125`, `mc-0126`, `mc-0127`, and `mc-0128`: the corresponding spatial/site targets.
- `mc-0147`, `mc-0148`, `mc-0149`, and `mc-0150`: the corresponding animal/id targets.
- `mc-0169`, `mc-0170`, `mc-0171`, and `mc-0172`: the corresponding relmat/id targets.

Each q12 row also has direct `x` and `z` slope-SD siblings. Dense-block
correlations are derived and cannot substitute for a direct target.

## Handoff rule

Claude should start at Rank 2 and select one exact target/fixture packet. It
must retain failures, use the one-profile immutable receipt contract, and seek
independent target-level review before promotion. It must not reopen the five
completed targets, execute q12, change a profile fence, run coverage, borrow B4
receipts, touch missing-response claims, or widen public guidance without a new
approved goal.
