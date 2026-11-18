# Check log: Binomial animal and relmat kernel equivalence

- Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-kernel-equivalence-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`
- First run: exit 0; 62 expectations passed; 0 failures, 0 warnings, 0 skips; 135.2 seconds.
- Captured rerun: exit 0; console transcript saved in `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-kernel-nonlogit-20261027/focused-tests.log`.
- Source manifest: five files hashed before the captured rerun; all hashes matched afterward.
- Evidence reconciliation: `python3 tools/general-sd-regression/reconcile_evidence.py` passed at 135 linked rows / 19,678 candidate rows / 157 evidence records.
- Status inventory patterns: `rg "meta_gaussian|tau ~|rho ~|meta_known_V\\\\([^V]|meta_known_V\\\\(V = V\\\\).*(current|preferred|stable|default)" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`; `rg "rho12|sigma1|sigma2|sd\\\\(" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`.
- After-task structure check passed; acceptance-gate state is UNKNOWN because the gate runner is unavailable.
- Prose check: 0 findings. Targeted whitespace check passed.
- No full suite, pkgdown build, live Julia engine, recovery campaign, or interval calibration was run.
- Eight rows were linked for animal A-inverse and pedigree crossed with relmat K and Q under probit and cloglog; all are marked unreviewed.
