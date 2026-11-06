## 2026-10-20: Clean-current stage-two receipt validation

The R combiner now reads and validates each clean-current conversion receipt
against its prepared-root receipt, frozen source mapping, batch manifest, and
GO-record hash. The exact clean-current receipt path passes; a changed source
row endpoint is rejected. Python stage-two tests passed 40/40, R stage-two
rules passed, the combiner test passed with its expected legacy replay
rejection, Python compilation passed, and `git diff --check` passed. No fits or
compute jobs ran. A complete clean-current prepare-to-run-to-combine test is
still outstanding, so this is adapter integrity evidence only, not campaign
readiness or statistical calibration. Report:
`docs/dev-log/after-task/2026-10-20-clean-current-stage-two-mode-adapter.md`.

The combiner test also runs the production R batch reader over all three
synthetic, sealed clean-current batches of terminal errors. It checks the
returned global source indices from 1 through 9,000 without fitting models.

NotebookLM auth was verified as `itchyshin@gmail.com`; all 14 indexed sources
were ready. Its synthesis and direct checks of Joe (2008), Stringer (2023),
and the glmmTMB covariance vignette found no direct evidence for calibrated
continuous predictor-dependent latent-SD slopes. Laplace bias and quadrature
results inform the validation design but do not establish slope calibration.
