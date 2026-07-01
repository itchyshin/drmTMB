# After Task: Q-Series Gaussian low-q q1 mu-intercept smoke contract

## 1. Goal

Record the Fisher/Rose-reviewed tiny-smoke contract for the four Gaussian low-q
q1 `mu` intercept rows, without running denominator work and without promoting
any Q-Series row.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian low-q q1 `mu`
intercept Totoro/FIIA smoke-contract channel, with `n = 5` planned smoke
replicates, all attempted replicates retained, and fixture-only interpretation.
It does not claim `interval_status`, `coverage_status`, `inference_ready`,
`supported`, sigma readiness, matched `mu+sigma` readiness, q2/q4/q8 readiness,
direct-SD readiness, `phylo_interaction()` readiness, non-Gaussian interval
readiness, REML, AI-REML, Nibi/Rorqual/DRAC denominator evidence, bridge
support, or public support.

Added
`docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv`
with one row for each reviewed smoke candidate:

- `qseries_phylo_q1_mu_intercept`;
- `qseries_spatial_q1_mu_intercept`;
- `qseries_animal_q1_mu_intercept`;
- `qseries_relmat_q1_mu_intercept`.

The contract records Fisher and Rose sign-off for a tiny Totoro/FIIA smoke only.
The interval channel is default `confint()` Wald extraction for direct
`sd:mu:<provider>(1 | group)` targets. The linked support cells remain
`point_fit/planned/planned`.

Mission control now validates the smoke-contract schema, linked dry-run rows,
linked support-cell statuses, artifact requirements, stop rules, no-promotion
wording, and next-gate language. The widget renders a "Low-q mu smoke" card and
table at build `r122`.

## 3a. Decisions and Rejected Alternatives

Decision: keep Totoro/FIIA as the only approved smoke hosts for this gate. Nibi
and Rorqual are reachable after loading `StdEnv/2023 gcc/12.3 r/4.4.0`, but
they remain scientifically blocked for this slice until the tiny smoke passes.

Decision: do not mark the smoke as executed. Non-interactive SSH to Totoro still
fails from this local session, and the `fiia` alias is not resolvable here.

Rejected alternatives:

- Do not convert the local n=2 dry-run into coverage evidence.
- Do not use Nibi/Rorqual/DRAC for the first smoke just because the hosts are
  reachable.
- Do not promote q1 `mu` intercept rows to `inference_ready`.
- Do not let sigma, matched `mu+sigma`, q2, q4/q8, direct-SD,
  `phylo_interaction()`, or non-Gaussian rows inherit this contract.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-mu-intercept-smoke-contract.md`

## 5. Checks Run

- `ssh -o BatchMode=yes -o ConnectTimeout=8 totoro 'hostname; pwd; command -v Rscript || true; Rscript --version 2>&1 || true'`:
  failed with `Permission denied (publickey,password)`.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 fiia 'hostname; pwd; command -v Rscript || true; Rscript --version 2>&1 || true'`:
  failed because the `fiia` hostname could not be resolved.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 nibi 'module load StdEnv/2023 gcc/12.3 r/4.4.0 >/dev/null 2>&1; command -v Rscript; Rscript --version 2>&1'`:
  passed; `Rscript` resolved to the DRAC R 4.4.0 module.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 rorqual 'module load StdEnv/2023 gcc/12.3 r/4.4.0 >/dev/null 2>&1; command -v Rscript; Rscript --version 2>&1'`:
  passed; `Rscript` resolved to the DRAC R 4.4.0 module.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R")); cat("parse_ok\n")'`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series cells,
  4 Gaussian low-q mu-intercept dry-run rows, and 4 Gaussian low-q mu-intercept
  smoke-contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  7587 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- Dashboard JavaScript parse check with `node --check /tmp/drmtmb-dashboard-index.js`:
  passed.
- Served dashboard refresh: stopped a stale local `python3 -m http.server
  8765 --directory /tmp/drm-dashboard` process that was returning empty
  replies, relaunched the detached `drmtmb-mission-control` server, and
  verified `http://127.0.0.1:8765/version.txt` returned `r122`,
  `structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv` served 5
  lines including the header, and `/` contained `Low-q mu smoke`, the smoke
  contract TSV fetch path, and build `r122`.
- Harmful-phrase scan for `n=5 coverage evidence`, `smoke coverage evidence`,
  `smoke passed coverage`, `ready for DRAC`, `promoted to inference_ready`, and
  `promoted to supported` across the dashboard, check log, and after-task
  directory: passed with no misleading smoke-promotion hits.
- `git diff --check`: passed after this report was written.

## 6. Tests of the Tests

The focused test now requires exactly four smoke-contract rows, exact
provider/cell linkage, `n = 5`, Totoro/FIIA-only allowed hosts, blocked
Nibi/Rorqual/DRAC hosts, Fisher/Rose tiny-smoke-only sign-off, not-executed
compute status, dry-run linkage, `point_fit/planned/planned` support-cell
statuses, required artifacts, stop rules, no-claim strings, and next-gate
language.

Mission control repeats those checks and also verifies that each evidence URL
resolves locally.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control contract evidence for the active Q-Series board.

## 8. Consistency Audit

Checked the support-cell TSV, Gaussian low-q row-selection sidecar, Gaussian
low-q dry-run sidecar, new smoke-contract sidecar, dashboard renderer, dashboard
README, validator, focused tests, and host-connectivity evidence.

The board remains 104 rows. The four q1 `mu` intercept rows remain
`point_fit/planned/planned`, not `inference_ready` or `supported`. No structured
row is newly promoted by this contract.

## 9. What Did Not Go Smoothly

The host reality is split: Nibi and Rorqual are reachable and module-ready, but
Totoro still rejects non-interactive SSH from this session and `fiia` is not a
known hostname. The sidecar therefore records the scientific smoke contract
without pretending the smoke has already run.

## 10. Known Residuals

The four q1 `mu` intercept rows still need an actual Totoro/FIIA n=5 smoke, raw
replicate TSVs, seed manifest, session information, and Fisher/Rose review
before any Nibi/Rorqual/DRAC denominator work.

Sigma, matched `mu+sigma`, q2 intercept, direct-SD, `phylo_interaction()`,
q4/q8, and non-Gaussian interval rows remain separate unfinished arcs.

## 11. Team Learning

Host reachability is not a status gate by itself. The board should record both:
which machines are technically reachable and which machines are scientifically
authorized for the next denominator step.
