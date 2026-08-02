# Session Handoff: drmTMB mesh/SPDE Gaussian intercept

Meta: 2026-08-01 · from Codex to the drmTMB Codex/team · planning handover only

You are Codex, picking up a new, bounded drmTMB implementation lane. Read this
document after `AGENTS.md`; do not infer state from the chat that created it.

## Critical Context

The goal is the first independently owned mesh/SPDE route in drmTMB:

```r
drmTMB(
  bf(y ~ x + spatial(1 | site, mesh = mesh)),
  family = gaussian(),
  data = dat
)
```

Keep the first slice univariate, Gaussian, `mu`, and intercept-only. drmTMB
already fits coordinate-based `spatial(..., coords = coords)` effects using a
dense exponential covariance in `drm_spatial_coords_precision()`. That route is
live and must not be silently replaced. The new mesh route needs a sparse
observation-to-vertex projection, so it cannot be implemented by merely passing
a new precision matrix through the existing one-node-per-observation index.

Shinichi made the separate provenance decision on 2026-08-01 that drmTMB may
reuse or closely adapt the independently authored GPL-3 spatial-helper code in
gllvmTMB. Record the exact source files and commit in `inst/COPYRIGHTS` in the
same implementation slice. This permission does not make sdmTMB a dependency
or a code source. sdmTMB may remain a courtesy inspiration and an isolated
post-implementation black-box comparator only.

## Goal and Earned Scope

Deliver issue [#881](https://github.com/itchyshin/drmTMB/issues/881) as a small
first mesh/SPDE capability with:

- a documented `drmTMBmesh` object contract;
- triangular mesh construction or acceptance of a supplied `fm_mesh_2d`;
- sparse `A_st` projection and `c0`, `g1`, `g2` finite-element matrices;
- explicit observation/data/mesh alignment and CRS guidance;
- one univariate Gaussian `mu` random-intercept fit;
- spatially named `ranef()`, `sdpars`, `profile_targets()`, and `check_drm()`
  output at the evidence tier actually earned;
- parser, malformed-input, sparse-algebra, minimal-fit, comparator, and field-SD
  recovery evidence.

This handover does not authorize slopes, bivariate fields, scale/shape fields,
non-Gaussian mesh models, barriers, anisotropy, replicated or spatiotemporal
fields, direct-SD/corpair regression, or interval/coverage claims.

## Existing drmTMB Boundary

The formula parser already accepts exactly one of `coords =` and `mesh =` in
`R/parse-formula.R`, while the fit path rejects `mesh =` in
`extract_gaussian_mu_spatial_term()` and `build_spatial_mu_structure()` in
`R/drmTMB.R`. The public marker and its planned example are in
`R/formula-markers.R`.

The current coordinate route constructs a dense exponential covariance,
inverts it, and passes the resulting sparse `Q_phylo` plus
`log_det_Q_phylo` into the generic structured-field machinery. It maps each
observation to one site node through `phylo_mu_node_index`. A mesh route instead
requires

\[
u(s_i) = A_i\omega,
\qquad
Q(\kappa) = \kappa^4 M_0 + 2\kappa^2 M_1 + M_2,
\]

where `A` is the observation-to-vertex projection and `M0/M1/M2` correspond to
fmesher `c0/g1/g2`. Therefore write the symbolic R-to-TMB alignment before
editing C++ and add a distinct mesh data path. Do not overload
`observation_node_index` with barycentric weights.

Issue #881 explicitly defers range changes. The safest first contract is to
estimate the field SD while fixing `kappa` through an explicit, documented mesh
setting. If the team instead wants to estimate `log_kappa_spde`, stop and amend
the issue/plan first: that is a larger likelihood and inference surface, and it
must not arrive accidentally by copying gllvmTMB's parameter plumbing.

## Authoritative gllvmTMB Source

The helper rewrite landed in gllvmTMB PR
[#886](https://github.com/itchyshin/gllvmTMB/pull/886), merge commit
`01a3b1103e1b3fe5fdf5d27826349d5bc6f4f040`. It is independently authored
gllvmTMB GPL-3 code based on the Lindgren-Rue-Lindstrom SPDE construction and
public fmesher/sf APIs; it contains no adapted sdmTMB source.

Read these files from that exact commit first:

1. `gllvmTMB/R/mesh.R` — mesh construction, validation, deterministic k-means,
   cutoff search, supplied-mesh handling, FEM/projection construction, and plot
   method;
2. `gllvmTMB/R/crs.R` — CRS and UTM helpers;
3. `gllvmTMB/tests/testthat/test-mesh.R` and
   `gllvmTMB/tests/testthat/test-utm-conversions.R` — behavioural contract and
   malformed-input matrix;
4. `gllvmTMB/docs/dev-log/research/2026-08-01-independent-spatial-helper-literature.md`
   — literature/API specification;
5. `gllvmTMB/docs/dev-log/after-task/2026-08-01-independent-spatial-helpers.md`
   — implementation, provenance, test, and limitation receipt;
6. `gllvmTMB/dev/verify-sdmtmb-spatial-oracle.R` — optional isolated
   post-implementation behavioural comparison.

Also read drmTMB's existing gate in
`docs/design/09-phylogenetic-and-spatial-speed.md` and the common-math map in
`docs/design/16-phylo-spatial-common-math.md`. They correctly require a sparse
projection-aware route, but parts of their gllvmTMB source map predate PR #886:
references to `inst/tmb/gllvmTMB_multi.cpp` and `R/spde-keyword.R` are stale, and
the old wording asks users to cite sdmTMB precedent. Repair those entries in the
implementation documentation cascade. The current policy is an optional
courtesy acknowledgement to sdmTMB, not a required citation.

For engine architecture only, inspect `gllvmTMB/src/gllvmTMB.cpp` around
`A_proj`, `spde_M0/M1/M2`, and `log_kappa_spde`, plus the matching assembly in
`gllvmTMB/R/fit-multi.R`. Adapt only the univariate pieces required by the
drmTMB contract. Do not port gllvmTMB's multi-trait `indep`, `dep`, `latent`, or
slope-field machinery.

## Reuse and Provenance Rules

Reuse should be deliberate, not a wholesale file copy:

- rename the public class to `drmTMBmesh` and use drmTMB-scoped internal helper
  names;
- retain the observable invariants: fields `loc_xy`, `xy_cols`, `mesh`, `spde`,
  `loc_centers`, and `A_st`; sparse finite square `c0/g1/g2`; conformable
  dimensions; finite entries; projection rows summing to one;
- remove the gllvmTMB-only `sdmTMBmesh` lifecycle bridge unless drmTMB has a
  real legacy-object need;
- keep `fmesher` in `Suggests` for the first slice, with a clear missing-package
  error, as issue #881 specifies;
- decide separately whether `sf` is needed in the first fitting slice or only a
  later CRS helper/docs slice;
- add a precise `inst/COPYRIGHTS` entry naming gllvmTMB PR #886, merge commit,
  source paths, GPL-3, and the adaptations made;
- cite Lindgren, Rue, and Lindstrom (2011) and relevant fmesher documentation in
  method-facing docs. A courtesy acknowledgement to sdmTMB is welcome, but it
  is not a required citation and must not imply code inheritance.

## Implementation Plan

### Slice 0 — freeze math, API, and provenance

Write a five-row symbolic alignment covering data-generating equation, fitted
equation, R syntax, R data fields, and TMB objective. Decide and document the
fixed-`kappa` first-slice contract before code. Add failing parser/fit tests for
the exact admitted and rejected syntax. Record the gllvmTMB reuse decision in
`inst/COPYRIGHTS` at the start, not at closeout.

### Slice 1 — mesh helper contract

Adapt the bounded helper surface from gllvmTMB into a new `R/mesh.R`. Export
`make_mesh()` only if the repo has no naming collision and Boole approves the
API; otherwise use a drmTMB-specific public name. Add roxygen, generated Rd,
NAMESPACE, `DESCRIPTION` Suggests, missing-dependency messaging, and tests for:

- default/cutoff, deterministic k-means, cutoff-search, and supplied-mesh modes;
- missing, duplicated, collinear, and non-finite coordinates;
- invalid `cutoff`, `n_knots`, and supplied mesh;
- sparse/conformable/finitely valued FEM matrices;
- sparse projection with one row per model observation and row sums of one;
- caller RNG preservation and deterministic seeded output.

### Slice 2 — one mesh field in the TMB contract

Create a distinct mesh branch in `build_spatial_mu_structure()`. Marshal
`A_st`, `M0`, `M1`, `M2`, the fixed `kappa`, and the mesh vertex count without
changing the existing dense-coordinate path. In `src/drmTMB.cpp`, add the
minimal univariate Gaussian field contribution `A_st * omega` and the matching
GMRF normalization. Name the latent mesh field and SD outputs consistently with
the existing `spatial_mu` public surface.

Do not reuse the existing `Q_phylo`/node-index route unless a mathematical
review proves an exactly equivalent sparse projection representation. A dense
`A_st %*% Q^{-1} %*% t(A_st)` shortcut would defeat the scalable goal.

### Slice 3 — evidence and public surface

Add:

- parser rejection tests for every deferred neighbour;
- a minimal real TMB fit using `spatial(1 | site, mesh = mesh)`;
- a small-mesh sparse-vs-dense covariance/objective comparator;
- alignment tests that permute data rows and site labels;
- `ranef("spatial_mu")`, `sdpars`, `profile_targets()`, and `check_drm()` tests;
- a CRAN-safe multi-seed field-SD recovery smoke with the true fixed `kappa`;
- one Tier-1 pkgdown example that prints summaries/dimensions, never the full
  sparse matrices or full mesh object.

If recovery needs a formal grid, stop after the local smoke and ask whether to
run it on Totoro or DRAC. Do not use GitHub Actions for a simulation campaign.

### Slice 4 — verification and closeout

Run focused tests, `devtools::document()`, `pkgdown::check_pkgdown()`, the
affected article render, full tests, and `devtools::check(args =
"--no-manual")`. Invoke Boole on formula/API, Gauss and Noether on the TMB and
mathematical alignment, Curie on recovery/comparator tests, Grace on
dependency/CRAN concerns, Pat on the worked example, and Rose on provenance and
cross-file consistency. Update the validation-debt register at the exact earned
tier; point-fit or recovery evidence does not authorize intervals or coverage.

## Files Expected to Change

This is a forecast, not permission to stage broadly:

- `R/mesh.R` (new), `R/formula-markers.R`, `R/parse-formula.R`, `R/drmTMB.R`;
- `src/drmTMB.cpp`;
- `DESCRIPTION`, `NAMESPACE`, `inst/COPYRIGHTS`, generated `man/*.Rd`;
- focused `tests/testthat/test-mesh*.R` plus the existing spatial parser/fit,
  extractor, profile-target, and diagnostic tests;
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
  `docs/design/05-testing-strategy.md`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/16-phylo-spatial-common-math.md`, and
  `docs/design/34-validation-debt-register.md`;
- one pkgdown article or a bounded spatial section, `_pkgdown.yml` if needed,
  `docs/dev-log/check-log.md`, and an after-task report.

Before editing shared files, rerun `gh pr list --state open` and the recent-log
lane preflight. Keep the implementation PR small enough to review; if the
helper/API and likelihood changes become too large, land the helper contract
first without advertising a fitted mesh model.

## What Was Accomplished

- Confirmed issue #881 is open and already carries the intended narrow scope.
- Inspected current drmTMB parser, dense coordinate precision, TMB data path,
  public extractors/diagnostics, tests, and provenance policy.
- Found stale pre-PR-#886 gllvmTMB paths and a stale required-sdmTMB-citation
  sentence in drmTMB's existing mesh design notes; these are documentation debt
  for the implementation cascade, not evidence that current code depends on
  sdmTMB.
- Confirmed gllvmTMB PR #886 is the independently authored, GPL-3 helper source.
- Recorded Shinichi's explicit permission to reuse/adapt that code with
  provenance.
- Produced this implementation-ready handover. No drmTMB feature code changed.

## Current Working State

- Working: existing `spatial(..., coords = coords)` routes on current drmTMB
  `main`; gllvmTMB helper implementation at merge commit `01a3b110...`.
- In progress: none in this handover lane; implementation has not begun.
- Planned/rejected today: `spatial(..., mesh = mesh)` still fails with the
  intentional "mesh fitting is planned" error.

## Key Decisions and Rationale

1. **Reuse gllvmTMB helper code with provenance.** Shinichi owns both GPL-3
   packages and explicitly authorized the reuse; naming the exact source commit
   is clearer and safer than re-deriving already independent code.
2. **Preserve the dense coordinate route.** It supports a broad existing drmTMB
   surface and has different covariance semantics. The mesh route is additive,
   not a replacement.
3. **Use a distinct projection-aware TMB path.** `A_st` contains barycentric
   weights, so the current one-node index cannot represent the mesh field.
4. **Keep range estimation outside the first issue slice.** This matches issue
   #881's deferral. Any decision to estimate `kappa` must amend the plan before
   C++ work.
5. **Split helper and likelihood PRs if reviewability deteriorates.** A landed,
   tested helper contract may precede model advertising; a half-reviewed TMB
   change may not.

## Files Created or Modified in This Handover

- Created
  `docs/dev-log/handover/2026-08-01-codex-mesh-spde-handover.md`.
- Deliberately did not edit `AGENTS.md`: six active PR lanes were visible and
  the repo has no single current Active-Lane-Split pointer that this lane could
  safely replace.
- No R, C++, test, generated documentation, package metadata, dashboard, or
  public-site file changed.

## Next Immediate Steps

1. Fetch current `origin/main`, inspect issue #881 and every open PR, and mark
   the items in this handover `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`.
2. Write the five-row symbolic alignment and make the fixed-`kappa` choice
   explicit in the design record.
3. Add the exact gllvmTMB PR #886 provenance entry and failing contract tests.
4. Implement only Slice 1, then review its API and dependency boundary before
   the TMB slice begins.
5. Stop for Gauss/Noether review before changing `src/drmTMB.cpp`.

## Landing State

The pre-write handoff gate reported unrelated historical/local unpushed
branches elsewhere in drmTMB. This handover neither owns nor modifies them.
The primary Dropbox checkout was dirty and protected; all work here used the
isolated worktree `/private/tmp/drmtmb-mesh-spde-handover-20260801` from
`origin/main`, reconciled through `d341f0210` before commit.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| drmTMB `codex/drmtmb-mesh-spde-handover` | pending | pending | pending | CARRIED-OVER until this documentation PR is opened |
| gllvmTMB helper PR #886 / merge `01a3b110...` | yes | yes | #886 merged | LANDED source |
| gllvmTMB spatial-guide PR #892 / merge `e51122c7...` | yes | yes | #892 merged | LANDED reader guide |

Six drmTMB PRs were open during orientation (#890, #889, #888, #887, #869,
#858); #887 merged as `d341f0210` before this handover was committed. None owns
this mesh/SPDE subject, but several touch shared documentation. Do not rebase or
edit those branches from this lane.

## Mission Control

| Repository | Branch/base | CI and shipped state | Highest-leverage next action |
|---|---|---|---|
| gllvmTMB | `main`, helper merge `01a3b110...`, guide merge `e51122c7...` | Independent mesh/CRS helpers and compact spatial article landed | Treat PR #886 as the source baseline; use the final article only as reader guidance |
| drmTMB | `codex/drmtmb-mesh-spde-handover` from `d341f0210` | Handover only; no feature or CI claim | Start Slice 0 with symbolic alignment and a fixed-`kappa` decision |

## Blockers and Open Questions

There is no blocker to planning or helper adaptation. Before C++ implementation,
the team must affirm the issue-consistent fixed-`kappa` contract. Estimating
range would expand the slice and requires an amended plan and evidence surface.

The repo has active parallel lanes and no single current Active-Lane-Split
pointer in `AGENTS.md`. This handover therefore deliberately does not replace
the existing snapshot pointer; doing so would orphan other work.

## Gotchas and Failed Approaches

- A mesh projection is not a node index. Do not coerce barycentric weights into
  the current `phylo_mu_node_index` interface.
- Do not replace the established dense `coords =` route while adding `mesh =`.
- Do not print a mesh object or sparse matrices in the public article; show a
  plot and compact dimension/invariant summaries.
- Do not copy gllvmTMB's legacy sdmTMB class bridge or multi-trait covariance
  machinery into drmTMB.
- Do not describe sdmTMB as a dependency or inherited code source.
- Do not treat a passing point fit as range, interval, or coverage validation.

## How to Resume

From a fresh Codex task rooted at drmTMB, paste:

> Read `AGENTS.md` and `docs/dev-log/handover/2026-08-01-codex-mesh-spde-handover.md`. Run the lane preflight, reconcile the handover with current `origin/main` and issue #881, classify each requested item as OWED/DONE/RETRACTED/PROTECTED, and begin only Slice 0: symbolic alignment, fixed-kappa decision, provenance entry, and failing contract tests. Do not implement slopes, non-Gaussian mesh models, anisotropy, or range estimation.

Codex owns the live R/TMB work: compile, fit, compare, test, render, and check.
Use the mirrored `.codex/agents/*.toml` reviewers at the bounded gates above.
