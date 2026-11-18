# 2026-10-27: Native NB2 correlated q2 predictor-dependent SD

- Implementation: the existing ordinary NB2 q2 likelihood already applies coefficient-specific group SD rows. The NB2 family adapter now admits the same unlabelled q2 target shape as Poisson, while the shared resolver still rejects q3 and other unsupported blocks.
- Focused command: `Rscript -e 'devtools::test(filter = "nbinom2-correlated-q2-sd")'`; 12 passed, 0 failed, 0 warnings, 0 skipped (48.0 s).
- Adjacent command: `Rscript -e 'devtools::test(filter = "nbinom2-(ordinary-correlated-q2|correlated-q2-sd)")'`; 37 passed, 0 failed, 0 warnings, 0 skipped (51.1 s).
- `pkgdown::check_pkgdown()` found no problems; only existing Pandoc `--mathml` deprecation warnings. Full `pkgdown::build_site()` completed successfully; the formula grammar and predictor-dependent SD articles built with only existing Pandoc deprecation warnings. The source-bound render of `vignettes/predictor-dependent-random-sd.Rmd` completed; the first attempt had loaded the installed package from another worktree and failed before reaching this section.
- The direct-SD evidence ledger now links the two ordinary NB2 q2 coefficient targets to a hash-checked recovery receipt. The frozen capability rows remain unresolved; this evidence does not promote general family support.
- `gh issue list --state open --search '"correlated NB2" "SD"' --limit 10` returned no matching open issue. No issue was opened, updated, or closed.
- Interval calibration, an independent NB2 integration oracle, structured q2, broader NB2 combinations, and Julia parity remain open.

- Full `git diff --check` reports one trailing blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`, outside this slice and left untouched. A recovery checkpoint for continuing the broad goal is `docs/dev-log/recovery-checkpoints/2026-10-27-210844-codex-checkpoint.md`.
