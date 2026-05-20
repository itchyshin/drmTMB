# After Task: Slices 1189-1208 Ayumi Current Convergence And Profile Check

## Goal

Refresh the Ayumi convergence evidence against the current branch, including the
new response-specific mean-scale random-effect covariance path, and check whether
profile-likelihood intervals are practical for the clean full-species anchor
model.

## Implemented

Ada added a fifth lightness stress scenario with two independent ordinary
mean-scale blocks, `(1 | p | species)` for `mu1`/`sigma1` and `(1 | q | species)`
for `mu2`/`sigma2`, plus residual `rho12`. The stress and Mass+Beak rerun tools
now record the maximum fixed-gradient component so convergence summaries no
longer rely only on `convergence` and `pdHess`.

## Mathematical Contract

The new ordinary stress row tests two same-response mean-scale covariance blocks:

```r
bf(
  mu1 = male_z ~ temp_z + (1 | p | species),
  mu2 = female_z ~ temp_z + (1 | q | species),
  sigma1 = ~ temp_var_z + (1 | p | species),
  sigma2 = ~ temp_var_z + (1 | q | species),
  rho12 = ~ tree_cover_z
)
```

This is not a phylogenetic model and not a public claim about stable inference.
It only checks that response-specific ordinary mean-scale blocks can be built and
reported separately. The lightness stress run returned the expected `corpairs()`
rows for the two mean-scale blocks, but the fit was false-converged with
`pdHess = FALSE`, a boundary residual `rho12`, and a very large fixed-gradient
component.

## Files Changed

- `tools/ayumi-convergence-stress.R`
- `tools/ayumi-mass-beak-pv2-rerun.R`
- `docs/dev-log/ayumi-convergence/slices-1189-1208/lightness-current-stress/`
- `docs/dev-log/ayumi-convergence/slices-1189-1208/mass-beak-current/`
- `docs/dev-log/ayumi-convergence/slices-1189-1208/mass-beak-locphylo-profile/`

## Checks Run

```sh
air format tools/ayumi-convergence-stress.R tools/ayumi-mass-beak-pv2-rerun.R
Rscript -e "parse('tools/ayumi-convergence-stress.R'); parse('tools/ayumi-mass-beak-pv2-rerun.R')"
DRMTMB_AYUMI_STRESS_OUT='docs/dev-log/ayumi-convergence/slices-1189-1208/lightness-current-stress' Rscript tools/ayumi-convergence-stress.R
DRMTMB_PV2_RERUN_OUT='docs/dev-log/ayumi-convergence/slices-1189-1208/mass-beak-current' DRMTMB_PV2_MODELS='PV2_locphylo,PV2_phylo_fallback,PV2_phylo_fallback_sigma_intercept' DRMTMB_PV2_RUN_Q4=false DRMTMB_PV2_SE=true DRMTMB_PV2_ITER_MAX=2000 DRMTMB_PV2_EVAL_MAX=2000 Rscript tools/ayumi-mass-beak-pv2-rerun.R
DRMTMB_PROFILE_FIT_RDS='docs/dev-log/ayumi-convergence/slices-1189-1208/mass-beak-current/fits.rds' DRMTMB_PROFILE_MODEL='PV2_locphylo' DRMTMB_PROFILE_OUT='docs/dev-log/ayumi-convergence/slices-1189-1208/mass-beak-locphylo-profile' DRMTMB_PROFILE_TARGETS='phylo_mean,rho12' DRMTMB_PROFILE_CORES=2 DRMTMB_PROFILE_BACKEND=multicore Rscript tools/ayumi-profile-fallback-correlations.R
gh pr status
gh run list --limit 12 --json databaseId,workflowName,displayTitle,headBranch,event,status,conclusion,createdAt,updatedAt,url
gh pr view 263 --json number,title,url,isDraft,mergeStateStatus,reviewDecision,headRefName,headRefOid,baseRefName,statusCheckRollup
```

The profile command was stopped after more than 30 minutes without producing
`profile-summary.csv`. The preflight and selected-target tables were retained as
evidence that the clean `PV2_locphylo` fit exposes profile-ready `rho12` and
phylogenetic mean-mean correlation targets, but this run is not an interval
result.

## Key Results

Full Mass+Beak current rerun:

| Model | Elapsed seconds | Convergence | pdHess | logLik | AIC | rho12 response | Max gradient |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| `PV2_locphylo` | 121.1 | 0 | TRUE | -4226.2 | 8504.4 | -0.789 | 0.0359 |
| `PV2_phylo_fallback` | 674.1 | 1 | FALSE | -4220.6 | 8499.1 | -0.720 | 50.0 |
| `PV2_phylo_fallback_sigma_intercept` | 533.6 | 1 | FALSE | -4285.3 | 8610.5 | 0.00066 | 49.0 |

The cleanest current practical anchor remains `PV2_locphylo`: phylogenetic
covariance on the location block, residual `rho12`, and non-phylogenetic scale.
It is not caveat-free: `check_drm()` still reports gradient and phylogenetic
replication cautions that need interpretation before scientific reporting. The
q4/fallback variants are useful diagnostics but not ready for user-facing
inference.

The lightness stress rerun showed the same pattern as earlier: simple aggregate
models are stable, forced-tree phylogenetic mean-only models can fit but often
put correlation at the boundary, and q4/row5 variants are not stable on the
small stress slice.

## Tests Of The Tests

The ordinary two-label mean-scale stress row is a stress test, not a unit test.
It exercises a model shape adjacent to the newly tested response-specific
ordinary mean-scale block path and confirms that `corpairs()` emits separate
rows for `p` and `q`. It also confirms that parse/build success is not enough:
the convergence diagnostics correctly prevent treating the fit as inference.

## Consistency Audit

The refreshed evidence supports these status calls:

- `PV2_locphylo` is currently the cleanest full-species Mass+Beak feasibility
  model, with gradient and phylogenetic-replication caveats.
- q4/full scale-phylogenetic covariance variants should remain marked diagnostic
  until convergence, Hessian, and profile/bootstrap evidence improve.
- Ordinary response-specific mean-scale blocks can be represented, but the
  current lightness stress fit is not stable enough for scientific conclusions.
- Profile intervals are attemptable after fitting for direct profile-ready
  targets, but the full 6,196-species Ayumi profile attempt shows why automatic
  profiling should not be a default model-fitting side effect.

## GitHub Issue Maintenance

Ada inspected the open issues before closing this task. The relevant standing
issues are:

- #4 large-data readiness, for full-species Ayumi runtime and profile-cost
  evidence.
- #33 structured and bivariate random slopes, for the ordinary mean-scale `p`/`q`
  block stress row.
- #147 animal/relmat, because parity with phylo remains planned rather than
  implemented.

Ada added the refreshed Ayumi evidence to #4 after local validation finished, so
GitHub records why profile intervals need explicit target and compute controls:
<https://github.com/itchyshin/drmTMB/issues/4#issuecomment-4499088186>.

## What Did Not Go Smoothly

Ada let the local evidence lane drift ahead of the PR/Actions loop. PR #263 is
green on commit `414a0088`, but the local working tree now contains additional
uncommitted evidence and documentation work. Grace should treat the current green
Actions result as stale until this slice is validated, committed, pushed, and CI
reruns on the updated branch.

The first profile attempt was intentionally useful but operationally clumsy:
`rho12` and the phylogenetic mean-mean correlation were both profile-ready, but
the unbounded two-core run did not finish in a reasonable window. Future profile
jobs for large Ayumi models should use bounded targets, clear time budgets, and
partial-output writing before they are promoted beyond developer diagnostics.

## Team Learning

- Ada should keep the PR/Actions heartbeat active during long local evidence
  work.
- Grace should require fresh Actions on the exact pushed branch before merge
  talk.
- Fisher should treat profile-likelihood cost as part of the inference design,
  not a cosmetic reporting add-on.
- Rose should flag any future claim that random-effect profile intervals are
  "available by default"; they are available on request from retained model
  objects, not automatically computed during fitting.

## Known Limitations

- No public parametric-bootstrap interval API is implemented yet.
- No public `drm_control(profile = ...)` or `drmTMB(..., profile = ...)` path
  exists yet.
- q4/full phylogenetic scale covariance remains unstable on the Ayumi stress
  models.
- Animal, `relmat()`, and spatial parity with phylo remain planned lanes, not
  completed feature claims.

## Next Actions

1. Run local validation on the updated working tree.
2. Add a concise issue update to #4 with the refreshed Ayumi evidence.
3. Commit and push the current slice to PR #263.
4. Wait for GitHub Actions on the updated commit before considering merge.
