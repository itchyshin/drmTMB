| Date | Slice | Evidence | Boundary |
| --- | --- | --- | --- |
| 2026-10-22 | emmeans preflight contract tests (#1602) | `devtools::test(filter = "emmeans-preflight-contract")` completed without failures on R 4.6.0 / macOS ARM64; `Rscript tools/write-env-skip-census.R --check` passed with 913 call sites. | Test and census only; package code unchanged. Full package checks and the live Julia engine were not run; fresh PR-head CI remains pending. |
