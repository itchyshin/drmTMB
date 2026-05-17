# After Task: Slice 140 emmeans interaction grid

## Goal

Add positive coverage that ordinary fixed-effect `mu` interactions work on an
explicit `emmeans()` reference grid.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Gaussian fixed-effect
interaction model, `bf(y ~ habitat * x, sigma ~ 1)`, and checks that
`emmeans(fit, ~ habitat, at = list(x = 0.4))` matches
`predict(dpar = "mu")` on the same interaction grid.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes record this as
ordinary fixed-effect interaction-grid parity. The wording does not claim slope
estimation or a new marginalisation contract.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-140-emmeans-interaction-grid.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-224815-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`

## Checks Run

- No-edit scout:
  `emmeans()` on a Gaussian `habitat * x` fit matched `predict(dpar = "mu")`
  exactly at `x = 0.4`.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 140 interaction-grid wording and test
  evidence: found the expected entries.
- Stale-claim scan for slopes or new marginalisation from interaction wording:
  no false support claims; the only match was the intentional design note that
  this is not slope estimation or a new marginalisation contract.
- Upstream Slice 134 PR #99 merged with squash commit
  `4a10206ce2444b77dcd40e71fc20019b2b25c01b`.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-224815-codex-checkpoint.md`.

## Post-Rebase Checks

- PR #104 merged as `aaa6c673fce40d2625245ec9c281adbc35385b19`.
- `git rebase --onto origin/main f6abdf561b1ba701c6ddd7a907ddd6534f078a4f`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

This test uses the same fixed-effect model matrix that `predict()` uses, so the
interaction terms are checked as conditional design-point predictions. It does
not turn interactions into slope estimates, trends, or empirical row-weighted
margins.

## Known Limitations

- This slice covers ordinary fixed-effect interactions for fixed-effect
  univariate `mu` only.
- No slope, non-`mu`, transformed-response, empirical-marginalisation,
  random-effect, or blocked-model workflow is added.

## Team Notes

Pat should keep interaction examples explicit about the conditioning value of
the numeric covariate. Rose should keep stale-claim scans looking for accidental
slopes or marginalisation language around interaction EMMs.
