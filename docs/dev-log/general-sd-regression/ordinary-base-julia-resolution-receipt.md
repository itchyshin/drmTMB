# Julia ordinary-base resolution receipt

This appendix resolves the 44 Julia `needs_review` rows in `ordinary-base-status.tsv` against the frozen Julia source pin `b1832c7a686decf4e3d7a06ad8382bf164b9d8d4`. Native rows and source were left unchanged. The task was source-only: no fits, source edits, or candidate-branch inference.

| Rows | Resolution | Pinned evidence |
| ---: | --- | --- |
| 2 | Gaussian `sigma`: one ordinary random intercept admitted; independent numeric slope blocked | `src/gaussian_core.jl:993-1001` explicitly requires a single intercept |
| 1 | Lognormal `mu` independent numeric slope blocked; its admitted correlated `(1+x|g)` is a different mechanism | `src/lognormal.jl:88-105` |
| 1 | Gamma `mu` independent numeric slope blocked; accepted single-term forms are intercept or correlated slope | `src/gamma.jl:110-136` |
| 1 | Poisson `mu` independent numeric slope blocked; accepted ordinary forms are `(1|g)` or `(1+x|g)` | `src/poisson.jl:209-251` |
| 2 | Zero-inflated Poisson `mu` intercept/slope blocked when `zi` is present | `src/poisson.jl:209-215,254-255` |
| 1 | NB2 `mu` independent numeric slope blocked; accepted single-term forms are intercept or correlated slope | `src/negbinomial.jl:149-178` |
| 2 | Zero-inflated NB2 `mu` intercept/slope blocked when `zi` is present | `src/negbinomial.jl:149-153,181-185` |
| 2 | Hurdle NB2 `mu` intercept/slope blocked by the wrapper's fixed-effects-only guard | `src/negbinomial.jl:491-525` |
| 10 | Bivariate Gaussian ordinary effects on `mu1`, `mu2`, `sigma1`, `sigma2`, `rho12` blocked; residual route is random-effect-free and structured routes use structured markers | `src/gaussian_bivariate.jl:151-223,675-684` |
| 10 | Bivariate lognormal ordinary effects on those endpoints blocked; delegates to the Gaussian residual/q2/q4 dispatcher | `src/bivariate_lognormal.jl:106-116`, `src/gaussian_bivariate.jl:151-223,675-684` |
| 12 | Bivariate Student ordinary effects on `mu1`, `mu2`, `sigma1`, `sigma2`, `nu`, `rho12` blocked; route is explicitly residual-only | `src/bivariate_student.jl:69-83,116-125` |

The 44 rows resolve to one admitted Gaussian `sigma` intercept and 43 base-blocked rows. The resulting full table has 16 Julia `base_source_admitted`, 96 Julia `base_blocked`, and zero Julia `needs_review`; native remains 52 admitted and 60 blocked. `base_blocked` is scoped to the row's ordinary-intercept or independent-slope shape. For example, a correlated intercept-plus-slope branch does not admit the separate independent numeric-slope row.

This resolves only the ordinary base-route question for the inventoried rows. It does not establish direct SD-regression support, interactions between endpoints, random-effect covariance/block composition, or the full provider/layout universe; G0 remains open.
