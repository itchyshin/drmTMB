# Julia SD candidate-availability documentation checks

- git diff --check over the scoped status/docs paths: PASS.
- python3 ~/shinichi-brain/tools/slop_check.py with absolute scoped paths: FINDINGS: 0.
- R parse of R/random-effect-scale-formulas.R and tools::parse_Rd() of man/random_effect_scale_formulas.Rd: PASS.
- Required support inventory search: rg -n -i 'julia.{0,80}(bernoulli|beta|gamma|student|nb2|sd-regress)|((bernoulli|beta|gamma|student|nb2).{0,80}julia)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml.
- Candidate/parity/calibration search: rg -n -i 'current shared/released DRM\.jl|candidate.{0,50}(parity|calibration)|same-data (engine )?parity|interval calibration' across scoped status, design, and vignette files.
- File-specific lane preflight was run for docs/dev-log/known-limitations.md before correcting two stale Julia route statements.
- No package tests or renders were run. The full package and rendered site remain unchecked.
