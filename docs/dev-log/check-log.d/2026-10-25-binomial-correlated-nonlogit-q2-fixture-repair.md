## 2026-10-25: Repair correlated Binomial q2 probit/cloglog recovery fixture

- Corrected the test generator to use shared standard-normal draws for the correlated intercept and slope effects. The fixed design has 160 groups, 32 observations per group, SD slopes 0.65 and -0.5, and correlation 0.5.
- Added signed recovery checks for both SD slopes and the positive correlation. Retained the link-specific independent Gauss-Hermite marginal likelihood oracle.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-binomial-correlated-sd.R", reporter = "summary")'`: exit 0, passed in about 77 seconds.
- The initial recovery design failed the intercept SD slope check and was replaced with the higher-information design without widening the final tolerances.
- `Rscript /Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R docs/dev-log/after-task/2026-10-25-binomial-correlated-nonlogit-q2-fixture-repair.md`: structure passed; acceptance ledger status `UNKNOWN` because 13 ledger files are not runnable.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py <after-task-report>`: `FINDINGS: 0`.
- `benchmark.py assessment-check ... --mode independent --version v1`: `ASSESSMENT_RECORDED` for the exact report hash. This records fields and identity only; the style score is an uncalibrated self-assessment.
- Scoped `git diff --no-index --check /dev/null` checks reported clean for the untracked test and report. No package-wide suite, Julia bridge fit, interval coverage, or documentation render was run.
- Main `docs/dev-log/check-log.md` update is pending review of its 449 divergent refs and confirmation from the active documentation-audit lane.

The native q2 test covers one fixed-seed probit and cloglog point-recovery fixture. It does not establish Julia parity or interval coverage. No programme gate closes.

SHA-256:

| File | SHA-256 |
|---|---|
| `tests/testthat/test-binomial-correlated-sd.R` | `7f5a8812257691545c4c5247af4de5e47add987de8e7d365a63c979a04bde21b` |
| `docs/dev-log/after-task/2026-10-25-binomial-correlated-nonlogit-q2-fixture-repair.md` | `be646a2df805b189f8e19fa19d6a584eba2feea776279c58072ff35e0dc94af2` |
