# Codex handover — mesh closeout and spatial q2 Confidence Eye next arc

Date: 2026-08-02  
From: Codex  
To: Codex  
Repository: `drmTMB`  
Platform/lane: `PLATFORM: Codex | CURRENT LANE: fixed-kappa Gaussian mesh | NEXT LANE: dense coordinate-spatial q2 correlation intervals`  
Current branch: `codex/drmtmb-spatial-mesh`  
Current head before this handover commit: `94224d5180c714a872fda0274b6a92029879fa1c`  
Pull request: [#893](https://github.com/itchyshin/drmTMB/pull/893)  
Issue closed by the current arc: [#881](https://github.com/itchyshin/drmTMB/issues/881)  
Sibling evidence issue: [gllvmTMB #904](https://github.com/itchyshin/gllvmTMB/issues/904)

## Critical context

PR #893 is the fixed-kappa mesh/SPDE arc. It adds explicit longitude/latitude
projection into a caller-declared projected CRS, mesh construction, and exactly
one fitted mesh route: a univariate Gaussian `mu` intercept. The observation
field is `A_st %*% omega`; `site` is a formula label, never a mesh-node index.
The existing dense planar `coords=` covariance route is preserved.

The next requested capability is mathematically distinct. The Confidence Eye
shown in `vignettes/spatial-models.Rmd` concerns the latent correlation between
two **dense coordinate-spatial q2 location fields**. It is not a mesh parameter,
and the point-recovery evidence used to close #881 does not calibrate that
correlation interval. Do not draw an interval merely because profile mechanics
return finite endpoints. The next lane must prospectively validate the exact
q2 correlation estimand before changing the article from point-only.

At handover, fetched `origin/main` is
`a34bb75092c7733e5d65e4bf427895b4318ced7c`, which includes merged PR #897.
The mesh branch is 28 main commits behind and 29 commits ahead, with merge base
`83055ec5846bc2f9b1d939c13aa16c4500181f04`. Reconcile #893 in its own lane;
do not start the q2 interval arc on this branch.

## Accomplished

- Added `spatial_coords()` with explicit projected-output CRS and fail-closed
  geographic-coordinate checks.
- Added `make_mesh()` and the validated `drmTMBmesh` contract, including sparse
  `A_st`, FEM matrices, alignment identifiers, CRS/units, and fixed positive
  `kappa`.
- Added the univariate Gaussian `spatial(1 | site, mesh = mesh)` `mu` intercept
  implementation and its sparse TMB objective.
- Preserved and regression-tested the dense planar `coords=` route.
- Recorded exact gllvmTMB PR #886 provenance, merge
  `01a3b1103e1b3fe5fdf5d27826349d5bc6f4f040`, GPL-3, and adapted source paths
  in `inst/COPYRIGHTS`.
- Retained the invalid V2 and first V3 attempts as falsifying evidence; the
  corrected V3 campaign used disjoint seeds and authenticated source receipts.
- Earned exact-domain field-SD `point_fit_recovery`: 100/100 valid Totoro fits,
  50 each at `n = 128` and `n = 256`. At `n = 128`, log-scale bias was
  -0.03008 with CI [-0.06572, 0.00556] and RMSE 0.14442; at `n = 256`, bias was
  -0.009627 with CI [-0.03746, 0.01821] and RMSE 0.10092. This is not a blanket
  `n >= 128` claim.
- Closed #881 at its earned point-recovery scope and updated the spatial article,
  README, roadmap, capability surfaces, limitations, and check log.
- Re-rendered the local article without the earlier manual-scale warning. The
  coordinate-spatial q2 correlation figure remains deliberately point-only.

## Locked boundaries

- Fixed `kappa` is configuration, not an estimand, profile target, or range
  estimate.
- The fitted mesh field SD is the sole first-slice mesh estimand.
- No mesh slopes, non-Gaussian mesh likelihoods, bivariate mesh fields,
  anisotropy, barriers, spatiotemporal fields, replicated fields, or range
  estimation.
- Raw longitude/latitude degrees are not passed directly to `make_mesh()`.
- The dense `coords=` route is protected from reparameterization or replacement.
- The q2 correlation article remains point-only until a prospective interval
  calibration gate passes.

## Landing state

| Item | State |
| --- | --- |
| Fixed-kappa mesh implementation | DONE on PR #893 |
| Exact-domain mesh field-SD point recovery | DONE |
| Issue #881 | DONE / closed |
| Dense `coords=` route | PROTECTED |
| Mesh interval/coverage inference | RETRACTED from this arc |
| q2 latent-correlation Confidence Eye | OWED in a fresh, separate lane |
| PR #893 merge/reconciliation with current main | OWED before the new lane starts |
| Range, slopes, non-Gaussian/bivariate mesh, anisotropy, barriers, space-time | PROTECTED / deferred |

## Checks and receipts

- Mesh focused tests: 87 passed, 0 failed.
- Protected dense spatial regression tests: 292 passed, 0 failed.
- Corrected V3 recovery contract: 100/100 retained valid fits; all optimizer
  convergence codes zero, all `pdHess = TRUE`, finite objectives/estimates, and
  maximum gradients no larger than `1e-3`.
- Article rebuilt successfully with no rendered warning text.
- GitHub R-CMD-check run
  [30763681382](https://github.com/itchyshin/drmTMB/actions/runs/30763681382)
  for #893 was still in progress at the handover snapshot; the earlier full
  branch run 30760659270 succeeded. Recheck the newest run before merge.
- After-task report:
  `docs/dev-log/after-task/2026-08-02-mesh-spde-point-recovery.md` passes the
  external after-task validator.
- `git diff --check` passed before the final documentation commit.
- Curie authenticated the corrected campaign; Fisher approved the exact-domain
  point-recovery promotion. Florence's figure review keeps uncertainty absent
  where it has not been calibrated.

## Files changed by PR #893

Run `git diff --name-only origin/main...origin/codex/drmtmb-spatial-mesh` after
fetching to reproduce the exact live list. The handover-relevant paths are:

- Package/API/TMB: `DESCRIPTION`, `NAMESPACE`, `R/check.R`, `R/drmTMB.R`,
  `R/mesh.R`, `R/profile.R`, `src/drmTMB.cpp`, `man/drmTMB.Rd`,
  `man/make_mesh.Rd`, `man/spatial_coords.Rd`, `inst/COPYRIGHTS`.
- User surface: `NEWS.md`, `README.md`, `ROADMAP.md`, `_pkgdown.yml`,
  `vignettes/formula-grammar.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/phylogenetic-spatial.Rmd`, `vignettes/spatial-models.Rmd`, and
  `vignettes/structural-dependence.Rmd`.
- Design and status: `docs/design/01-formula-grammar.md`,
  `docs/design/03-likelihoods.md`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/16-phylo-spatial-common-math.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/dev-log/known-limitations.md`, `docs/dev-log/check-log.md`, and
  `docs/dev-log/team-improvements.md`.
- Mesh design/evidence notes: every `2026-08-02-mesh-spde-*.md` file directly
  under `docs/dev-log/`, both mesh after-task reports under
  `docs/dev-log/after-task/`, and
  `docs/dev-log/figure-audits/2026-08-02-spatial-models-mesh.md`.
- Evidence tables: the two `c17c*-c14-current-source-compatibility.tsv` files
  under `docs/dev-log/dashboard/capability-ledger/`; every file under the six
  `docs/dev-log/implementation-recovery/2026-08-02-mesh-spde-*` directories;
  and every file under the four
  `docs/dev-log/simulation-artifacts/2026-08-02-mesh-spde-*` directories.
- Tests: `tests/testthat/test-covariance-block-registry.R`,
  `test-gaussian-location-scale.R`, `test-mesh-contract.R`,
  `test-mesh-helpers.R`, `test-mesh-recovery-v3-contract.R`,
  `test-phylo-utils.R`, and `test-reml-bivariate-spatial-q2.R`.
- Campaign tooling: `tools/mesh-spde-recovery-v3-helpers.R` and the four
  `tools/run-mesh-spde-*.R` runners.
- Handover: this file and the current `AGENTS.md` snapshot block.

## Mission-control reconciliation

| Requested item | Classification | Evidence / action |
| --- | --- | --- |
| Five-row mesh symbolic alignment | DONE | `docs/dev-log/2026-08-02-mesh-spde-symbolic-alignment.md` |
| Fixed-kappa first-slice contract | DONE | design, parser, helper, TMB, and recovery tests |
| Exact gllvmTMB #886 provenance | DONE | `inst/COPYRIGHTS`; sibling issue #904 |
| Failing contract tests before C++ | DONE historically | retained in branch history; implementation followed review |
| Preserve dense `coords=` | PROTECTED | regression suite green; do not replace it |
| Issue #881 point-estimate question | DONE | exact-domain point recovery earned; issue closed |
| Confidence interval in the q2 article figure | OWED | separate symbolic, profile, calibration, and coverage gate |
| Turn on `interval = TRUE` now | RETRACTED | finite endpoints alone are not calibrated inference |
| Treat mesh recovery as q2-correlation evidence | RETRACTED | different model and estimand |
| Reuse invalid proposal `50770c579` or erase `n = 64` failure | RETRACTED | falsifying receipts remain immutable |
| Start the next arc in the mesh worktree | RETRACTED | wait for #893, then use fresh `origin/main` |
| Mesh extensions beyond the first slice | PROTECTED | require new symbolic contracts and evidence arcs |

## Next immediate steps

1. Verify PR #893 is green and mergeable. Finish only its reconciliation with
   current `origin/main`; do not mix q2 interval work into #893.
2. After #893 merges, fetch the new `origin/main` and create a fresh worktree
   and branch for `codex/spatial-q2-confidence-eye`.
3. Run lane preflight. Reconcile current main, merged PR #897, open PRs, this
   handover, and the existing q2 coordinate-spatial profile/coverage evidence.
4. Classify every candidate task as OWED, DONE, RETRACTED, or PROTECTED before
   editing.
5. Use the ultra-plan method for the new arc. First freeze the five-row symbolic
   alignment for the exact dense-coordinate q2 latent-correlation estimand,
   keeping it distinct from residual `rho12`, observed response correlation,
   and every mesh quantity.
6. Inventory the current `corpairs()`/profile/Confidence Eye contracts and
   define a prospective coverage/calibration gate. Ask whether the campaign
   should run on Totoro or DRAC before any repeated simulation; never use GitHub
   Actions for recovery or coverage.
7. Stop for Noether and Fisher review before implementation or compute. Update
   `vignettes/spatial-models.Rmd` only if the exact interval gate passes. Then
   obtain Florence review of the rendered figure.

## Blockers and questions

- The new lane is blocked until PR #893 is merged and the fresh branch is based
  on the resulting `origin/main`.
- The exact q2 interval method and coverage domain are not yet approved. This
  handover authorizes planning and reconciliation, not implementation or a
  campaign launch.
- GitHub API rate limits were exhausted during the current session. Recheck the
  public PR/check state directly at resume rather than inferring it from this
  snapshot.

## Foreign and protected repository state

The handoff gate reports 430 commits on unrelated local branches that are not
on `origin/main`. They are not owned by this handover. Do not alter, rebase,
stage, merge, or delete them: `claude/arc-a-external-comparator-evidence`,
`claude/handover-freshness-0718`, `codex/aoi2-drac-recovery`,
`codex/arc-d-design1-overflow-guard`, `codex/arc6-6-bernoulli-nb2-plan`,
`codex/b4-ci-c1-exact-24`, `codex/capability-taxonomy-backlog`,
`codex/lane-b-q1-preflight-admission`, `codex/lane-c-c12-ci-repair`,
`codex/lane-c-c13-zinb-sigma-predictor`,
`codex/lane-c-c14-canonical-integration`,
`codex/lane-c-implementation-recovery`,
`codex/lane-c-provider-cohort-20260729`,
`codex/sd-bootstrap-r999-diagnosis`, `codex/staged-eta-godambe-se`, and
`hopper/bridge-finish-phase15-5`. Recent Claude-originated main merges also mean
lane-preflight silence cannot be treated as sole ownership.

## How to resume

First finish #893 in its existing lane:

```sh
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin
git worktree list
cd /private/tmp/drmtmb-spatial-mesh
/Users/z3437171/shinichi-brain/tools/lane_preflight.sh .
git status --short --branch
git diff --check
```

Only after #893 is merged, start the new arc from fresh main:

```sh
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin
git worktree add -b codex/spatial-q2-confidence-eye /private/tmp/drmtmb-spatial-q2-ci origin/main
cd /private/tmp/drmtmb-spatial-q2-ci
/Users/z3437171/shinichi-brain/tools/lane_preflight.sh .
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "spatial")'
```

## Paste-ready continuation prompt

> Work in drmTMB. Read AGENTS.md and docs/dev-log/handover/2026-08-02-codex-handover.md. First verify and finish PR #893 without widening it. After #893 merges, start a fresh worktree from current origin/main and ultra-plan the coordinate-spatial q2 latent-correlation interval-calibration arc needed for the spatial-models Confidence Eye. Reconcile merged PR #897 and all existing profile/coverage evidence; classify every item as OWED, DONE, RETRACTED, or PROTECTED; freeze the five-row symbolic estimand and prospective coverage gate; and stop for Noether/Fisher review before implementation or compute. Keep the dense coords= route protected. Do not modify the mesh model, estimate range, add slopes, or widen other spatial surfaces. Update the article only if calibration passes, then obtain Florence review.
