# Session Handoff: Q-Series Evidence Board Continuation

Meta: 2026-06-29 · from Codex to Codex · context high

You are Codex, picking up the drmTMB Q-Series evidence board. Read `AGENTS.md`
first, then this file. The current checkout is not a finished checkpoint: it is
a large in-progress working tree on `codex/qseries-sigma-inference-ready`.

## Critical Context

Do not say the Q-Series is finished. The current source-of-truth table still has
104 rows, with 67 Gaussian rows, 37 non-Gaussian rows, 24 Gaussian high-q rows
(`q4`/`q6`/`q8`), and 9 `q8` rows. Only 5 rows currently have both
`interval_status == inference_ready` and `coverage_status == inference_ready`.
No high-q row is inference-ready, and no non-Gaussian row has interval or
coverage evidence.

The live validator is red at handoff time because the new q2-plus-q2 intercept
contract is wired but not closed:

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py
```

fails on:

- `gaussian_lowq_status_phylo_q2_plus_q2_intercept`: gate row
  `claim_boundary` must name point/fixture evidence only;
- all 10 rows in `structured-re-q2-plus-q2-intercept-contract.tsv`: the
  `evidence_url` points to a not-yet-created after-task report.

Do not run new DRAC coverage before this local contract state is repaired.

## Mission Control Summary

| Area | Current state | What this means |
| --- | --- | --- |
| Branch | `codex/qseries-sigma-inference-ready`, `HEAD=77b634ed` | Branch tracks `origin/codex/qseries-sigma-inference-ready`; working tree is very dirty. |
| Widget | `docs/dev-log/dashboard/index.html`, build `r132` | The Q-Series support-cell table is present near the top of the widget. |
| Support cells | 104 rows | Source-of-truth file: `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`. |
| Gaussian rows | 67 | Includes 24 high-q rows and 9 q8 rows. |
| Non-Gaussian rows | 37 | Recovery-only or rejection-contract evidence only; no interval/coverage claims. |
| Inference-ready | 5 rows | Exactly 5 rows have both interval and coverage inference-ready. |
| Fit baseline | 3 rows | Ordinary comparator/baseline rows only, not structured-RE support. |
| High-q | 24 rows | Diagnostic/admission work only; 0 inference-ready. |
| q8 | 9 rows | Stability/geometry only; 0 inference-ready. |
| Mission control | currently failing | q2-plus-q2 contract wording/report closure remains. |
| Reachable DRAC | Nibi and Rorqual reachable | `nibi -> l5.nibi.sharcnet`; `rorqual -> rorqual2`. |
| Not reachable non-interactively | Totoro/FIIA | Totoro denied public-key/password; FIIA hostname did not resolve from this shell. |

## What Was Accomplished

The current branch contains a broad Q-Series evidence-board expansion. The
important completed or nearly completed pieces visible from the checkout are:

- the support-cell widget/table now exposes all 104 Q-Series rows with separate
  fit, interval, and coverage status columns;
- non-Gaussian structured rows are separated from Gaussian inference claims;
- count rows have recovery-only sidecars, runner scripts, cluster artifacts, and
  after-task reports;
- high-q rows are kept diagnostic/admission-only, with q4/q8 blockers separated
  from low-q interval readiness;
- q2 slope and q2 intercept evidence sidecars exist, but new q2-plus-q2
  contract wiring is still incomplete;
- an internal hidden q>2 correlation-parameterization probe was started in
  `src/drmTMB.cpp` and `tests/testthat/test-phylo-utils.R`; focused
  `phylo-utils` testing passed earlier in this session, but the slice still
  needs design/check-log/after-task closure before it should be treated as done.

Recent local evidence collected for this handoff:

```text
support_cells = 104
family_class = gaussian 67, non_gaussian 37
dimension_pattern = q1 57, q2 11, q4 10, q6 5, q8 9, q1_plus_q1 8, q2_plus_q2 4
fit_status = supported 3, point_fit 69, diagnostic_only 2, planned 9, unsupported 21
interval_status = inference_ready 5, interval_feasible 4, diagnostic_only 18, planned 37, unsupported 40
coverage_status = inference_ready 5, planned 78, unsupported 21
```

## Current Working State

- Working: dashboard source files and sidecar TSVs are present in the checkout;
  the widget can be served from `http://127.0.0.1:8765/` when
  `tools/start-mission-control.sh` is running.
- In progress: q2-plus-q2 intercept contract sidecar, validator wiring, and test
  coverage are not closed.
- In progress: hidden q>2 partial-correlation parameterization probe is compiled
  enough for focused `phylo-utils`, but lacks full closure documentation and
  broader regression coverage.
- Blocked for immediate compute: Fisher/Rose recommended the next true compute
  lane be Gaussian low-q `qseries_phylo_q1_mu_intercept`, but only after the
  local contract/validator state is green. Totoro/FIIA are not reachable
  non-interactively from this shell, so do not silently spend the Totoro/FIIA
  smoke on Nibi/Rorqual.
- Not working: `tools/validate-mission-control.py` is red for the q2-plus-q2
  contract closure items listed above.

## Key Decisions & Rationale

- Evidence-complete Q-Series does not mean all 104 rows are supported. It means
  every row has a truthful row-level state: inference-ready, fit baseline,
  recovery-only, diagnostic-only, planned, blocked, or unsupported.
- Stability, interval feasibility, coverage, and inference readiness remain
  separate signals. A fit-stable row is not inference-ready unless both interval
  and coverage evidence pass row-specific gates.
- Non-Gaussian rows remain recovery-only or rejected. Do not promote
  non-Gaussian interval, coverage, REML, AI-REML, or support claims.
- Gaussian q4/q6/q8 rows remain diagnostic/admission-only. q8 does not inherit
  q4 evidence.
- The default small-sample bias+t correction remains limited to location-axis
  structured-RE SD targets. Do not apply it to sigma or non-Gaussian rows by
  analogy.
- Rose audit is mandatory before any tier/status claim. Fisher owns interval,
  coverage, MCSE, one-sided miss, and denominator acceptance.

## Files Created / Modified

The working tree is too large for a hand-written every-line inventory in this
handoff. Before staging, regenerate the exact manifest with:

```sh
git diff --name-only > /tmp/drmtmb-modified-files.txt
git ls-files --others --exclude-standard > /tmp/drmtmb-untracked-files.txt
```

Tracked files currently modified:

```text
R/drmTMB.R
R/profile.R
docs/design/03-likelihoods.md
docs/design/218-structured-q-series-completion-map.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/README.md
docs/dev-log/dashboard/index.html
docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv
docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv
docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv
docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv
docs/dev-log/dashboard/structured-re-q2-slope-spatial-animal-admission-audit.tsv
docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv
docs/dev-log/dashboard/version.txt
docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-interval-smoke/structured-re-q4-location-slope-interval-smoke-results.tsv
docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv
src/drmTMB.cpp
tests/testthat/test-phase18-animal-mu-slope.R
tests/testthat/test-phylo-utils.R
tests/testthat/test-profile-targets.R
tests/testthat/test-structured-re-conversion-contracts.R
tests/testthat/test-wald-small-sample-default.R
tools/run-structured-re-q2-slope-coverage-grid.R
tools/run-structured-re-q4-location-coverage-grid.R
tools/run-structured-re-q4-location-slope-interval-smoke.R
tools/run-structured-re-q4-slope-interval-stability-probe.R
tools/start-mission-control.sh
tools/validate-mission-control.py
```

Major untracked categories currently present:

```text
docs/design/220-structured-q4-animal-production-transform-gate.md
docs/dev-log/after-task/2026-06-29-q-series-*.md
docs/dev-log/dashboard/structured-re-*.tsv
docs/dev-log/simulation-artifacts/2026-06-29-*/
tools/run-structured-re-*.R
tools/slurm/*.sbatch
tools/summarize-structured-re-*.R
```

Files added by this handover:

```text
docs/dev-log/handover/2026-06-29-codex-handover.md
AGENTS.md
```

## Next Immediate Steps

1. Repair the q2-plus-q2 contract closure:
   - create
     `docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-intercept-contract.md`;
   - adjust the `qseries_phylo_q2_plus_q2_intercept` row in
     `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv` so its
     `claim_boundary` explicitly says point/fixture evidence only;
   - finish the matching focused expectations in
     `tests/testthat/test-structured-re-conversion-contracts.R`.
2. Run:
   ```sh
   R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py
   R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts|phylo-utils")'
   git diff --check
   ```
3. Close the hidden q>2 parameterization probe:
   - keep it hidden/internal unless a separate design decision says otherwise;
   - document the default path and no-status-change boundary in
     `docs/design/03-likelihoods.md`;
   - add an after-task report and check-log entry;
   - run at least focused `phylo-utils` again after any C++ changes.
4. Only after mission control is green, decide whether to continue the Gaussian
   low-q `mu` intercept lane. Fisher/Rose recommendation was to start with
   `qseries_phylo_q1_mu_intercept`, not q4/q8 and not non-Gaussian intervals.
5. Use Nibi/Rorqual for DRAC jobs only after local contract gates pass. Totoro
   and FIIA need access repair or a manual authenticated session before they can
   serve as smoke hosts from this environment.

## Blockers / Open Questions

- Should this dirty working tree be split into smaller PRs before push? Yes,
  likely. Do not stage all files blindly.
- Are the large local `.rds` replicate artifacts intended to be committed? Check
  the artifact policy and PR size before staging.
- Totoro/FIIA were reported by the human as connected, but non-interactive SSH
  from this shell failed. Resolve before writing a plan that requires them.
- The q2-plus-q2 contract names six admissible block targets and four blocked
  cross-block correlations. It has not passed the validator yet.

## Gotchas & Failed Approaches

- Do not infer q4/q8 readiness from the hidden q>2 parameterization harness. It
  is a geometry/parameterization probe, not interval or coverage evidence.
- Do not promote spatial/animal q2 rows by analogy to phylo/relmat q2 rows.
- Do not treat non-Gaussian recovery as interval, coverage, inference, REML, or
  support evidence.
- Do not reroute a planned Totoro/FIIA smoke to Nibi/Rorqual just because
  Nibi/Rorqual are reachable; that changes the campaign contract.
- `R_PROFILE_USER=/dev/null` is required because the local `.Rprofile` points at
  an R-4.5 library that can segfault R 4.6.

## How to Resume

From the repo root:

```sh
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git status --short --branch
R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py
```

Then paste this into a fresh Codex session:

```text
Rehydrate from docs/dev-log/handover/2026-06-29-codex-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps. Rose audit is mandatory before any tier/status claim. Use R_PROFILE_USER=/dev/null Rscript --no-init-file and keep Nibi/Rorqual compute behind local validator gates.
```

Codex should run the live R/TMB toolchain, real fits, validators, simulation
smokes, and rendering. Claude should review the diff, write claim-boundary
prose, and help split the branch if the current working tree is too large for a
single PR.
