# Session Handoff: Q-Series v1 Practical-Surface Checkpoint

Meta: 2026-07-05 · from Codex to Claude · context high

You are Claude, picking up `drmTMB` after a Codex live-toolchain session on the
Q-Series v1 practical-surface branch. Read `AGENTS.md` first, then this file.
This is not a full Q-Series completion claim. It is a banked practical-v1
checkpoint on branch `drmtmb/fix-family-conventions`.

## Critical Context

The current strategic decision is: finish `drmTMB` as the primary R/TMB package
first. Treat `DRM.jl` as a later optional counterpart or acceleration/parity
backend, not as a required dependency and not as a blocker for v1.0. The same
policy applies to `gllvmTMB`: R/TMB remains primary; Julia stays optional where
supported.

The pushed implementation checkpoint is:

```text
branch: drmtmb/fix-family-conventions
remote: origin/drmtmb/fix-family-conventions
implementation commit: 3262655f59c1da69eef1a1950a94ea1a6698eb33
base merge-base with origin/main at handoff: 3a9750436b52155cf5c017c5910a9c398ae1054a
```

Current Q-Series v1 dashboard truth after this slice:

```text
support cells: 104
practical_v1_surface: 94/104 (90.4%)
gaussian_core: 59/67 (88.1%)
basic_distribution_recovery: 35/37 (94.6%)
exact_inference_ready: 8/104 (7.7%)
structured_supported_authority: 0/104 (0.0%)
post_v1: 10/104 (9.6%)
```

Do not inflate this into `supported`, broad inference readiness, q4/q8
promotion, REML/AI-REML expansion, coverage authorization, or public support.
The 94/104 number is a practical v1 implementation/recovery surface, not an
inferential authority surface.

## Takeover Mission: 3-4 Day Arc

This handover is meant for a real takeover, not a single narrow follow-up. The
next 3-4 days should finish the current `drmTMB` Q-Series practical-v1 arc if
the evidence stays clean, then decide whether to stop at a credible v1 boundary
or go beyond it.

The takeover goal is:

```text
Finish the drmTMB R/TMB practical-v1 Q-Series arc first, with honest claim
boundaries, a clean PR/CI path, and no Julia requirement. If the last 10 rows
are economical, plan or execute them; otherwise document them as post-v1 and
shift to package-level v1 polish.
```

Work in this order:

1. Bank and protect the checkpoint: open/update the draft PR, make sure CI runs,
   and keep the branch pushed.
2. Audit the branch as a release candidate for the practical-v1 surface:
   Mission Control, claim language, docs, tests, after-task reports, and stale
   91/104 or old rejection wording.
3. Decide the last-10-row policy with Rose/Fisher/Ada:
   - cheap and deterministic rows may be worth finishing now;
   - expensive inference, q4/q8, derived correlation intervals, REML/AI-REML,
     and non-Gaussian coverage should stay post-v1 unless the evidence changes.
4. If finishing the last 10 is not economical, close this arc at 94/104 with a
   clear post-v1 ledger and move to package-level v1 polish for `drmTMB`.
5. Only after `drmTMB` is current should the team shift serious time to
   `DRM.jl` parity or acceleration. Julia remains optional.

Suggested 3-4 day cadence:

| Window | Main objective | Exit condition |
| --- | --- | --- |
| Day 1 | PR, CI, and claim audit | Draft PR open; branch pushed; fast gates green; no stale 91/104 wording. |
| Day 2 | Last-10 triage | Each remaining row marked finish-now or post-v1 with evidence and cost. |
| Day 3 | Execute economical finish-now rows or v1 polish | Either practical surface increases safely, or post-v1 boundary is documented. |
| Day 4 | Merge/closeout or hand forward | CI/review clean, after-task/check-log updated, next arc explicitly named. |

The team should resist turning this into the old all-inference campaign. The
near-term win is a credible, usable `drmTMB` R/TMB v1 state.

## Mission Control Summary

| Area | Current state | What this means |
| --- | --- | --- |
| Repository | `drmTMB` | R/TMB package is the finish-first target. |
| Branch | `drmtmb/fix-family-conventions` | Pushed to `origin`; continue here for this PR. |
| Implementation SHA | `3262655f` | Banks q2 scale-only point-fit recovery and updated dashboard truth. |
| PR state | Branch pushed; browser compare page ready | `gh` is not installed in this shell, and the exposed connector cannot create PRs. |
| Practical v1 surface | 94/104 rows | Crossed 90%; still not full Q-Series completion. |
| Exact inference-ready | 8/104 rows | Unchanged; interval/coverage authority did not expand. |
| Supported authority | 0/104 rows | No structured row is public-claim `supported`. |
| Post-v1 rows | 10/104 rows | Remaining work is explicit and mostly not economical for this v1 lane. |
| Julia/DRM.jl | optional later | Do not make Julia required for v1, CI, install, docs, or tutorials. |

## What Was Accomplished

- Recovered exact Gaussian q2 scale-only point-fit support for bivariate
  `sigma1` + `sigma2` structured blocks for `spatial`, `animal`, and `relmat`.
- Routed bivariate q2 structured-effect contributions by endpoint metadata
  rather than hardcoding `mu1`/`mu2`.
- Added endpoint-aware SD summary extraction for scale endpoints.
- Retired the old q2-plus-q2 sigma rejection contract by turning its sidecar
  into a header-only zero-row contract.
- Updated Mission Control, release-preflight tooling, q2/q4 boundary docs, row
  selection sidecars, check-log, and after-task evidence so they agree on
  `94/104 (90.4%)`.
- Preserved the claim boundary: no coverage authorization, no promotion, no
  q4/q8 claims, no `supported` rows, no non-Gaussian interval/coverage claims.
- Wrote a memory note for the project policy: finish `drmTMB` first; keep Julia
  optional/later.

## Current Working State

- Working: implementation commit `3262655f` was pushed to
  `origin/drmtmb/fix-family-conventions`.
- Working: focused R tests passed for q2 scale-only recovery and conversion
  contracts before the handover doc was written.
- Working: Mission Control and release-preflight checks passed before the
  handover doc was written.
- Working: this handover doc and the `AGENTS.md` snapshot update are intended
  to travel as a small follow-up commit on the same branch.
- In progress: a draft PR should be opened from the already-pushed branch. Use
  the browser compare page if `gh` is still unavailable.
- Not working / blocked: automated PR creation from this shell is blocked by
  missing `gh`; the GitHub connector exposed here can read PR/status metadata
  but does not expose PR creation.

## Key Decisions & Rationale

- `drmTMB` is the primary package to finish first. Julia twins are useful, but
  optional later add-ons should not slow or complicate the R/TMB v1 path.
- The current Q-Series finish strategy is practical v1 implementation coverage,
  not the older all-rows inference-ready/support campaign.
- A row can be counted in the practical v1 surface when it has an honest
  implemented fit/recovery/rejection boundary. That does not imply interval,
  coverage, support, or public authority.
- q2 scale-only rows are now native point-fit/extractor rows with planned
  future interval/coverage work. They are not bridge rows and do not authorize
  coverage.
- Post-v1 rows remain post-v1: q4/q8, broad interval expansion, derived
  correlation intervals, non-Gaussian interval/coverage, and REML/AI-REML
  expansion are not part of this immediate R/TMB v1 checkpoint.
- Rose audit remains mandatory before any tier/status claim. Fisher owns
  inferential claims and denominator boundaries.
- Totoro/DRAC remain available for compute when needed, but this slice was
  docs/dashboard/targeted-test work and did not require remote compute. Keep
  host provenance separate if future runs use Totoro, DRAC, Nibi, Rorqual, or
  Fir.

## Files Created / Modified

Branch diff from `origin/main...HEAD` at implementation commit, plus this
handover and the `AGENTS.md` snapshot edit:

```text
AGENTS.md
NEWS.md
R/drmTMB.R
R/methods.R
README.md
ROADMAP.md
docs/design/01-formula-grammar.md
docs/design/168-r-julia-finish-capability-matrix.md
docs/design/208-structured-q2-native-ml-status.md
docs/design/214-structured-docs-closeout.md
docs/design/216-structured-random-effect-finish-100-slices.md
docs/design/218-structured-q-series-completion-map.md
docs/dev-log/after-task/2026-07-04-q-series-v1-90pct-review-packet.md
docs/dev-log/after-task/2026-07-04-q-series-v1-beta-animal-mu-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-beta-sigma-animal-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-count-mu-slope-only-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-count-mu-structured-plus-ordinary-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-fast-status-tooling.md
docs/dev-log/after-task/2026-07-04-q-series-v1-first-four-current-debug-runner.md
docs/dev-log/after-task/2026-07-04-q-series-v1-first-four-rejection-smoke-tool.md
docs/dev-log/after-task/2026-07-04-q-series-v1-gamma-relmat-mu-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-nb2-sigma-one-slope-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-public-prose-sync.md
docs/dev-log/after-task/2026-07-04-q-series-v1-student-nu-poisson-zi-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-student-spatial-mu-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-zi-nb2-structured-mu-fit.md
docs/dev-log/after-task/2026-07-04-q-series-v1-zi-poisson-structured-mu-fit.md
docs/dev-log/after-task/2026-07-05-q-series-v1-90pct-economy-plan.md
docs/dev-log/after-task/2026-07-05-q-series-v1-merge-current-main.md
docs/dev-log/after-task/2026-07-05-q-series-v1-ordinal-phylo-mu-fit.md
docs/dev-log/after-task/2026-07-05-q-series-v1-poisson-labelled-scalar-spatial-mu-fit.md
docs/dev-log/after-task/2026-07-05-q-series-v1-q2-scale-only-point-fit-recovery.md
docs/dev-log/after-task/2026-07-05-q-series-v1-truncnbinom2-hu-relmat-fit.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/README.md
docs/dev-log/dashboard/status.json
docs/dev-log/dashboard/structured-re-balance-100-slices.tsv
docs/dev-log/dashboard/structured-re-closeout-package.tsv
docs/dev-log/dashboard/structured-re-count-slope-sigma-one-slope-rejection-contract.tsv
docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv
docs/dev-log/dashboard/structured-re-executable-evidence.tsv
docs/dev-log/dashboard/structured-re-finish-100-slices.tsv
docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv
docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv
docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv
docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv
docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv
docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv
docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv
docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv
docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv
docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv
docs/dev-log/dashboard/structured-re-q2-bridge-boundary.tsv
docs/dev-log/dashboard/structured-re-q2-plus-q2-sigma-rejection-contract.tsv
docs/dev-log/dashboard/sweep.json
docs/dev-log/handover/2026-07-05-claude-handover.md
docs/dev-log/known-limitations.md
docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv
docs/dev-log/release-audits/q-series-v1-90pct-economy-plan.tsv
docs/dev-log/release-audits/q-series-v1-90pct-review-packet.tsv
docs/dev-log/release-audits/q-series-v1-first-candidate-debug-fixture-contract.tsv
docs/dev-log/release-audits/q-series-v1-first-candidate-design-contract.tsv
docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv
docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv
docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv
docs/dev-log/release-audits/q-series-v1-preflight-report.md
docs/dev-log/release-audits/q-series-v1-release-status.md
docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv
src/drmTMB.cpp
tests/testthat/test-count-structured-mu.R
tests/testthat/test-cumulative-logit.R
tests/testthat/test-nongaussian-structured-boundary.R
tests/testthat/test-structured-re-conversion-contracts.R
tests/testthat/test-structured-re-q2-rejections.R
tools/qseries-v1-first-four-rejection-smoke.R
tools/qseries_v1_claim_guard.py
tools/qseries_v1_release_check.py
tools/validate-mission-control.py
vignettes/formula-grammar.Rmd
```

## Local Validation Banked

These passed before this handover doc was written:

```sh
python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py

/Users/z3437171/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node --check /tmp/drmtmb-mission-control-index-r-current.js

python3 tools/qseries_v1_release_ledger.py --check --check-status --summary

R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 python3 tools/validate-mission-control.py

python3 tools/qseries_v1_release_check.py --summary --write-report --write-candidates
python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates

R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "structured-re-q2-rejections", reporter = "summary")'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'

rg -n "91/104|87\\.5|Rows to 90|rows_to_90=3|scale-only q2 remains rejected|scale-only.*reject before optimization|current .*q2-plus-q2 sigma rejection|reproduce the current .*q2-plus-q2 sigma rejection" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/dashboard docs/dev-log/release-audits tools tests | head -160

git diff --check
```

Important validation summary:

```text
qseries_v1_release_check_ok
practical_v1_surface=94/104 (90.4%)
gaussian_core=59/67 (88.1%)
basic_distribution_recovery=35/37 (94.6%)
exact_inference_ready=8/104 (7.7%)
supported_authority=0/104 (0.0%)
post_v1=10/104 (9.6%)
rows_to_90=0
rows_to_100=10
mission_control_ok
```

## Next Immediate Steps

1. Verify the handover commit and clean state:
   ```sh
   git checkout drmtmb/fix-family-conventions
   git pull --ff-only origin drmtmb/fix-family-conventions
   git status --short --branch
   ```
2. Open or refresh the draft PR from `drmtmb/fix-family-conventions` into
   `main`. Use this corrected headline and summary, not the stale 91/104 body
   from the old compare URL:
   ```text
   [codex] Q-Series v1 practical-surface and tooling updates

   This draft PR banks the Q-Series v1 practical-surface branch after syncing
   with current main.

   Highlights:
   - moves the practical v1.0 Q-Series surface to 94/104 rows (90.4%) while
     keeping exact inference_ready at 8/104 and supported authority at 0/104
   - recovers q2 scale-only Gaussian point-fit/extractor rows for spatial,
     animal, and relmat without coverage or support promotion
   - adds local fit-only basic-distribution rows for recent Q-Series slices
   - adds release-preflight tooling and generated Mission Control sidecars
   - preserves claim boundaries: no q4/q8 promotion, no REML/AI-REML expansion,
     no coverage authorization, no public-support wording

   Draft until CI completes and the branch-level review confirms whether this
   should land as one consolidated Q-Series v1 branch or be split further.
   ```
3. Re-run the fast gates after the handover commit:
   ```sh
   python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_claim_guard.py
   R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py
   python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates
   R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'
   git diff --check HEAD^..HEAD
   ```
4. Run a Rose-first claim audit before any public status wording:
   ```text
   Rose: find stale, inflated, or inconsistent claims.
   Fisher: verify inference/coverage/support boundaries.
   Ada: verify branch, docs, tests, dashboard, and PR story are coherent.
   Grace: verify CI, reproducibility, and served Mission Control.
   ```
5. Triage the remaining 10/104 rows:
   - finish-now only if the work is cheap, deterministic, and does not require
     broad coverage or new inferential authority;
   - post-v1 if it requires q4/q8 admission, coverage grids, REML/AI-REML,
     derived-correlation intervals, broad bridge support, or heavy remote
     compute.
6. If CI fails, route failures by ownership:
   - Codex should handle live R/TMB compiler, fit, test, and rendering failures.
   - Claude can review docs, claim language, stale wording, PR narrative, and
     pure logic failures.
7. Only after this PR is merged should the next planning step decide whether to
   spend the last 10/104 rows before v1 or stop the Q-Series practical surface
   here and shift to package-level v1 polish.

## Blockers / Open Questions

- PR creation is not completed by this handover because this shell has no
  `gh` executable and the exposed GitHub connector does not include PR creation.
  The branch is pushed, so the open browser compare page can submit it.
- Decide whether the large practical-surface branch should land as one draft PR
  or be split. The branch is coherent as a v1 practical-surface checkpoint, but
  it touches many docs/dashboard/report files.
- Should the remaining 10/104 rows be pursued before v1, or should v1 switch to
  package polish now that the practical surface is above 90%? This is a product
  decision, not just an engineering one.

## Gotchas & Failed Approaches

- Do not use the older compare-page body that says `91/104 (87.5%)`; it is
  stale after commit `3262655f`.
- Do not claim q2 scale-only interval/coverage readiness. The new rows are
  native point-fit/extractor rows with future interval design still planned.
- Do not make Julia required or imply Julia is needed for `drmTMB` v1.
- Do not pool denominators across local, Totoro, DRAC, Nibi, Rorqual, or Fir
  unless a future run design explicitly permits it.
- R should be run with `R_PROFILE_USER=/dev/null Rscript --no-init-file` when
  possible; older local profile/library combinations have caused segfaults.
- A temporary TSV rewrite error during this session truncated
  `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`, but it was
  restored from `HEAD` and revalidated before commit.

## How to Resume

From the repo root in an authenticated terminal, start Claude interactively:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-05-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```

For an autonomous fresh Claude session with a budget cap:

```sh
claude -p "Rehydrate from docs/dev-log/handover/2026-07-05-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps." --max-budget-usd 10
```

Long takeover prompt for the next 3-4 days:

```text
Rehydrate from docs/dev-log/handover/2026-07-05-claude-handover.md + the AGENTS.md snapshot. Take over the drmTMB Q-Series v1 practical-surface arc for the next 3-4 days. First confirm branch drmtmb/fix-family-conventions is pushed at the handover SHA or newer, confirm Mission Control truth (104 rows, practical_v1_surface 94/104, exact inference_ready 8/104, supported 0/104, post_v1 10/104), and open/update the draft PR with the corrected 94/104 body if needed. Then run a Rose-first claim audit and Fisher/Ada/Grace review: no q4/q8 promotion, no new coverage authorization, no REML/AI-REML expansion, no Julia requirement, and no public-support wording. After PR/CI are stable, triage the remaining 10 rows into finish-now versus post-v1 using economy as the rule. Execute only cheap deterministic finish-now work; otherwise document the post-v1 boundary and shift to drmTMB package-level v1 polish. Keep DRM.jl/Julia optional and later, not required for drmTMB v1. Leave a fresh check-log, after-task report, and handover if the arc is not merged by the end.
```

Claude should focus on review, claim language, PR narrative, and planning.
Codex should run the live R/TMB toolchain: real fits, compilation, focused
`devtools::test()`, `devtools::check()`, pkgdown rendering, and simulations.
