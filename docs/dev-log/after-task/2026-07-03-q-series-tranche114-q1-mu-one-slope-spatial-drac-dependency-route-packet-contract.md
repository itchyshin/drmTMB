# Q-Series Tranche 114 q1 mu one-slope spatial DRAC dependency-route packet contract

## 1. Goal

Bank the Tranche 114 no-compute dependency-route packet/contract for the q1
`mu` one-slope spatial DRAC lane after the Tranche 113 dependency/provenance
review. The tranche must spend zero host compute, make no package-install or
package-load success claim, and prepare only the reviewed route for a possible
Tranche 115 no-model dependency-route proof.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche114-spatial-drac-dependency-route-packet-contract.tsv`
with 12 rows: the T113 import, installer-error patch contract,
dependency-source route contract, Rlib reuse policy, source-SHA contract,
terminal-status contract, candidate packet, syntax boundary, no-model boundary,
no-denominator boundary, T115 gate, and tranche summary.

Added local-only contract artifacts under
`docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche114-spatial-drac-dependency-route-packet-contract/`:
`t114-dependency-route-packet-contract.txt`,
`t114-install-packages-contract.R`,
`t114-source-provenance-contract.tsv`,
`t114-terminal-status-contract.tsv`, and
`q1-mu-slope-spatial-t114-dependency-route-proof.sbatch`.

Updated Mission Control rendering, `version.txt`, validator checks, the focused
conversion-contract test, dashboard README, completion map, next-campaign queue,
and member-board rows. Rose/Fisher/Gauss/Noether/Grace remain blocking for any
future T115 proof.

## 3a. Decisions and Rejected Alternatives

Selected a no-compute packet contract instead of rerunning the Rorqual job. T112
already showed the next blocker: CRAN `PACKAGES` was unreachable and the
installer error branch called `conditionMessage()` on a logical value. T114 fixes
the packet contract first, rejects direct CRAN on an allocation, requires a
file/pre-staged dependency source, and requires source SHA
`56add7f04fab7bec57a42e56eaeb090dff491863` before any install.

Rejected treating T112/T113/T114 rows as package-install success, package-load
success, fit evidence, retained-denominator evidence, admission evidence, or
coverage evidence.

## 4. Files Touched

Core T114 files:
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche114-spatial-drac-dependency-route-packet-contract.tsv`,
`docs/dev-log/dashboard/member-discussions.tsv`,
`docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`,
`docs/dev-log/dashboard/index.html`, `docs/dev-log/dashboard/version.txt`,
`tools/validate-mission-control.py`, and
`tests/testthat/test-structured-re-conversion-contracts.R`.

Documentation and report files:
`docs/dev-log/dashboard/README.md`,
`docs/design/218-structured-q-series-completion-map.md`,
`docs/dev-log/check-log.md`, and this after-task report.

## 5. Checks Run

- `python3` TSV width scan for the T114 sidecar, `member-discussions.tsv`, and
  `structured-re-q-series-next-campaign-queue.tsv`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche114-spatial-drac-dependency-route-packet-contract/t114-install-packages-contract.R'))"`:
  passed.
- `bash -n docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche114-spatial-drac-dependency-route-packet-contract/q1-mu-slope-spatial-t114-dependency-route-proof.sbatch`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `node --check /tmp/drmtmb-mission-control-index-r308.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed and reported 12 T114 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'Sys.setenv(OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`:
  passed.
- Q-Series support invariant: `104 96 8 0 0 0 0`.
- Served Mission Control version: `r308`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused test now treats the T114 sidecar as the latest q1 `mu` one-slope
queue evidence and checks the T114 row IDs, linked artifacts, local contract
phrases, queue wording, member-board claims, and unchanged support-cell status.
The older T113 test now pins its meeting evidence to the T113 sidecar so the
latest-evidence helper cannot silently rewrite historical reviewer rows.

## 7a. Issue Ledger

No new package-code issue was opened by T114. The unresolved next issue is still
the DRAC dependency route: T115 may run at most one allocation-safe no-model
Rorqual proof after checkpoint and blocking review. It must use an offline or
pre-staged dependency source, record source SHA provenance, use the patched
installer status handling, and stop before `R CMD INSTALL`, `library(drmTMB)`,
smoke runner, model formula, model fit, retained denominator, coverage, top-up,
or support-cell status edit.

## 8. Consistency Audit

Mission Control still reports 104 Q-Series support cells, 8 `inference_ready`
rows, 0 `supported` rows, 0 coverage-authorized rows, and 0 q4
coverage-authorized rows. The q1 `mu` one-slope spatial cell remains
`point_fit/planned/planned`.

T114 changes no public API, formula grammar, `R/`, `src/`, pkgdown, README,
NEWS, or support-cell status. It updates only docs, dashboard ledgers,
validator/test contracts, and local contract artifacts.

## 9. What Did Not Go Smoothly

The tranche exists because T112 exposed two independent route hazards: allocation
network access to CRAN was unavailable, and the installer error branch did not
handle non-condition results safely. T114 resolves those as a packet contract,
not as proof that dependencies can install.

## 10. Known Residuals

No host command was run in T114. No dependency was installed, no package was
loaded, no model was fit, no denominator was created, and no coverage or
promotion claim moved. T115 remains a gated follow-up, not an automatic compute
step.

## 11. Team Learning

Rose's audit boundary is now encoded in the validator and focused test: route
packets are not package-install success. Grace's provenance boundary is also
encoded: future proof must carry the expected source SHA and host-separated
provenance before any install attempt.
