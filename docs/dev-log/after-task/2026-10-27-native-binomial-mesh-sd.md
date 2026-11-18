# After Task: Native Binomial Mesh SD Slice

## 1. Goal

Add a first native R/TMB route for predictor-dependent SDs on a fixed-kappa spatial mesh intercept, with synthetic point-recovery and public-workflow checks.

## 2. Implemented

The Binomial builder now admits one mesh spatial location intercept with one matching `sd(site, level = "spatial") ~ predictors` formula. It requires complete responses, one location SD formula, and no other random effects. The route uses ML. The TMB likelihood multiplies the projected mesh field by the group-specific SD multiplier and maps out the unused scalar mesh SD parameter.

The fitted mesh stores a sparse Cholesky factor. Marginal simulation uses its permutation-aware precision draw, projects the field to observations, and applies the fitted SD by group. The formula reference and generated Rd page describe the route and its limits. The new test checks point recovery, SD prediction, marginal simulation, and save/reload reproducibility.

## 3a. Decisions and Rejected Alternatives

The synthetic latent field is drawn from the supplied GMRF precision without subtracting its mean. Centering changed the prior represented by the fitted model and let the broad mesh mode confound the fixed intercept. The mesh scale remains a multiplier on the supplied kernel; the implementation does not normalize the kernel.

This receipt covers the logit link only. Probit and complementary log-log mesh fits remain for a follow-up slice. No interval-coverage validation was run, consistent with the current implementation-first scope.

Assumptions made without asking: the first native mesh slice is limited to a single Binomial location intercept and complete responses. If this boundary is too narrow, the implementation and evidence rows need a new scoped extension.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/methods.R`
- `R/random-effect-scale-formulas.R`
- `man/random_effect_scale_formulas.Rd`
- `tests/testthat/test-binomial-mesh-sd-regression.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-mesh-sd-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-mesh-sd.md`
- `docs/dev-log/after-task/2026-10-27-native-binomial-mesh-sd.md`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "binomial-mesh-sd-regression|mesh-contract|binomial-phylo-sd-simulation")'`: PASS, 71 assertions, 0 failures, 0 warnings, 0 skips. Receipt: `docs/dev-log/general-sd-regression/evidence/native-binomial-mesh-sd-20261027/test-console.log`.
- Source hashes for the eight implementation and test files matched before and after the run. R 4.6.0; branch `codex/general-sd-regression`; HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: PASS, 19,230 candidate rows, 82 linked rows, 19,148 unlinked rows, 102 evidence records.
- `git diff --check` on the six edited source, test, and API-documentation files: PASS.
- The older Gaussian mesh checks passed 48/48, and the existing Binomial phylogenetic-SD simulation checks passed 11/11.

## 6. Tests of the Tests

The recovery test first failed when its simulated field was centered and the fitted model retained the broad constant mode. The revised generator draws from the fitted GMRF precision without centering. The marginal-simulation test then failed before the mesh draw was added, and public `simulate()` refused the modelled mesh SD. The final seeded draw is checked against the sparse factor and group-row mapping; the test also verifies save/reload reproducibility.

## 7a. Issue Ledger

No GitHub issue was inspected or updated in this slice. The issue scan remains open for the next task. The source-bound native logit row was linked in `direct-sd-evidence.tsv` with review status `unreviewed`; it is not an admission or calibration claim.

## 8. Consistency Audit

The new mesh test, existing Gaussian mesh contract, and existing Binomial phylogenetic-SD simulation tests were checked together. The frozen row for the native Binomial logit mesh spatial intercept now has a recovery evidence record. Probit/cloglog rows remain unverified. The R formula reference and generated Rd page now describe the single-intercept ML route.

The family article is held by the active documentation-audit lane. I sent that lane the exact scope and requested a short update. README, NEWS, the roadmap, known-limitations inventory, pkgdown rendering, profile, bootstrap, and a package-wide documentation check were not completed here.

## 9. What Did Not Go Smoothly

The first DGP centered the latent mesh field, which did not match the fitted precision model. The first sparse-draw oracle compared values from sparse and dense Cholesky factorizations using the same normal vector; their permutations differ, so that exact-value comparison was invalid. The corrected test checks the stored sparse factor identity and its own seeded draw. The marginal simulator also required explicit handling of the SD formula registry key versus its `mu` endpoint.

The lane lease registry did not return from one scoped claim/list attempt, so I stopped the list process. Preflight and liveness showed no active lease for this lane, and the user had assigned the SD implementation lane to me. The handoff gate reported 997 uncommitted paths and six unpushed commits in this worktree; it also listed unpushed history on other branches. All such work is carried over unchanged.

## 10. Known Residuals

This is one native Binomial logit mesh-intercept slice. It does NOT cover probit or cloglog recovery, spatial slopes, multiple random effects, incomplete responses, REML, other families, profile or bootstrap workflows, R-to-Julia bridge parity, or calibrated interval coverage. The direct Julia mesh route was not rerun in this slice. The overall SD-regression goal remains active.

The report does not claim package-level completion. A docs-audit response and updates to adjacent roadmap and NEWS surfaces remain pending. No code was committed or pushed.

## 11. Team Learning

For a mesh model whose precision permits a broad constant mode, generate test fields from the exact supplied precision and keep the fixed intercept in the fitted model. For repeated marginal draws, store the sparse Cholesky representation once and preserve its permutation; do not densify the mesh precision.

Memory receipt: read the project operating contract and efficiency protocol, the after-task audit skill, the local SD evidence ledger, and the current source spans. The route script found no LOAD-FIRST manifest. Golden Set: NOT RUN; this slice used a targeted pre-fix failure and a fixed-seed model-specific regression test.

Prose assessment: style 2/10, medium confidence. Genre and coverage: short technical after-task report, reviewed in full. Evidence and repair: the concrete counts and limits are tied to the saved run log and manifest; no further wording change was needed. Gates: science pass for the stated implementation behavior only; facts pass against the captured source and test outputs; references not applicable because the report has no literature claims. Provenance: self-review, 2026-10-27, no style controls used.

## 12. Cross-Product Coverage

Covers: native R/TMB Binomial logit with one fixed-kappa mesh spatial location intercept, point recovery, predictor-dependent SD prediction, marginal simulation, save/reload, and neighboring Gaussian mesh plus Binomial phylogenetic-SD regression checks.

This slice does NOT cover other Bernoulli links, Julia direct or bridge parity, spatial slopes, other response families or random-effect types, inferential coverage, or public release.
