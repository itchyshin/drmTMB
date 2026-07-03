# After Task: Q-Series Tranche 19 q2-plus Held-Correlation Profile Contract

## 1. Goal

Advance the Q-Series q2-plus retained-denominator lane by turning the Tranche
18 failure taxonomy into one fail-closed contract for one target and one
failure class, without running compute or moving any support-cell status.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile-contract.tsv`
with six rows: selected target, runner contract, approval gate, host policy,
stop rules, and tranche summary. Every row targets only
`cor_sigma1_sigma2_intercept` from
`q2_plus_q2_intercept_phylo_cor_sigma1_sigma2`, the held Nibi
sigma1/sigma2 correlation profile-root failure on replicate 3 / seed 823003.

Added
`tools/run-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile.sh`
as the fail-closed helper. It refuses to run unless
`DRMTMB_Q2_TRANCHE19_EXECUTION_APPROVED=fisher_rose_noether_gauss_grace`, locks
the contract to `n_rep = 1`, `seed_start = 3`, `seed_base = 823000`, and
`bootstrap = 0`, runs the existing q2-plus smoke runner with
`interval_repair_channel = bounded_tmbprofile_direct_correlation_sidecar`, and
blocks DRAC, Nibi, Rorqual, Trillium, SLURM, and cluster-labeled execution.

Mission Control now loads and renders the sidecar at dashboard build `r213`.
The Python validator and focused conversion-contract test own the schema,
six-row identity, exact seed/target/route, fail-closed helper text, member-board
rows, and the unchanged q2-plus support-cell invariants.

## 3a. Decisions and Rejected Alternatives

Selected the Nibi held sigma1/sigma2 profile-root failure because it is the
cheapest post-taxonomy question: does a bounded `tmbprofile` sidecar explain the
single replicate 3 profile-root error before any broader q2-plus denominator or
coverage design?

Rejected an SR150 top-up, a full q2-plus rerun, and any q4 or q2-intercept
inheritance. This tranche is not coverage evidence, interval repair evidence,
or a denominator. It is a reviewed command contract only.

Rejected DRAC/Nibi/Rorqual/Trillium execution in the helper. If the blocking
reviewers approve a run, the first diagnostic run must stay local or Totoro
with host provenance separated and no pooling.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile-contract.tsv`
- `tools/run-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile.sh`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche19-q2-plus-held-correlation-profile-contract.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche19-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Tranche 19 TSV shape check: 7 lines including header, 39 columns on every
  row.
- `bash -n tools/run-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile.sh`
- `env -u DRMTMB_Q2_TRANCHE19_EXECUTION_APPROVED bash tools/run-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile.sh`: refused before R execution with exit status 64.
- `DRMTMB_Q2_TRANCHE19_EXECUTION_APPROVED=fisher_rose_noether_gauss_grace DRMTMB_Q2_TRANCHE19_HOST_NAME=nibi bash tools/run-q2-retained-denominator-tranche19-q2-plus-held-correlation-profile.sh`: refused before R execution with exit status 66.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Dashboard JS extraction plus `node --check /tmp/drmtmb-dashboard-index.js`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Narrow stale-claim scan for positive Tranche 19 admission, coverage,
  promotion, execution-evidence, denominator-ready, `inference_ready`, and
  `supported` wording: no hits.
- `gh issue list --repo itchyshin/drmTMB --state open --search "q2-plus retained denominator held correlation profile" --limit 10 --json number,title,state,url`: returned no issues.
- `gh issue view 687 --repo itchyshin/drmTMB --json number,title,state,url,body`: #687 remains a DDF parking issue, not Tranche 19 authority.
- Served Mission Control checks on `http://127.0.0.1:8765/`: `version.txt =
  r213`, the Tranche 19 sidecar serves with 7 lines including the header,
  `index.html` contains the Tranche 19 table label, and the served completion
  map contains the Tranche 19 paragraph.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche19-q2-plus-held-correlation-profile-contract.md')"`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series Tranche 19 q2-plus held-correlation profile contract banked; no compute/status" --next "After Fisher/Rose/Noether/Gauss/Grace approval, run only the fail-closed Tranche 19 helper for cor_sigma1_sigma2_intercept seed 823003 on local/Totoro and review the tmbprofile sidecar before any denominator or coverage design. No status before review." --output docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche19-codex-checkpoint.md`

## 6. Tests of the Tests

The focused R block reads the Tranche 19 sidecar and checks the exact schema,
six-row scope counts, one target, one seed, one route, command-status
boundaries, blocking reviewer rows, local source existence, fail-closed helper
text, and linked support-cell invariants. The first run failed because the
numeric-looking seed fields were parsed as integers while the test expected
character values; the test was tightened to compare identity fields as
characters, then passed.

The helper refusal probes exercise both required failure paths: missing
approval exits 64 and a blocked Nibi host label exits 66 before `Rscript` can
run.

## 7a. Issue Ledger

The open issue search for `q2-plus retained denominator held correlation
profile` returned no matching open issues. Issue #687 was inspected directly;
it remains an open DDF repair-sidecar parking issue and does not authorize this
profile contract, q2-plus promotion, coverage, q4/q8 inheritance, REML,
AI-REML, or public support. No new issue was opened.

## 8. Consistency Audit

Mission Control reports 104 Q-Series support cells, 8 Q-Series inference-
evidence summary rows, 6 Tranche 19 held-correlation profile-contract rows,
and 95 member-discussion rows. The linked support cell
`qseries_phylo_q2_plus_q2_intercept` remains `point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`.

Every Tranche 19 row remains `no_compute_in_tranche19`,
`coverage_not_authorized`, and `do_not_promote`. The dashboard README and
Q-Series completion map describe Tranche 19 as a banked contract only. Public
APIs, formula grammar, R source, package documentation, README, NEWS, pkgdown,
and support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The validator caught two useful ledger defects before closeout: the runner row
did not repeat the approval environment variable in its displayed exact
command, and the host-policy row had Gauss and Grace review fields swapped.
Both were fixed in the sidecar rather than weakening the validator.

The first focused R contract-test rerun also failed on TSV type inference for
numeric seed fields. That was a test expectation issue, not a contract-value
issue, and it is now covered by explicit character comparisons.

## 10. Known Residuals

No Tranche 19 smoke has run. The next tranche may run only the approved helper
for `cor_sigma1_sigma2_intercept` seed 823003 on local or Totoro, then review
the resulting bounded `tmbprofile` diagnostic sidecar. Even a successful run
would remain profile-geometry evidence until Rose, Fisher, Noether, Gauss, and
Grace review it; it would not authorize a denominator, top-up, coverage,
`inference_ready`, `supported`, q4/q8, bridge, REML, AI-REML, or public-support
claim.

Q2-plus SR150 blockers, sigma-side interval-shape blockers, direct-correlation
undercoverage, artifact-dependency failures, endpoint-SD blockers, and true-q4
cross-block correlations remain separate lanes.

## 11. Team Learning

The cheap honest move after a failure taxonomy is not always more simulation.
For this slice, Rose keeps the command from becoming status, Fisher keeps one
seed from becoming a denominator, Noether keeps the target identity exact,
Gauss keeps the question numerical, and Grace keeps the host provenance and
approval gate fail-closed.
