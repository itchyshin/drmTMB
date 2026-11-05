# 2026-10-20: beta-binomial independent-slope SD smoke

- Focused test: `Rscript -e "devtools::test(filter = '^beta-binomial-sd-slope$', reporter = 'summary')"` passed 12 assertions, including formula assembly, a fixed-seed fit, SD prediction, simulation, and save/reload prediction.
- Documentation check: `Rscript -e "pkgdown::check_pkgdown()"` reported no problems; Pandoc emitted its existing `--mathml` deprecation warning.
- Independent likelihood check: a separate per-group numerical quadrature test passed against the fitted Laplace log likelihood; reversing the group SD map gave a worse value. This is one seeded case, not broad validation.
- Scope: one native TMB complete-response beta-binomial location slope with fixed `sigma`; Julia parity and interval calibration remain open.
- Full details: `docs/dev-log/after-task/2026-10-20-beta-binomial-sd-slope.md`.
