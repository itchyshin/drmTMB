# 2026-10-20: Student phylogenetic SD selector guard

The Student builder classified `sd_phylo()` as an SD formula but never passed the entries into a phylogenetic SD structure. A new regression test reproduced the silent acceptance using an ordinary Student random intercept plus `sd(species, level = "phylogenetic") ~ w`. The builder now fails clearly with an unsupported-route error.

Checks:

- Before fix: `Rscript -e "devtools::test(filter = 'student-sd-regression', reporter = 'summary')"` failed at the new expectation because no error was raised.
- After fix: the same focused regression suite passed.
- `Rscript -e "devtools::test(filter = 'student-sd-integration', reporter = 'summary')"` passed the neighboring Student SD fit/output tests.
- `git diff --check -- R/drmTMB.R tests/testthat/test-student-sd-regression.R` passed.

This is a truthful admission guard only. Student phylogenetic SD regression remains unsupported; no interval calibration claim follows.
