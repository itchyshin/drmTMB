# Unit-level SD schemas for the shared CJS route. Fitting is wired separately.
# A unit covariate is declared by one or more equal nonmissing values. This
# never fills missing observation-level mean predictors. Entirely missing
# unit covariates are rejected, matching the native Julia unit contract.
.cmr_shared_sd_design <- function(formula, frame, random, process, contrasts = NULL) {
  if (is.null(random)) {
    if (!is.null(formula)) stop("sd_",process," has no shared effect.",call.=FALSE)
    return(NULL)
  }
  if (!process %in% c("phi","p")) stop("Unknown shared SD process.",call.=FALSE)
  if (!is.null(formula) && (!inherits(formula,"formula") || length(formula)!=2L))
    stop("Shared SD formula must be one-sided.",call.=FALSE)
  if (!random$group %in% names(frame)) stop("Shared grouping column is absent.",call.=FALSE)
  supplied_formula <- formula
  levels <- as.character(random$levels)
  if (!length(levels) || anyNA(levels) || anyDuplicated(levels))
    stop("Shared SD units must be distinct nonmissing levels.",call.=FALSE)
  rows <- lapply(levels,function(level) which(as.character(frame[[random$group]])==level))
  if (any(lengths(rows)==0L)) stop("An active shared SD unit has no process rows.",call.=FALSE)
  unit <- data.frame(.cmr_unit=levels)
  if (is.null(formula)) formula <- ~1
  for (name in all.vars(formula)) {
    if (!name %in% names(frame)) stop("SD predictor or offset is absent: ",name,call.=FALSE)
    source <- frame[[name]]
    values <- lapply(rows,function(indices) {
      x <- source[indices];x <- x[!is.na(x)]
      if (!length(x)) stop("Shared SD predictor has no nonmissing value: ",name,call.=FALSE)
      if (length(unique(x))!=1L) stop("Shared SD predictors and offsets must be constant within unit: ",name,call.=FALSE)
      x[1L]
    })
    unit[[name]] <- if (is.factor(source)) factor(vapply(values,as.character,""),levels=levels(source)) else do.call(c,values)
  }
  design <- .cmr_design(formula,unit,paste0("sd_",process),rep(TRUE,nrow(unit)),contrasts=contrasts)
  if (!ncol(design$X)) stop("Shared SD design must have at least one free column.",call.=FALSE)
  if (qr(design$X)$rank!=ncol(design$X)) stop("Shared SD design is rank deficient.",call.=FALSE)
  c(design,list(levels=levels,group=random$group,unit_data=unit,formula=supplied_formula))
}

.cmr_shared_sd_start <- function(design) {
  start <- rep(0,ncol(design$X))
  intercept <- match("(Intercept)",design$columns)
  if (!is.na(intercept)) start[intercept] <- log(.3)
  start
}

.cmr_shared_sd_prune <- function(random) {
  if (is.null(random)) return(NULL)
  keep <- colSums(abs(random$Z)) > 0
  if (!any(keep)) stop("Shared SD effect has no active units.",call.=FALSE)
  random$excluded_sd_levels <- random$levels[!keep]
  random$Z <- random$Z[,keep,drop=FALSE]
  random$levels <- random$levels[keep]
  random$n_levels <- sum(keep)
  random$histories_per_level <- random$histories_per_level[keep]
  random$active <- random$active & rowSums(abs(random$Z))[random$row_index] > 0
  random
}
