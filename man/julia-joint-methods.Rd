\name{julia-joint-methods}
\alias{coef.drmTMB_julia_joint}
\alias{vcov.drmTMB_julia_joint}
\alias{nobs.drmTMB_julia_joint}
\alias{predict.drmTMB_julia_joint}
\alias{imputed.drmTMB_julia_joint}
\alias{summary.drmTMB_julia_joint}
\alias{confint.drmTMB_julia_joint}
\title{Inspect a Julia joint missing-predictor fit}
\description{
Methods for Gaussian response models with one additive \code{mi()} predictor,
using a fixed-effect Gaussian or Bernoulli predictor model through
\code{engine = "julia"}. This experimental route uses the shared DRM.jl joint
likelihood. Other missing-predictor families and structures remain separate
implementation work.
}
\usage{
\method{coef}{drmTMB_julia_joint}(object, dpar = NULL, ...)
\method{vcov}{drmTMB_julia_joint}(object, ...)
\method{nobs}{drmTMB_julia_joint}(object, ...)
\method{predict}{drmTMB_julia_joint}(object, newdata = NULL,
  dpar = c("mu", "sigma"), type = c("response", "link"), ...)
\method{imputed}{drmTMB_julia_joint}(object, variable = NULL,
  rows = c("missing", "all"), se = TRUE, include_observed, ...)
\method{summary}{drmTMB_julia_joint}(object, conf.int = FALSE,
  level = 0.95, method = c("wald", "profile"), ...)
\method{confint}{drmTMB_julia_joint}(object, parm = NULL,
  level = 0.95, method = c("wald", "profile", "bootstrap"), ...)
}
\arguments{
\item{object}{A fit returned by the joint Julia route.}
\item{dpar}{Coefficient block to extract, or \code{"mu"}/\code{"sigma"} for prediction.}
\item{newdata}{Complete new predictor rows. Omit to obtain stored conditional predictions.}
\item{type}{Prediction on the response or link scale.}
\item{variable}{Name of the modelled missing predictor.}
\item{rows}{Return missing-predictor rows only, or every retained model row.}
\item{se}{Include available conditional imputation standard errors.}
\item{include_observed}{Optional compatibility selector for all or missing rows.}
\item{conf.int}{Append Wald intervals to the summary table.}
\item{level}{Confidence level strictly between zero and one.}
\item{method}{Currently \code{"wald"} only. Profile and bootstrap requests fail explicitly.}
\item{parm}{Optional compact \code{dpar:term} or \code{fixef:dpar:term} target names.}
\item{...}{Reserved.}
}
\details{
Binary predictor labels follow the fitted encoding, regardless of the levels
present in the new batch. Numeric new values match raw numeric fitted labels;
for nonnumeric fitted labels, numeric 0/1 values specify the encoded states.
If distinct labels become identical as numbers (for example, "01" and "1"),
supply character or factor values to preserve their identity.

The \code{sigma_mi_<variable>} coefficient is the Gaussian predictor standard
deviation on its natural scale. Its covariance includes the full delta-method
transformation, including cross-covariances. Its symmetric delta-Wald interval
can extend below zero; it is not an exponentiated log-scale interval or a
verified counterpart of native predictor-SD interval output.

\code{imputed()} returns conditional summaries, not multiple-imputation draws.
Gaussian imputation uncertainty includes conditional variance and parameter
uncertainty; Bernoulli uncertainty is the conditional Bernoulli standard
deviation. Observed predictors have no imputation standard error.

With \code{response = "include"}, retained missing responses have unavailable
residuals. \code{nobs()} counts observed responses, while predictions and
\code{imputed(rows = "all")} retain every model row. The Julia adapter applies
\code{response = "drop"} before joint preparation; the current native route
can instead reject that combination. This preprocessing difference is explicit.

The initial route requires default fitting controls, ML, and complete exogenous
fixed-effect designs. Weights, REML, offsets, random effects and structured
predictor models are not admitted by this route.
}
\value{
Coefficient blocks, a covariance matrix, an observation count, prediction
vectors, an eight-column imputation table, or a summary/interval table,
according to the generic used.
}
\seealso{\code{\link{drmTMB}}, \code{\link{mi}}, \code{\link{impute_model}}, \code{\link{imputed}}}
