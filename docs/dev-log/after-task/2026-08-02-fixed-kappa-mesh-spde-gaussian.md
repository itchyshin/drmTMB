# After Task: Fixed-kappa mesh/SPDE Gaussian spatial capability

## 1. Goal

Add a projection-aware mesh/SPDE spatial route without changing the existing
dense `coords =` model, and keep every claim at its earned evidence tier.

## 2. Implemented

`spatial_coords()` converts longitude/latitude to an explicitly requested
projected CRS. `make_mesh()` constructs a validated `drmTMBmesh` with sparse
FEM matrices and observation projection `A_st`. The admitted model is exactly
univariate Gaussian ML `bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1)`.
Its TMB contribution is `A_st %*% omega`; it never uses a mesh-node index.

## 3a. Decisions and Rejected Alternatives

With fixed positive `kappa`, the raw precision is
`Q = kappa^4 C0 + 2 kappa^2 C1 + C2` and
`omega ~ N(0, s^2 Q^-1)`. `s` is reported as a raw GMRF field scale; the
projected marginal SD is location dependent. `kappa` is fixed configuration,
not an estimated range. The independent dense Gaussian marginal likelihood
uses `V = sigma_e^2 I + s^2 A Q^-1 A^T`.

The final implementation uses TMB's normalized
`density::SCALE(density::GMRF(Q, true), s)` expression, closely adapted from
gllvmTMB's GPL-3 SPDE prior with exact provenance in `inst/COPYRIGHTS`.  This is
algebraically identical to the original manual normalized density; drmTMB uses
direct covariance scale `s`, whereas gllvmTMB supplies reciprocal precision
scale `1 / tau`.

The slice rejects silent geographic projection, estimated range, a node-index
shortcut, mesh slopes, non-Gaussian or bivariate mesh likelihoods, REML, and
interval claims. The existing dense planar `coords =` route remains the
appropriate fitted alternative when its exponential covariance contract is
the scientific target.

## 4. Files Touched

The implementation adds `R/mesh.R`, mesh parser/fit/TMB plumbing, tests,
provenance, recovery receipts, and spatial documentation. Public reader paths
include the spatial, formula-grammar, structural-dependence,
phylogenetic-spatial, and model-map vignettes; pkgdown indexes both helpers.

## 5. Checks Run

- `devtools::test(filter = "mesh")`: 64 expectations, zero failures or warnings.
- Dense marginal-objective comparator, row alignment, CRS, malformed mesh,
  non-Gaussian, labelled, mesh-plus-coordinates, REML, and missing-data
  boundaries are exercised by the mesh contracts.
- An off-optimum joint-density contract compares the normalized native GMRF
  objective and gradients with the complete manual formula at three field
  scales, including its constants and both vertex and log-scale derivatives.
- `pkgdown::build_article("spatial-models")` against a temporary install of
  the current source: passed; the rendered page shows 27 vertices, 4
  observations, zero projection-row error, projected values, and profile
  status. Florence's follow-up audit replaced the invalid shared-unit SD axis,
  removed the q2 manual-scale warning, and retained honest point-only displays.
- The covariance registry, phylogenetic utility, and bivariate REML regression
  suites passed 510 expectations with zero failures or warnings after the
  native-density substitution.
- `pkgdown::check_pkgdown()`: passed after adding both new helpers to the
  reference index.
- Capability ledger and its 50 Python tests: passed after the final-source
  Totoro receipt was installed.
- Hosted PR Linux run 30753455095 passed on exact implementation head
  `0407ee370`; its package-check job 91511468246 completed successfully.
- On-demand three-OS run 30753479753 passed on the same head: Windows job
  91511534286, macOS job 91511534299, and Ubuntu job 91511534306 all completed
  successfully.

## 6. Tests of the Tests

The dense marginal likelihood is calculated outside the TMB random-effect
objective. Boundary tests directly reject routes that would widen the slice,
and the recovery receipt retains the clean-Hessian `n = 64` near-zero estimate
that makes the predeclared RMSE gate fail.

The direct density test keeps the latent field nonzero and evaluates multiple
off-optimum scale values, so it would detect a missing normalizer, reciprocal
scale, or derivative error even when an optimizer could compensate elsewhere.

## 7a. Issue Ledger

Issue #881 remains open. A comment records that the complete Totoro ladder
withheld point-fit recovery. PR #893 passed its exact-implementation-head Linux
and independent three-OS CI gates; the closeout-only commit is checked again
before the PR boundary is declared complete.

The same absolute-scale evidence gap is tracked for the sibling implementation
in gllvmTMB issue #904. Its current SPDE tests establish convergence, plausible
range, or scale-free structure, not recovery or calibrated uncertainty for the
absolute field scale.

## 8. Consistency Audit

`docs/dev-log/2026-08-02-mesh-spde-handover-reconciliation.md` records every
handover item as DONE, RETRACTED, PROTECTED, or OWED. Current reader surfaces
distinguish the exact mesh exception from wider mesh/SPDE work. The old dense
`coords =` route is separately documented and regression-protected. The article
is executable and uses `$projected` rather than calling mesh vertices sites.

## 9. What Did Not Go Smoothly

The initial C17-C1 compatibility receipt predates a later `R/drmTMB.R`
missing-data rejection. The capability-ledger guard correctly failed CI. A
fresh final-source Totoro control retained all 12 attempts and passed, then the
manifest was refreshed. A later rebase incorporated C17-C2 model-15 source
changes; GitHub's merge-ref guard again correctly rejected the stale
fingerprint before package checking, and a second fresh 12-attempt Totoro
receipt at `f0e7fbadf` passed before its C17-C2 manifest was refreshed. Final
reviews also found stale public “mesh planned” wording and one incorrectly
labelled article invariant; both were repaired.

Fresh closeout review then found that the first CI-fixture repair was too
narrow: seven tracked bivariate diagnostic tools also construct TMB objects
below `drm_fit_spec()`. Inert mesh DATA now enter centrally at builder level.
Gauss also required validation of the formula group as an observation label
and an explicit finite/small-gradient test; both were added without using the
group as a node index. Noether corrected the symbolic scale name and its use
throughout the normalized prior. The repaired tree received Gauss and Noether
GO verdicts.

That R-source repair invalidated the model-15 compatibility blob by design. A
fresh isolated Totoro checkout at `4bec20741` retained all 12 frozen attempts;
`mc-0568`, `mc-0569`, and `mc-0576` passed 4/4, and the C17-C2 manifest now
authenticates that exact source.

## 10. Known Residuals

The route is ML-only, fixed-kappa, univariate Gaussian `mu`, intercept-only,
and local-fit only. The recovery gate is **blocked** at `n = 64`; there are no
range, uniform marginal-SD, interval, coverage, slope, non-Gaussian, bivariate,
anisotropy, barrier, replicated, or spatiotemporal claims.

## 11. Team Learning

For a new structured route, update every status inventory and execute its
public example before treating a focused implementation as ready. A source-wide
receipt guard is useful only when it is rerun after every relevant source edit.

## 12. Cross-Product Coverage

The drmTMB source, tests, symbolic alignment, formula grammar, likelihood
design, capability/debt surfaces, exported helper documentation, pkgdown
article, gllvmTMB provenance, Totoro receipts, PR #893, and issue #881 all name
the same local-fit-only contract. The compatibility ledger separately proves
that central mesh DATA defaults leave its three authenticated model-15 routes
working; it does not transfer their evidence tier to the mesh model.
This arc does NOT cover REML, missing-response or predictor models,
aggregation, penalty/MAP fitting, Julia or bridge engines, range estimation,
scale/shape/coscale mesh fields, non-Gaussian or bivariate families, slopes,
anisotropy, barriers, replicated fields, spatiotemporal fields, intervals, or
coverage. Those providers and downstream surfaces remain at their prior status.

## Next Actions

Keep #881 open and retain the local-fit boundary unless a separately approved
recovery/design arc changes it. Merge and deploy PR #893 only after the final
closeout-only head is green; then verify the hosted spatial article.
