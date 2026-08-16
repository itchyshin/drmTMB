# A5 — the three flagged vacuous-shape sites: all three are REAL (2026-08-15 overnight)

Verified by reading the producers, no R run:

| site | verdict | evidence |
| --- | --- | --- |
| `test-animal-relmat-gaussian.R` (`q8_pairs_ci$conf.low`) | REAL | `R/methods.R:1035,1067` create `pairs$conf.low`; the adjacent `conf.status` equality against a length-28 vector would fail on NULL |
| `test-phase18-biv-gaussian-q8-endpoint-recovery.R:67-69` | REAL, self-protecting | the test asserts `all(c("conf.low","conf.high") %in% names(out$wald_intervals))` on the line ABOVE the `all(is.na(...))` |
| `test-julia-inference.R:155-156` (`s$coefficients$conf.low`) | REAL | `R/methods.R:4919` and `R/julia-bridge.R:2723` construct `coefficients$conf.low` |

Correction to the 2026-08-15 sweep that flagged them: it grepped the `expect_true(all(...))` lines
without their surrounding context, so it could not see site 2's own existence pin. The sweep's
CLASS was right (all() over a silently-empty vector passes vacuously); these three INSTANCES carry
real columns. Issue 7 of the evidence-rewire after-task closes with zero fixes needed.
