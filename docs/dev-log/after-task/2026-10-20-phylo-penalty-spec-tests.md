# After task: fit-free tests for the phylogenetic penalty helpers

Reader: a maintainer changing `R/penalty.R`.

- Problem: `drm_phylo_penalty()`, `drm_parse_phylo_penalty()` and
  `drm_apply_phylo_penalty_spec()` were only exercised through full fits, so
  about ten abort branches had no direct test.
- Change: test-only. `tests/testthat/test-phylo-penalty-spec.R` adds 63
  fit-free expectations on a hand-built minimal spec (class and fields,
  every validation abort, parse of NULL / penalty object / other input, spec
  writes, the `drm_phylo_cor_penalty_needs_two_sd` class, NULL penalty
  leaving the spec unchanged).
- Findings: no bug found. There is no `print` method for `drm_phylo_penalty`;
  the default list print is tested. `drm_parse_phylo_penalty()` accepts only
  NULL or a classed object (no list or numeric forms), and does not re-check
  the fields of a classed object edited by hand.
- Skips: none added, so the env-skip census is unchanged.
- Not done: no `R/` change, no NEWS entry.
