#' Stable native reader contracts
#'
#' These contracts define the minimum public output used by drmTMB's native
#' reader journeys. They do not stabilize every component retained on fitted or
#' summary objects for backward compatibility.
#'
#' `check_drm()` returns a `drm_check` data frame with the character columns
#' `check`, `status`, `value`, and `message`, in that order. Status values are
#' `"ok"`, `"note"`, `"warning"`, or `"error"`. Its `"ok"` attribute is `TRUE`
#' exactly when no row has status `"warning"` or `"error"`.
#'
#' `summary()` guarantees the reader tables `coefficients`, `parameters`,
#' `covariance`, and `derived`, plus the `confint` key. `confint` is `NULL` when
#' intervals were not requested and a table otherwise. Relayed `sdpars`,
#' `corpars`, `ordinal`, `uncertainty`, and `mspl` components remain available
#' for compatibility but are outside this stable reader contract.
#'
#' For `ranef()`, `terms` is the stable model-scale conditional-deviation
#' interface on ordinary distributional and named structured-effect blocks.
#' It is not a random-effect standard-deviation extractor. `values`, `latent`,
#' `covariance_blocks`, and specialised mesh fields are advanced compatibility
#' components; covariance-block entries do not promise `terms`. A fit with no
#' random effects returns an empty list when `dpar = NULL`; requesting a named
#' block produces an error explaining that the fit contains no random effects.
#'
#' `fitted()` is the response-summary interface, while [predict_parameters()]
#' is the distributional-component surface. For example, for a lognormal fit,
#' `fitted()` returns the arithmetic response mean `exp(mu + sigma^2 / 2)`, not
#' the log-scale `mu` returned by `predict_parameters(..., dpar = "mu")`.
#'
#' In interval tables, `conf.status` reports the result or availability state,
#' `interval_source` records provenance, and `profile.boundary` is only a flag
#' that the relevant profile reached a boundary.
#'
#' @name native_reader_contracts
#' @seealso [check_drm()], [summary.drmTMB()], [ranef.drmTMB()],
#'   [fitted.drmTMB()], and [predict_parameters()]
NULL
