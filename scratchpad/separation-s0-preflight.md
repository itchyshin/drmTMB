## Git/lane

- Worktree: `/Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0`
- Branch: `codex/fixed-design-binary-separation-experiment`
- HEAD: `b441227fa0e11f9ab4347fc963266801cfb75a5f`
- `git status --porcelain=v1`: empty; no diff.
- Lane is fixed-effect-only; repository rules prioritize fixed-effect likelihoods before random effects [AGENTS.md:897-927](AGENTS.md:897).

## Existing capability

- Fixed-effect binomial `mu` is implemented, logit-linked, with binary and `cbind(success, failure)` encodings [DESCRIPTION:15-18](DESCRIPTION:15).
- Hurdle `hu` is implemented only through `truncated_nbinom2()`, with fixed-effect hurdle routes explicitly supported [R/drmTMB.R:57-63](R/drmTMB.R:57); hurdle random effects are rejected [R/drmTMB.R:7716-7722](R/drmTMB.R:7716).
- No `detectseparation` or `brglm2` textual hits occurred in current source/docs. Generic “separation” references are unrelated. This does not prove absence from every installed namespace.

## Exact fit/extractor call map

Fixed-effect binomial `mu`:

```r
fit_mu <- drmTMB(
  bf(y01 ~ x),
  family = stats::binomial(link = "logit"),
  data = dat
)
coef(fit_mu, dpar = "mu")
```

The repository’s exact binary example is [docs/design/175-phase-18-binomial-fixed-effect-artifacts.md:43-52](docs/design/175-phase-18-binomial-fixed-effect-artifacts.md:43).

Fixed-effect hurdle `hu`:

```r
fit_hu <- drmTMB(
  bf(count ~ x, hu ~ w),
  family = truncated_nbinom2(),
  data = dat
)
coef(fit_hu, dpar = "mu")
coef(fit_hu, dpar = "hu")
```

`hu` must be one-sided; `sigma ~ 1` is supplied by default [R/drmTMB.R:7658-7678](R/drmTMB.R:7658). The source’s fixed-effect hurdle example is [R/drmTMB.R:7716-7722](R/drmTMB.R:7716).

For either fit:

- Coefficients: `coef(fit, dpar = "mu")`, `coef(fit, dpar = "hu")`; implementation returns `object$coefficients[[dpar]]` [R/methods.R:2291-2297](R/methods.R:2291).
- Stored objective: `fit$opt$objective`; stored log-likelihood: `fit$logLik` [R/drmTMB.R:540-560](R/drmTMB.R:540).
- Raw TMB objective/gradient: `fit$obj$fn(fit$opt$par)` and `fit$obj$gr(fit$opt$par)`; the object is created by `TMB::MakeADFun()` [R/drmTMB.R:510-517](R/drmTMB.R:510).
- Convergence/message: `fit$opt$convergence`, `fit$opt$message`; `0` is the successful `nlminb` code [R/check.R:107-110](R/check.R:107).
- Full diagnostics: `check_drm(fit)`, including objective, fixed gradient, warnings, and Hessian [R/check.R:175-205](R/check.R:175).
- Hessian status: `fit$sdr$pdHess`; `is_converged(fit, include_hessian = TRUE)` requires optimizer success plus `pdHess = TRUE` [R/check.R:147-170](R/check.R:147).
- Warnings must be captured around the fit; source emits warnings for nonconvergence and nonfinite objectives [R/drmTMB.R:519-524](R/drmTMB.R:519).

## Dependency inventory

Exact isolated R command attempted:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e '...installed.packages()...'
```

Output:

```text
Fatal error: creating temporary file for '-e' failed
```

`R --version` output:

```text
R version 4.6.0 (2026-04-24) -- "Because it was There"
Platform: aarch64-apple-darwin23
```

Read-only DESCRIPTION fallback:

- Source-tree `drmTMB`: `0.6.0` [DESCRIPTION:1-3](DESCRIPTION:1)
- Filesystem package descriptions found: `drmTMB 0.6.0`, older `drmTMB 0.1.3.9000`, `brglm2 1.1.0`.
- `detectseparation`: not found by the filesystem fallback; active-library status remains unknown because R could not initialize.
- Relevant source requirements: `Matrix >= 1.6.0`, `TMB >= 1.9.6`, `RcppEigen`, and `TMB` [DESCRIPTION:31-43](DESCRIPTION:31).
- Read-only framework-library descriptions found:
  - R 4.5: TMB 1.9.17, Matrix 1.7-4, Rcpp 1.1.0, RcppEigen 0.3.4.0.2.
  - R 4.6 system library: Matrix 1.7-5; TMB/Rcpp/RcppEigen were not present there.

## File fence

Read-only fence used:

- `AGENTS.md`
- `DESCRIPTION`, `NAMESPACE`
- `R/drmTMB.R`, `R/family.R`, `R/methods.R`, `R/check.R`
- `docs/design/174-controls-and-convergence.md`
- `docs/design/175-phase-18-binomial-fixed-effect-artifacts.md`
- Narrow binomial/hurdle test references under `tests/testthat/`

No files were edited, staged, compiled, installed, fitted, or generated.

## Risks/unknowns

- R package-version probing was blocked by the sandbox’s inability to create R temporary files; active `drmTMB`, `brglm2`, and `detectseparation` library resolution is therefore unverified.
- No separation-specific detector is evidenced in the searched source/docs. Existing `check_drm()` diagnoses convergence, gradients, finite objective, and Hessian—not complete or quasi-complete binary separation specifically.
- Hurdle `hu` is a count-hurdle probability, not a binary-response `glm` separation route.

## Verdict

The smallest existing fit surfaces are available for fixed-effect binomial `mu` and fixed-effect hurdle-NB2 `hu`. Coefficients, objective, optimizer status, gradients, and Hessian status have clear extractors. A dedicated separation detector is not evidenced in the clean source/docs fence. Preflight is otherwise clean, but installed-package compatibility remains **UNVERIFIED** because isolated R startup could not create its temporary file.
