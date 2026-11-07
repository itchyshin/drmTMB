# After Task: Bernoulli Phylogenetic SD Timing and Recovery Pilot

## 1. Goal

Design and run a bounded, synthetic-only Bernoulli phylogenetic SD pilot to
measure whether the native R/TMB path fits the intended model, returns
profile-interval diagnostics, and can be timed for a later calibration study.

## 2. Implemented

Added an ADEMP design, a reproducible pilot runner, a DGP self-test, a
deterministic recovery summarizer, and a source-bound Totoro receipt. The final
v4 run completed 12 fits across four
nested tip-count and within-tip-replication cells. It returned eight finite
non-boundary profile intervals, three clamp-limited intervals, and one failed
profile. Seven of the eight returned intervals contained the true slope
`0.45`. These three-seed results are diagnostic only and do not estimate
coverage.

The design and run receipt are in:

- `docs/dev-log/general-sd-regression/bernoulli-phylo-calibration-pilot-design.md`
- `docs/dev-log/general-sd-regression/evidence/phylo-calibration-pilot-20261020/`

## 3a. Decisions and Rejected Alternatives

The pilot retains the existing phylogenetic kernel scaling. Its 16-tip subset
keeps one tip from each root daughter so pruning preserves the matching
covariance submatrix. We rejected the first-16-label subset after a self-test
showed that pruning away a root daughter changed shared-stem covariance.

The three replicates per cell support timing and runner checks. They do not
justify a coverage estimate, information threshold, or public calibration
claim. The output records every attempt, including runner failures from v1
and interval-schema errors in v2-v3; only v4 contributes to the final readout.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/bernoulli-phylo-calibration-pilot-design.md`
- `tools/general-sd-regression/probes/bernoulli-phylo-calibration-pilot.R`
- `tools/general-sd-regression/probes/summarize-bernoulli-phylo-calibration-pilot.R`
- `docs/dev-log/general-sd-regression/evidence/phylo-calibration-pilot-20261020/README.md`
- `docs/dev-log/general-sd-regression/evidence/phylo-calibration-pilot-20261020/`
  with the bounded source capsule, package tarball, remote environment receipt,
  self-test logs, and all v1-v4 attempt ledgers
- This after-task report and its check-log shard
- `docs/dev-log/check-log.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- Local DGP self-test passed:
  `DRMTMB_PILOT_DEVTOOLS=true Rscript --vanilla tools/general-sd-regression/probes/bernoulli-phylo-calibration-pilot.R --self-test`.
- A filtered package source capsule built successfully with
  `R CMD build --no-build-vignettes --no-manual <capsule>/drmTMB`. The first
  build from the entire worktree failed while copying its 1.1 GB development
  archive; it produced no tarball and was replaced by the bounded capsule.
- Totoro installed the exact 4.1 MB source tarball to an isolated library.
  The install completed and loaded the package. The tarball SHA-256 is
  `54ed1b3a52113494528605f191c1d928c801731c2ee437b2ea7fa9e95e212a18`; the
  installed shared-library SHA-256 is recorded in the evidence README.
- Totoro v4 self-test passed, then 12 fits completed with exit status 0 using
  four workers and `OPENBLAS_NUM_THREADS=1`. The median per-fit elapsed times
  by cell were 0.955, 2.281, 1.572, and 6.568 seconds. The maximum covariance
  submatrix difference was `2.22e-16`.
- A local readback check compared the RDS and CSV attempt counts, confirmed
  all 12 rows and optimizer convergence codes, verified profile-status counts,
  checked truth-in-interval counts, and confirmed every covariance difference
  was below `1e-8`.
- The deterministic recovery summarizer reran from the retained v4 RDS and
  regenerated `recovery-summary.csv`. Each cell has three estimates, so slope
  bias, its MCSE, RMSE, and the bootstrap SE of RMSE are descriptive only.
  Biases were 0.134, 0.374, -0.005, and -0.043 across the four cells; RMSEs
  were 0.994, 0.539, 0.210, and 0.049. The CSV hash is
  `2a9aabe0b34be048b6ed6dba96ad200def40e503cf97d90a8fe6155d08c61fb8`.
- `python3 tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`
  passed all 36 fixture-based adapter and campaign-integrity tests in 3.8
  seconds. These tests launched no model fits and do not qualify calibration.
- All source hashes, seeds, package versions, output hashes, and remote
  session details are recorded under the evidence path above.
- `gh issue view 59 --json number,title,state,url,body --repo itchyshin/drmTMB`
  confirmed the open simulation-framework issue remains relevant. No issue was
  edited or commented on.

## 6. Tests of the Tests

The DGP self-test checks that the selected subset has 16 tips and 12 rows per
tip, the standardized predictor has mean 0 and SD 1, the design has four
cells, and the pruned covariance equals the corresponding covariance
submatrix. It failed on the initial arbitrary subset and passed after retaining
both root daughter clades.

The retained attempt ledger also caught two runner defects. First, inline
`subset$tree` syntax failed the formula parser before fitting. Second, indexing
the profile table by position misread its endpoint columns. The final runner
binds `tree` by name and reads the returned `lower` and `upper` columns. The
v1-v3 ledgers remain in evidence so those failures are visible.

## 7a. Issue Ledger

Issue #59, “Phase 18: comprehensive simulation framework and reporting,” is
open and covers the broader staged simulation framework. This pilot adds a
small input to that programme; it does not change the issue's scope or status.
No issue was opened, closed, or edited.

## 8. Consistency Audit

The synthetic model is `log(SD_g) = alpha_0 + alpha_1 z_g`, with
`alpha_0 = log(0.35)` and `alpha_1 = 0.45`, applied as a multiplier of the
existing phylogenetic covariance. The R formula uses
`sd(species, level = "phylogenetic") ~ z`. The run does not normalize or
otherwise change the kernel. The design document cites the existing
source-audited methods review and states where it does not establish
identifiability or interval calibration.

No package source, public capability table, vignette, NEWS entry, or Julia
route changed in this task. The result applies only to the native Bernoulli
phylogenetic random-intercept SD route. No email was sent.

## 9. What Did Not Go Smoothly

Three corrections were needed before the final readout. The first full-worktree
build tried to copy a large development archive. The first runner passed a
tree expression that the formula parser rejects. The next runner versions
misread the profile-table endpoint schema. Each failure was retained; the
final package source and runner hashes are bound to v4.

## 10. Known Residuals

The 12 attempts do not calibrate profile intervals, compare against an
independent marginal-likelihood oracle, or validate a quadrature approximation.
The small-tip, low-replication cells produced clamp-limited or failed profiles
in some seeds. The study has no power to distinguish coverage rates or define
an information threshold. It does not cover Julia, other distributions,
independent or correlated ordinary effects, other structured providers,
cross-parameter blocks, or bivariate models.

## 11. Team Learning

For nested phylogenetic simulations, verify pruning against the original
covariance before fitting; preserving both root daughter clades retained the
same submatrix in this design. For package profile outputs, read named columns
from the returned table and use a named tree object in the formula. Keep
runner and extraction failures as separate, retained attempt versions.

## 12. Cross-Product Coverage

Covers the DGP and interval-diagnostic runner, isolated source installation,
and native R/TMB Bernoulli phylogenetic random-intercept SD fits on Totoro.

Does NOT cover Julia parity, interval calibration, an independent likelihood
oracle, any other response family or random-effect type, correlated blocks,
prediction or bootstrap coverage, or completion of the general SD programme.

## Prose Assessment

The prose-style checker passed for the design, report, and evidence README.
The after-task structure check passed. The general SD acceptance ledger still
has all nine gates G0-G8 open, so the overall programme remains incomplete.
