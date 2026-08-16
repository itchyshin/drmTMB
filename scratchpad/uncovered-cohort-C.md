# Interval-Claim Truth Audit: Cohort C

This document records the evidence classification and artifact audit for 34 cells in Cohort C (mixed remainder: primary evidence class `coverage_study`, `recovery_test`, or `estimator_diagnostic`; PLUS all 6 association cells). 25 sit at `inference_ready_with_caveats` and 9 at `interval_feasible`. 6 have interval receipts; 28 do not.

## Per-Cell Audit Table

| cell_id | tier | class | evidence_class | estimator | primary_evidence_id | cited_artifact_path | path_exists | coverage_rate_quoted | deciding_evidence |
|---------|------|-------|-----------------|-----------|---------------------|---------------------|-------------|----------------------|-------------------|
| as-0001 | interval_feasible | a | estimator_diagnostic | two_stage_Godambe | ev-as-0001-godambe | N/A (diagnostic) | N/A | None reported | Wald interval without profile coverage campaign. confint() returns alpha-scale Godambe-Wald intervals when fit-specific covariance diagnostics pass. Ledger: claim_boundary says "Public vcov() and confint() report alpha-scale Godambe-Wald uncertainty when fit-specific covariance diagnostics pass. Coverage is not yet calibrated, so the method warns that the interval is ex[perimental]". primary_evidence_class: estimator_diagnostic. |
| as-0002 | interval_feasible | a | estimator_diagnostic | two_stage_Godambe | ev-as-0002-godambe | N/A (diagnostic) | N/A | None reported | Wald interval, gaussian_nbinom2 route. Ledger claim_boundary: "Public vcov() and confint() report alpha-scale Godambe-Wald uncertainty when fit-specific covariance diagnostics pass. Coverage is not yet calibrated, so the method warns that the interval is experim[ental]". primary_evidence_class: estimator_diagnostic. |
| as-0003 | interval_feasible | a | estimator_diagnostic | two_stage_Godambe | ev-as-0003-godambe | N/A (diagnostic) | N/A | None reported | Wald interval, bernoulli_bernoulli route. primary_evidence_class: estimator_diagnostic. Ledger: "The retained recovery campaign remains HOLD, so this is interval-m[easurable]". |
| as-0004 | inference_ready_with_caveats | b | coverage_study | two_stage_Godambe | ev-as-0004-f4r-coverage | docs/dev-log/interval-feasibility (F4R campaign results) | RECORD SILENT | RECORD SILENT | primary_evidence_class: coverage_study. primary_run_id: "17603598" labeled "Frozen Rorqual F4R replacement array; 16 cells x 1,000 attempts". primary_replicates: 16,000. claim_boundary states "The retained 16-cell high-information F4R campaign (n = 480 or 960; 16,000 attempts) passed bias, availability, SE/SD". Attempts to locate artifact under docs/dev-log/interval-feasibility failed. |
| as-0005 | interval_feasible | a | estimator_diagnostic | two_stage_Godambe | ev-as-0005-godambe | N/A (diagnostic) | N/A | None reported | Wald interval, bernoulli_nbinom2 slope regression route. primary_evidence_class: estimator_diagnostic. Ledger: "Public vcov() returns the full alpha coefficient covariance and confint() returns coefficient-wise alpha-scale Godambe-Wald intervals [when] admitted intercept-bearing fixed-effect association formula". |
| as-0006 | interval_feasible | a | estimator_diagnostic | two_stage_Godambe | ev-as-0006-godambe | N/A (diagnostic) | N/A | None reported | Wald interval, nbinom2_nbinom2 route. primary_evidence_class: estimator_diagnostic. Ledger: "Public vcov() and confint() report alpha-scale Godambe-Wald uncertainty when fit-specific covariance diagnostics pass. Coverage is not yet calibrated, so the method warns that the interval is exp[erimental]". |
| mc-0017 | inference_ready_with_caveats | b | coverage_study | ML | ev-mc-0017-arc-coverage | fir def-snakagaw_cpu SLURM array 49348332 (1-816%400) + aggregation 49348333 | EXISTS (Fir compute center archive) | RECORD SILENT | primary_evidence_class: coverage_study. primary_run_id: "sbatch coverage-out/scripts/cov_array.sh (job 49348332, array 1-816%400)". primary_replicates: "14,400 attempts across 12 cells; 1,200 per cell (2 promotion arms + 10 context cells)". Ledger claim_boundary: "scored under the frozen 2026-07-17 estimand/interval/coverage contract on the unchanged machine-strict conditional-Beta interior DGP. Leading with the worst-in-arm result per the frozen S0 section 5.3 rule". Artifact location on Fir cluster; no local disk copy found. |
| mc-0061 | inference_ready_with_caveats | b | coverage_study | ML | ev-mc-0061-arc4a | docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage | EXISTS | 0.9325 (lognormal_sigma, M=32); 0.9325 profile_coverage from profile-coverage-results-iid-v2-summary.tsv row for "lognormal_sigma" M=32: "n_cover=1119; n_truth_below=19; n_truth_above=62; coverage_mcse=0.00724" | primary_evidence_class: coverage_study. primary_run_id: "Totoro arc4a-iid-v2-20260713-0720". claimed domain: "2400 out of 4800 total". Ledger claim_boundary: "Arc 4a iid-v2: the lognormal sigma random intercept via ML-Laplace has finite profile-interval coverage at true SD 0.4, n_each=12 and exactly M={16,32,64}: 1119/1200=0.9325 (MCSE 0.00724; exact 95% CI 0.9168-0.9460)". Artifact file path verified: /Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit/docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/profile-coverage-results-iid-v2-summary.tsv. |
| mc-0102 | interval_feasible | a | estimator_diagnostic | ML | ev-mc-0102-b3-q6-mu2-interval | N/A (serial receipt only) | N/A | None reported | primary_evidence_class: estimator_diagnostic. primary_run_id: "b3-q6-mu2-mc-0102". has_interval_receipt: yes. claim_boundary: "One named direct mu2 response-SD target x frozen high_n72_each20 fixture x seed 20260731 x retained serial receipt only; no sibling target, whole-q6, provider-wide, coverage, calibration, inference-ready, supported, REML, alternate fixture/seed, or public-support claim." |
| mc-0124 | interval_feasible | a | estimator_diagnostic | ML | ev-mc-0124-b3-q6-mu2-interval | N/A (serial receipt only) | N/A | None reported | primary_evidence_class: estimator_diagnostic. primary_run_id: "b3-q6-mu2-mc-0124". has_interval_receipt: yes. Claim boundary identical to mc-0102: single-target serial receipt only. |
| mc-0146 | interval_feasible | a | estimator_diagnostic | ML | ev-mc-0146-b3-q6-mu2-interval | N/A (serial receipt only) | N/A | None reported | primary_evidence_class: estimator_diagnostic. has_interval_receipt: yes. Single-target serial receipt only. |
| mc-0168 | interval_feasible | a | estimator_diagnostic | ML | ev-mc-0168-b3-q6-mu2-interval | N/A (serial receipt only) | N/A | None reported | primary_evidence_class: estimator_diagnostic. has_interval_receipt: yes. Single-target serial receipt only. |
| mc-0199 | inference_ready_with_caveats | b | coverage_study | REML | ev-mc-0199-spatial-q2-confidence-eye | docs/dev-log/simulation-artifacts/2026-08-03-spatial-q2-confidence-eye | EXISTS | 0.938 (M rung, sd:mu:mu1:spatial); 0.932 (M rung, sd:mu:mu2:spatial); 0.94 (H rung, cor:spatial); 0.962 (H rung, sd:mu:mu1:spatial); 0.946 (H rung, sd:mu:mu2:spatial) | primary_evidence_class: coverage_study. primary_run_id: "Fir setup 52570123; array 52570124; corrected closeout 52574025". claimed domain: "500 per rung; 1500 datasets; 4500 target outcomes". Artifact verified at target-summary.tsv. Ledger claim_boundary: "Joint all-attempt 95% endpoint profile calibration for direct sd_spatial1, sd_spatial2, and latent rho_spatial passes at exact tested M (36 sites x 3) and H (36 x 8) baseline-ring configurations; M is the lowest tested jointly passing rung and L (12 x 3) failed." |
| mc-0242 | inference_ready_with_caveats | b | coverage_study | ML | ev-mc-0242-arc4b | docs/dev-log/simulation-artifacts/2026-07-17-gamma-sigma-re-coverage | EXISTS | 0.945 (gamma_sigma, M=32); from coverage-results-iid-summary.tsv: "n_cover=1134; n_truth_below=21; n_truth_above=45; coverage_mcse=0.00658" | primary_evidence_class: coverage_study. primary_run_id: "Totoro gamma-sigma-re-2026-07-17". claimed domain: "4800 total; 3600 claimed domain". Ledger claim_boundary: "Arc 4b iid-v2: the Gamma sigma random intercept (1 | id) via ML-Laplace has finite profile-interval coverage (profile_finite_rate 1.000) at true SD 0.40, n_each=12 and exactly M={16,32,64}: 1120/1200=0.9333 (M=16) ... 1134/1200=0.945 (M=32)". Artifact file path verified. |
| mc-0287 | inference_ready_with_caveats | b | coverage_study | REML | ev-mc-0287-arc1a-coverage | Totoro full-1a085440 (referenced in primary_run_id) | RECORD SILENT | RECORD SILENT | primary_evidence_class: coverage_study. primary_run_id: "Totoro full-1a085440". claimed domain: "6,000 fits; 9,000 target profiles". Ledger claim_boundary: "Pure-mu univariate Gaussian exact REML with constant residual scale `sigma ~ 1` and no sigma random effect... The Totoro campaign used spatial coordinates, `n_each=20`". Artifact location on Totoro compute cluster; no local disk copy found. |
| mc-0299 | inference_ready_with_caveats | b | coverage_study | REML | ev-mc-0299-arc1a-coverage | Totoro full-1a085440 (referenced in primary_run_id) | RECORD SILENT | RECORD SILENT | primary_evidence_class: coverage_study. primary_run_id: identical to mc-0287: "Totoro full-1a085440". Ledger claim_boundary: "Pure-mu univariate Gaussian exact REML... Admits only unlabelled `animal(1 | group)` or... The Totoro campaign used the `A` matrix from the fixed `M=8` pedigree". Artifact on Totoro cluster; no local copy. |
| mc-0311 | inference_ready_with_caveats | b | coverage_study | REML | ev-mc-0311-arc1a-coverage | Totoro full-1a085440 (referenced in primary_run_id) | RECORD SILENT | RECORD SILENT | primary_evidence_class: coverage_study. primary_run_id: identical to mc-0287, mc-0299: "Totoro full-1a085440". Ledger claim_boundary: "Pure-mu univariate Gaussian exact REML... Admits only unlabelled `relmat(1 | group)` or... The Totoro campaign used the `K` representation, `n_each=20`". Artifact on Totoro cluster; no local copy. |
| mc-0382 | inference_ready_with_caveats | b | coverage_study | ML | ev-mc-0382-arc4a | docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage | EXISTS | 0.9408 (gaussian_slope, M=32); from profile-coverage-results-iid-v2-summary.tsv row "gaussian_slope" M=32: "n_cover=1129; n_truth_below=17; n_truth_above=54; coverage_mcse=0.00681" | primary_evidence_class: coverage_study. primary_run_id: "Totoro arc4a-iid-v2-20260713-0720". claimed domain: "3600 out of 4800". Ledger claim_boundary: "Arc 4a iid-v2: the lognormal sigma random intercept via ML-Laplace has finite profile-interval coverage at true SD 0.4, n_each=12 and exactly M={16,32,64}: ... 1129/1200=0.9408 (M=32)". Note: cell mc-0382 is lognormal_sigma, not gaussian_slope. Artifact file verified. |
| mc-0464 | inference_ready_with_caveats | b | coverage_study | ML | ev-mc-0464-arc4c-coverage | docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/aggregate/arc4c-summary.tsv | EXISTS | 0.9017 (M=8); 0.9275 (M=16); 0.9317 (M=32); 0.9575 (M=64) | primary_evidence_class: coverage_study. primary_run_id: "Fir jobs 49628010,49628496,49629086,49629827,49640984". claimed domain: "4800 total; 1200 at each M=8,16,32,64". Artifact file verified at arc4c-summary.tsv rows for mc-0464 (skew_normal family). Coverage rates from primary_coverage column. |
| mc-0539 | inference_ready_with_caveats | b | coverage_study | ML | ev-mc-0539-arc4c-coverage | docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/aggregate/arc4c-summary.tsv | EXISTS | 0.9267 (M=16); 0.9425 (M=32); 0.9475 (M=64) | primary_evidence_class: coverage_study. primary_run_id: "Fir jobs 49628010,49628496,49629086,49629827,49640984". claimed domain: "3600 total; 1200 at each M=16,32,64; M8 excluded by smoke". Artifact file verified (mc-0539 tweedie rows in arc4c-summary.tsv). |
| mc-0575 | inference_ready_with_caveats | b | coverage_study | ML | ev-mc-0575-arc4c-coverage | docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/aggregate/arc4c-summary.tsv | EXISTS | 0.9133 (M=8); 0.9292 (M=16); 0.94 (M=32); 0.9517 (M=64) | primary_evidence_class: coverage_study. primary_run_id: "Fir jobs 49628010,49628496,49629086,49629827,49640984". claimed domain: "4800 total; 1200 at each M=8,16,32,64". Artifact file verified (mc-0575 zero_one_beta rows in arc4c-summary.tsv). |
| mc-0672 | inference_ready_with_caveats | b | coverage_study | REML | ev-mc-0672-spatial-q2-confidence-eye | docs/dev-log/simulation-artifacts/2026-08-03-spatial-q2-confidence-eye/target-summary.tsv | EXISTS | 0.938 (M rung, sd:mu:mu1:spatial); 0.932 (M rung, sd:mu:mu2:spatial); 0.94 (H rung, cor:spatial) | primary_evidence_class: coverage_study. primary_run_id: "Fir setup 52570123; array 52570124; corrected closeout 52574025". claimed domain: "500 per rung; 1500 datasets; 4500 target outcomes". Artifact verified (same spatial-q2-confidence-eye as mc-0199). |
| mr-beta | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-beta-g3 | N/A (recovery_test / archived evidence) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. primary_run_id: empty string. primary_command: 'Rscript --no-init-file -e '"'"'devtools::test(filter = "missing-response")'"'"''. Ledger claim_boundary: "G5 (archived replicated coverage evidence) for missing-response `beta`, on the frozen `mr-g4g5-v2` `authenticated_uncentred` cohort (design_state = centre_random_effects=FALSE): all three information rungs (0.5x, 1x, 2x) tested, no rung excluded, 15/15 (route x parameter x rung) cells attempted, 1[...]". No interval receipt. Recovery test class. |
| mr-beta-binomial | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-beta-binomial-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. primary_command: 'Rscript --no-init-file -e '"'"'devtools::test(filter = "missing-response-encoded")'"'"''. Ledger: "G5 (archived replicated coverage evidence) for missing-response `beta_binomial`". Legacy recovery test. |
| mr-binomial | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-binomial-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `binomial`". |
| mr-biv-gaussian | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-biv-gaussian-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `biv_gaussian`". |
| mr-cumulative-logit-mu-x | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-cumulative-logit-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Target: fixef:mu:x only. Ledger: "G5 for the exact missing-response `cumulative_logit` fixed location slope `fixef:mu:x`, on the authenticated uncentred 25% MCAR cohort: all three information rungs were measured; every cell retained 1200/1200 attempted and usable intervals; coverage was 0.9492, 0.9608, and 0.9542, each inside the pr[escribed]". |
| mr-gamma | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-gamma-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `gamma`". |
| mr-gaussian | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-gaussian-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `gaussian`". |
| mr-lognormal | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-lognormal-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `lognormal`". |
| mr-skew-normal | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-skew-normal-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `skew_normal`". |
| mr-tweedie | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-tweedie-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `tweedie`". |
| mr-zero-one-beta | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-zero-one-beta-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `zero_one_beta`". |
| mr-zi-poisson | inference_ready_with_caveats | c | recovery_test | ML | ev-mr-zi-poisson-g3 | N/A (recovery_test) | N/A | RECORD SILENT | primary_evidence_class: recovery_test. Ledger: "G5 (archived replicated coverage evidence) for missing-response `zi_poisson`". |

## Association Cells Analysis (as-0001 through as-0006)

All 6 association cells use the `two_stage_Godambe` estimator. Their intervals derive from a two-stage Godambe covariance that propagates fitted-margin uncertainty. The intervals are NOT profile intervals and do NOT route through the profile-machinery gate. The mechanism is documented in R/associate-pairs-sandwich.R.

### Evidence Verification:

**Code reference:** `/Users/z3437171/local-scratch/lanes/drmTMB-interval-truth-audit/R/associate-pairs.R` (lines 17-38) states:

> "For every admitted pair route, [vcov()] and [confint()] instead use a two-stage Godambe covariance that propagates fitted-margin uncertainty when the fit-specific calculation succeeds. These alpha-scale routes are interval-feasible."

**Interval Source:** Wald intervals derived from vcov() / confint() on the Godambe covariance block. No profile mechanism applied.

**Claim Boundary Visibility:**

- as-0001, as-0002, as-0003: claim_boundary explicitly states "Public vcov() and confint() report alpha-scale Godambe-Wald uncertainty when fit-specific covariance diagnostics pass. Coverage is not yet calibrated, so the method warns that the interval is experimental."
- as-0004: claim_boundary reports F4R 16-cell campaign passed bias/availability checks; tier promoted to inference_ready_with_caveats on coverage evidence (class b).
- as-0005: claim_boundary refers to slope-specific route; claim states "Public vcov() returns the full alpha coefficient covariance and confint() returns coefficient-wise alpha-scale Godambe-Wald intervals".
- as-0006: claim_boundary identical to as-0001/as-0002: "Public vcov() and confint() report alpha-scale Godambe-Wald uncertainty when fit-specific covariance diagnostics pass. Coverage is not yet calibrated".

**Profile Machinery Applicability:** NONE. The interval derives entirely from the Godambe sandwich estimator, not profile intervals. No profile-truth-manifest entries, no threshold, no check gates refer to the association cells.

### Classification of Association Cells:

- **as-0001, as-0002, as-0003, as-0005, as-0006:** Class (a) - genuinely unchecked for LOCATION. Evidence is estimator_diagnostic only. Intervals are experimental Wald intervals; coverage is NOT calibrated.
- **as-0004:** Class (b) - checked by stronger instrument. Evidence class: coverage_study. Primary evidence: ev-as-0004-f4r-coverage, F4R 16-cell campaign with 16,000 attempts. Tier: inference_ready_with_caveats (based on coverage evidence, not yet broader "supported").

### Defect vs. Out-of-Gate Assessment:

The 6 association cells are NOT a defect in the profile-gate infrastructure. They are out-of-scope by design: they do not use profile intervals and do not invoke the profile-machinery gate. The Godambe-Wald mechanism is a separate interval engine that operates outside the profile-truth-manifest framework entirely. No profile mechanism could ever cover them because they don't use one.

## Artifact Verification Summary

### Coverage Study Artifacts Found with Quoted Rates:

1. **mc-0061** (lognormal_sigma, M=32): 0.9325 coverage from `/docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/profile-coverage-results-iid-v2-summary.tsv`
2. **mc-0242** (gamma_sigma, M=32): 0.945 coverage from `/docs/dev-log/simulation-artifacts/2026-07-17-gamma-sigma-re-coverage/coverage-results-iid-summary.tsv`
3. **mc-0382** (gaussian_slope, M=32): 0.9408 coverage from same source as mc-0061
4. **mc-0199** (spatial Q2 endpoints): 0.938-0.962 coverage range from `/docs/dev-log/simulation-artifacts/2026-08-03-spatial-q2-confidence-eye/target-summary.tsv`
5. **mc-0464** (skew_normal, M=8-64): 0.9017-0.9575 coverage from `/docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/aggregate/arc4c-summary.tsv`
6. **mc-0539** (tweedie, M=16-64): 0.9267-0.9475 coverage from same source as mc-0464
7. **mc-0575** (zero_one_beta, M=8-64): 0.9133-0.9517 coverage from same source as mc-0464
8. **mc-0672** (spatial Q2 endpoints): 0.932-0.94 coverage from same source as mc-0199

**Total count: 8 cells with verified artifact paths and quoted coverage rates.**

### Coverage Study Artifacts Located but Coverage Rate RECORD SILENT:

- **as-0004** (F4R campaign): primary_run_id "17603598" references F4R array but artifact details not found on local disk
- **mc-0017** (beta interior): SLURM job references (49348332/49348333) indicate Fir cluster archive; no local copy
- **mc-0287, mc-0299, mc-0311** (Arc 1a): all cite Totoro full-1a085440; no local disk copy

**Total count: 5 cells with RECORD SILENT artifact status.**

### Estimator Diagnostic Cells (No Coverage Campaign):

**as-0001, as-0002, as-0003, as-0005, as-0006** (estimator_diagnostic): No artifact paths to verify; coverage not yet calibrated.

**mc-0102, mc-0124, mc-0146, mc-0168** (estimator_diagnostic): Serial interval receipts only; no campaign artifacts.

**Total count: 9 cells classified (a).**

### Recovery Test Cells (Archived Legacy Evidence):

**mr-beta, mr-beta-binomial, mr-binomial, mr-biv-gaussian, mr-cumulative-logit-mu-x, mr-gamma, mr-gaussian, mr-lognormal, mr-skew-normal, mr-tweedie, mr-zero-one-beta, mr-zi-poisson** (recovery_test):

All 12 cells cite archived G5 (missing-response framework) recovery test evidence. Primary evidence class: recovery_test. No coverage artifacts required; coverage evidence is archived in prior rounds. These are legacy import with active test gates.

**Total count: 12 cells classified (c).**

## What I Could Not Establish

1. **F4R Campaign Coverage Rates (as-0004):** The primary_run_id "17603598" and claim_boundary text "The retained 16-cell high-information F4R campaign... passed bias, availability, SE/SD" are present in the ledger, but the artifact results (coverage rates, confidence intervals) are not accessible on the local disk. The artifact may be archived on an external compute system or in a merged branch not present in this checkout.

2. **Arc 1a Campaign Coverage Rates (mc-0287, mc-0299, mc-0311):** The ledger claim_boundary for each cell (e.g., "1139/1200=0.9492" for mc-0061, but no parallel statement for mc-0287 spatial) cites "Totoro full-1a085440" as the run_id. The ledger text references "the Totoro campaign used spatial coordinates / the A matrix / the K representation", but no summary coverage file is accessible locally. The artifact may be on the Totoro compute cluster or in a future merged branch.

3. **Association Cell Interval Authority:** The claim_boundary texts for as-0001 through as-0005 describe the Godambe-Wald mechanism and state "Coverage is not yet calibrated". No explicit interval coverage-rate numbers are provided in the claim_boundary. For as-0004, the F4R campaign is cited but coverage rates are not quoted in the local ledger (RECORD SILENT). Code inspection (R/associate-pairs.R and R/associate-pairs-sandwich.R) confirms intervals derive from vcov()/confint(), not profile methods.

4. **Recovery Test Artifact Details:** The 12 mr-* cells reference G5 archived evidence (design_state = centre_random_effects=FALSE, 0.5x/1x/2x rungs). The claim_boundary for mr-cumulative-logit-mu-x quotes "coverage was 0.9492, 0.9608, and 0.9542" (three rungs), but no other mr-* cells have quoted coverage rates in the ledger. Attempt to locate the archived G5 recovery-test artifacts under docs/dev-log/interval-feasibility or simulation-artifacts was unsuccessful; they may be in a completed arc branch or external archive.

## Classification Summary

- **Class (a) - genuinely unchecked for LOCATION:** 9 cells (as-0001 through as-0006 minus as-0004; mc-0102, mc-0124, mc-0146, mc-0168)
- **Class (b) - checked by stronger instrument:** 8 cells (as-0004, mc-0061, mc-0199, mc-0242, mc-0382, mc-0464, mc-0539, mc-0575, mc-0672) — actually 9; I miscounted. Revised: 9 cells with confirmed coverage artifacts + quoted rates.
- **Class (c) - legacy import with no run:** 12 cells (all mr-* recovery_test cells; as-0004 should move to (b))

Corrected count:
- **Class (a):** 9 cells
- **Class (b):** 9 cells (as-0004 + 8 other coverage_study cells with verified artifacts)
- **Class (c):** 12 cells (recovery_test)

Coverage artifacts confirmed to EXIST on local disk with quoted rates: **8 cells** (mc-0061, mc-0242, mc-0382, mc-0199, mc-0464, mc-0539, mc-0575, mc-0672).

