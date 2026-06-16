#' drmTMB: Distributional Regression Models Using TMB
#'
#' `drmTMB` is a focused package for fast univariate and bivariate
#' distributional regression models. The core design goal is one formula per
#' distributional parameter, fitted by maximum marginal likelihood with Template
#' Model Builder.
#'
#' @section Status vocabulary:
#' Public documentation uses a small status vocabulary. "Stable" means a routine
#' fitted path with tests, diagnostics or interval status, and a reader-facing
#' example or guide. "First slice" means fitted and tested, but intentionally
#' narrow. "Opt-in control" means available for hardening, scalability, or memory
#' control, not a modelling guarantee for neighbouring surfaces. "Planned" or
#' "reserved" syntax may appear in roadmap or formula-grammar text, but should be
#' rejected by `drmTMB()` or treated as design-only until likelihood, tests,
#' documentation, and after-task evidence land. "Unsupported" or "blocked"
#' syntax should not be used as analysis syntax.
#'
#' @keywords internal
#' @importFrom Matrix sparseMatrix
#' @importFrom TMB MakeADFun sdreport
#' @importFrom cli cli_abort cli_text
#' @importFrom stats ave coef complete.cases delete.response deviance df.residual
#' @importFrom stats gaussian logLik nobs
#' @importFrom stats lm.fit model.frame model.matrix model.response na.omit
#' @importFrom stats nlminb predict residuals rnorm sd sigma simulate terms vcov
#' @importFrom utils packageVersion
#' @useDynLib drmTMB, .registration = TRUE
"_PACKAGE"
