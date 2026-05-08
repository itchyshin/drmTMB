#' drmTMB: Distributional Regression Models Using TMB
#'
#' `drmTMB` is a focused package for fast univariate and bivariate
#' distributional regression models. The core design goal is one formula per
#' distributional parameter, fitted by maximum marginal likelihood with Template
#' Model Builder.
#'
#' @keywords internal
#' @importFrom Matrix sparseMatrix
#' @importFrom TMB MakeADFun sdreport
#' @importFrom cli cli_abort cli_text
#' @importFrom stats coef complete.cases delete.response deviance df.residual
#' @importFrom stats gaussian logLik nobs
#' @importFrom stats lm.fit model.frame model.matrix model.response na.omit
#' @importFrom stats nlminb predict residuals rnorm sd sigma simulate terms vcov
#' @importFrom utils packageVersion
#' @useDynLib drmTMB, .registration = TRUE
"_PACKAGE"
