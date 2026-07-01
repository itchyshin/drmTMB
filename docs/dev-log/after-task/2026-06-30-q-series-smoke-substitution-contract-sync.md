# After Task: Q-Series Smoke-Substitution Contract Sync

## Goal

Make the Fisher/Rose/Grace smoke-substitution contract a first-class Q-Series
dashboard artifact, with Nibi/Rorqual allowed only for exact `n=5` substitute
smoke and still blocked for denominator work.

## Implemented

- Added `structured-re-q-series-smoke-substitution-contract.tsv` with three
  rows: q1 `mu` intercept smoke, q2 `mu1+mu2` intercept smoke, and phylo
  q2-plus-q2 intercept smoke.
- Added the smoke-contract summary card and contract table to the Q-Series
  widget; dashboard build is `r154`.
- Updated host-access rows so Nibi/Rorqual are
  `reachable_for_contract_bounded_smoke_only`.
- Updated q1/q2 row-selection, dry-run, q2 contract, q2-plus-q2 contract,
  local-smoke summaries, runners, README dashboard notes, validator, and focused
  tests so the contract is explicit and no denominator work is implied.
- Tightened q2 contract wording after the focused tests caught missing exact
  phrases: the q2 rows now state the Totoro/FIIA access failure, Nibi/Rorqual
  reachability, Fir missing qseries root, the smoke-substitution contract
  filename, and the denominator block.

## Mathematical Contract

No estimand, likelihood, interval rule, small-sample correction, simulation DGP,
or coverage denominator changed. This is a routing and evidence-boundary task:
it permits only exact `n=5` substitute smoke on Nibi/Rorqual under the named
contract and promotes no row.

## Files Changed

- `docs/dev-log/dashboard/structured-re-q-series-smoke-substitution-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-host-access-recheck.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-dry-run.tsv`
- `docs/dev-log/dashboard/structured-re-q2-intercept-interval-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-intercept-local-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-local-smoke.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- Matching q2 local-smoke mirrors under `docs/dev-log/simulation-artifacts/`
- `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`
- `tools/run-structured-re-q2-intercept-smoke.R`
- `tools/run-structured-re-q2-plus-q2-intercept-smoke.R`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 5 host-access recheck rows, and 3
  smoke-substitution contract rows.
- `cmp` passed for row-selection, q1 `mu` dry-run, q2 intercept local-smoke,
  and q2-plus-q2 local-smoke dashboard/artifact mirrors.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 8670 PASS / 0 FAIL / 0 WARN /
  0 SKIP.

## Tests Of The Tests

The focused suite failed before the final wording fix. The first rerun reported
8662 PASS / 8 FAIL because the q2 contract rows no longer carried the exact
host-reachability and denominator-block phrases. After tightening those rows, a
second rerun reported 8669 PASS / 1 FAIL because the filename appeared without
the plain-language phrase `smoke-substitution contract`. The final rerun passed,
which confirms the test is guarding the intended wording boundary.

## Consistency Audit

- Stale live-surface scan:
  `rg -n "write a Fisher/Rose/Grace|without a Fisher/Rose/Grace smoke-substitution contract|not smoke substitutes without review|blocked as smoke substitutes before Fisher/Rose/Grace contract|before Fisher/Rose/Grace contract|restore Totoro/FIIA access or write|does not make Nibi/Rorqual|reachable_but_not_smoke_substitute_without_contract|ready_for_totoro_fiia_smoke|totoro_fiia_smoke_operational_hold|totoro_fiia_n5_smoke_after_fisher_rose_signoff" docs/dev-log/dashboard/structured-re-*.tsv tools/run-structured-re-q2-intercept-smoke.R tools/run-structured-re-q2-plus-q2-intercept-smoke.R tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/dashboard/README.md`
  returned no matches.
- Positive contract scan confirmed current live q2 surfaces mention
  `Nibi/Rorqual reachable with qseries roots`,
  `Nibi/Rorqual allowed only for exact n=5 smoke`, the smoke-substitution
  contract filename, and the denominator-work block.
- No examples, vignettes, formula grammar, likelihood equations, NEWS, ROADMAP,
  known-limitations, or pkgdown navigation changed; the task changes dashboard
  and evidence ledgers only.

## GitHub Issue Maintenance

`gh issue list --search "Q-Series OR qseries OR structured RE smoke-substitution"
--limit 20 --json number,title,state,url` returned `[]`, so no issue was opened
or commented.

## What Did Not Go Smoothly

- The first focused test rerun exposed that mission control accepted the
  contract file but the R-side test expected stronger row-level q2 wording.
- The first wording patch compressed reachability and permission into one
  clause, which broke the exact `Nibi/Rorqual allowed only for exact n=5 smoke`
  guard. The final wording separates reachability from permission.
- The contract filename alone was not enough for the R test; the plain-language
  phrase `smoke-substitution contract` now appears beside it.

## Team Learning

Rose and Fisher need both positive and negative text guards for host routes.
Grace's reproducibility boundary is now visible in the widget: Nibi/Rorqual are
reachable, but only for the exact contract-bounded smoke lane, with denominator
work still held for artifact review.

## Known Limitations

- This does not run the Nibi/Rorqual smoke itself.
- This does not promote `interval_status`, `coverage_status`,
  `inference_ready`, or `supported` for any Q-Series row.
- This does not authorize q4/q8, non-Gaussian, REML, AI-REML, bridge, DRAC
  denominator, or public-support claims.

## Next Actions

Run one contract-bounded Nibi or Rorqual `n=5` smoke lane from
`structured-re-q-series-smoke-substitution-contract.tsv`, preserving raw
replicate TSVs, summaries, seed manifest, session info, git SHA, module list,
logs, and exact command line. Fisher/Rose must review that host artifact before
any denominator work.
