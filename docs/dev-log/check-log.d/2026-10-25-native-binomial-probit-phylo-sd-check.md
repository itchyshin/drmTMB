## 2026-10-25 - Native Binomial probit phylogenetic SD recovery

- Branch: `codex/general-sd-regression`
- Goal: Add a direct synthetic recovery check for probit phylogenetic SD regression in native TMB.
- Files changed: `tests/testthat/test-binomial-phylo-sd-regression.R`, `docs/dev-log/after-task/2026-10-25-native-binomial-probit-phylo-sd-check.md`
- Checks run:
  - `Rscript -e 'devtools::test(filter = "binomial-phylo-sd-regression", reporter = "summary")'`: passed with 80 tips, an absolute slope-recovery tolerance of 0.25, formula-aligned tip-SD predictions, and constant-SD likelihood equivalence.
  - `DRM_JL_JULIA_HOME='/Users/z3437171/.juliaup/bin' DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' Rscript -e 'devtools::test(filter = "julia-student-sd", reporter = "summary")'`: passed with two live Julia fits for the Student SD bridge path.
- Not run: full R suite, pkgdown, profiles, bootstrap, and interval coverage; this is focused point-recovery evidence only.
- Next safest action: resume Julia probit phylogenetic SD work after the shared fitter handoff.
