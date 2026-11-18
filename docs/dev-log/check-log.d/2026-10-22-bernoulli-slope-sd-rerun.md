# 2026-10-22: native Bernoulli independent-slope SD regression rerun

- Worktree branch: `codex/general-sd-regression`, HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^binomial-sd-integration$", reporter = "summary")'`.
- Result: PASS. The focused `tests/testthat/test-binomial-sd-integration.R` file completed with no failed assertions. The testthat output states that no live Julia tests ran in this configuration.
- Current source SHA-256: `R/drmTMB.R` `a8a99c9ea3bcc8af1e824f4a6e71cd62f5d294c9795f5ea88b4ef5713fa80e2b`; `src/drmTMB.cpp` `e42e51c3050bf3c11e000df7966da9ca0db630e5f193ae35f20bc0b40edd8c79`; test file `afc4a14d3ec43a1fdae3405384f9fa7262b18b35da7b1668a0373100bfb8bfe9`.
- Scope: this verifies the existing native candidate test for a Bernoulli independent random slope, including recovery direction, named SD predictions, an independent scalar Laplace oracle, profile execution, simulation, save/reload, constant-SD equivalence, and two bootstrap refits. It is not a live Julia check, coverage result, or calibration result.
- A prior `git diff --check` reports one added blank line at EOF in the pre-existing dirty test file (line 225). This rerun did not edit that file.
- Issue search: `gh issue list --repo itchyshin/drmTMB --state open --search 'Bernoulli random effect SD slope' --limit 20 --json number,title,url` returned no matches.
