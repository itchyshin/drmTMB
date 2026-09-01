# Finite-state missing predictors use the common Julia likelihood. Native R
# owns parsing, ordered-factor contrasts and the response-row policy.
drm_julia_finite_joint_payload <- function(spec, mi_setup, response_drop) {
  model <- spec$missing_predictor
  if (!model$family %in% c("ordinal","categorical") ||
      isTRUE(model$random$enabled) || isTRUE(model$structured$enabled)) {
    cli::cli_abort("Finite-state Julia predictors require fixed-effect ordinal or categorical imputation models.")
  }
  if (!identical(model$variable,mi_setup$variable)) cli::cli_abort("Finite-state Julia predictor name mismatch.")
  levels <- as.character(model$levels);K <- length(levels)
  if (K<3L || anyNA(levels) || any(!nzchar(levels)) || anyDuplicated(levels)) {
    cli::cli_abort("Finite-state Julia predictors need at least three distinct declared levels.")
  }
  original_row <- as.integer(response_drop$original_row[spec$missing_data$original_row])
  spec$missing_data$original_row <- original_row
  for(name in names(spec$missing_data$predictors)) {
    spec$missing_data$predictors[[name]]$original_row <- as.integer(
      response_drop$original_row[spec$missing_data$predictors[[name]]$original_row])
  }
  y <- as.numeric(spec$y);x <- as.numeric(model$x);n <- length(y)
  oy <- as.logical(spec$missing_data$observed_y);ox <- as.logical(model$observed)
  Xmu <- drm_julia_joint_numeric_matrix(spec$X$mu,"mu design")
  Xstate <- drm_julia_joint_numeric_matrix(model$X_mu_state,"state-expanded mu design")
  Xsigma <- drm_julia_joint_numeric_matrix(spec$X$sigma,"sigma design")
  Xp <- drm_julia_joint_numeric_matrix(model$X,"predictor design")
  if (length(x)!=n || length(original_row)!=n || length(oy)!=n || length(ox)!=n ||
      nrow(Xmu)!=n || nrow(Xsigma)!=n || nrow(Xp)!=n || !identical(dim(Xstate),c(n*K,ncol(Xmu)))) {
    cli::cli_abort("Finite-state Julia payload dimensions do not match prepared rows.")
  }
  if (anyNA(oy) || anyNA(ox) || any(!is.finite(y[oy])) ||
      any(!is.finite(x[ox])) || any(x[ox]!=as.integer(x[ox])) || any(!x[ox] %in% seq_len(K))) {
    cli::cli_abort("Finite-state Julia observed values or masks are invalid.")
  }
  ids <- which(ox)
  if(length(ids) && max(abs(Xstate[(ids-1L)*K+as.integer(x[ids]),,drop=FALSE]-Xmu[ids,,drop=FALSE]))>1e-12) {
    cli::cli_abort("Finite-state Julia observed design and state order disagree.")
  }
  payload <- list(schema="joint_missing_finite_v1",predictor=model$family,variable=model$variable,
    levels=levels,y=y,x=x,observed_y=oy,observed_x=ox,X_mu=Xmu,X_mu_state=Xstate,
    state_layout="row_then_state",X_sigma=Xsigma,X_predictor=Xp,
    mu_names=unname(colnames(spec$X$mu)),sigma_names=unname(colnames(spec$X$sigma)),
    predictor_names=unname(as.character(colnames(model$X))),original_row=original_row,options=list(g_tol=1e-8))
  list(payload=payload,spec=spec)
}

# Cutpoint coordinates stay in raw transport, while public coef/vcov contain
# only regression coefficients, matching native ordinal-predictor fits.
drm_julia_finite_joint_contract <- function(result, prepared) {
  p <- prepared$payload;result <- as.list(result);K <- length(p$levels)
  if(!identical(result$schema,"joint_missing_finite_result_v1") || !p$predictor %in% c("ordinal","categorical")) {
    cli::cli_abort("Unknown finite-state Julia result schema or family.")
  }
  blocks <- c(rep("mu",length(p$mu_names)),rep("sigma",length(p$sigma_names)))
  terms <- c(p$mu_names,p$sigma_names)
  if(p$predictor=="ordinal") {
    blocks <- c(blocks,rep(paste0("rawcut_",p$variable),K-1L))
    terms <- c(terms,"cut1",paste0("log_spacing",seq.int(2L,K-1L)))
    pn <- p$predictor_names
  } else pn <- unlist(lapply(p$levels[-1L],function(level) paste0(level,":",p$predictor_names)),use.names=FALSE)
  blocks <- c(blocks,rep(paste0("mi_",p$variable),length(pn)));terms <- c(terms,pn)
  raw_names <- paste0(blocks,"_",terms)
  if(!identical(as.character(result$coefficient_blocks),blocks) ||
     !identical(as.character(result$coefficient_terms),terms) ||
     !identical(as.character(result$coef_names),raw_names) || anyDuplicated(raw_names)) {
    cli::cli_abort("Finite-state Julia coefficient ordering does not match the prepared contract.")
  }
  theta <- drm_julia_joint_result_vector(result$coefficients,"coefficients")
  if(length(theta)!=length(blocks)) cli::cli_abort("Finite-state Julia raw theta length mismatch.")
  V <- drm_julia_vcov(drm_julia_joint_validate_raw_vcov(result,raw_names),raw_names)
  rows <- drm_julia_joint_validate_result_rows(result,p)
  imputation <- drm_julia_joint_validate_imputation(result,p,rows)
  if(identical(as.character(result$covariance_status),"observed_information_inverse")) {
    expected_status <- ifelse(!rows$observed_x & p$predictor=="categorical",
      "route_conditional_se_unavailable","ok")
    if(!identical(as.character(imputation$uncertainty_status),expected_status)) {
      cli::cli_abort("Finite-state Julia uncertainty statuses do not match the predictor family and observed rows.")
    }
    if(p$predictor=="categorical" && (any(imputation$se_available) || any(is.finite(imputation$std_error)))) {
      cli::cli_abort("Categorical imputation has no metric standard error.")
    }
  }
  probabilities <- result$conditional_probabilities;n <- length(rows$original_row)
  if(!identical(as.character(result$predictor_levels),p$levels) || !is.matrix(probabilities) ||
     !identical(dim(probabilities),c(n,K)) || any(!is.finite(probabilities)) ||
     any(probabilities < 0 | probabilities > 1) || any(abs(rowSums(probabilities)-1)>1e-10)) {
    cli::cli_abort("Finite-state Julia posterior probabilities or level order are invalid.")
  }
  ids <- which(rows$observed_x)
  if(length(ids)) {
    expected <- matrix(0,length(ids),K);expected[cbind(seq_along(ids),as.integer(p$x[ids]))] <- 1
    if(max(abs(probabilities[ids,,drop=FALSE]-expected))>1e-12) cli::cli_abort("Observed finite-state posteriors must retain their observed category.")
  }
  point <- if(p$predictor=="ordinal") as.numeric(probabilities %*% seq_len(K)) else max.col(probabilities,ties.method="first")
  if(max(abs(point-as.numeric(imputation$estimate)))>1e-10) cli::cli_abort("Finite-state Julia imputation does not match posterior probabilities.")
  if(p$predictor=="ordinal") {
    raw <- theta[startsWith(blocks,"rawcut_")];cuts <- cumsum(c(raw[1L],exp(raw[-1L])))
    ordinal <- result$ordinal
    if(!is.list(ordinal) || !identical(as.character(ordinal$labels),paste0(p$levels[-K],"|",p$levels[-1L])) ||
       length(ordinal$cutpoints)!=K-1L || length(ordinal$theta_raw)!=K-1L ||
       any(!is.finite(ordinal$cutpoints)) || max(abs(as.numeric(ordinal$cutpoints)-cuts))>1e-10 ||
       max(abs(as.numeric(ordinal$theta_raw)-raw))>1e-10) cli::cli_abort("Finite-state Julia cutpoint metadata disagrees with raw coordinates.")
    sd <- sqrt(rowSums(probabilities*(matrix(seq_len(K),n,K,byrow=TRUE)-point)^2))
    valid <- !rows$observed_x & as.character(imputation$uncertainty_status)=="ok"
    if(any(abs(as.numeric(imputation$std_error)[valid]-sd[valid])>1e-10)) cli::cli_abort("Ordinal imputation SD must be the conditional score SD.")
  } else if(!is.null(result$ordinal)) cli::cli_abort("Categorical predictor must not contain ordinal cutpoint metadata.")
  list(result=result,payload=p,variable=p$variable,predictor=p$predictor,
       raw_names=raw_names,raw_theta=stats::setNames(theta,raw_names),raw_vcov=V,
       blocks=blocks,terms=terms,rows=rows,imputation=imputation)
}

drm_julia_finite_factor_data <- function(data, variable, levels, ordered, allow_missing=FALSE) {
  if(!variable %in% names(data)) cli::cli_abort("Finite-state prediction requires predictor {.val {variable}}.")
  x <- as.character(data[[variable]])
  if(any(!is.na(x) & !x %in% levels) || (!allow_missing && anyNA(x))) {
    cli::cli_abort("Finite-state prediction requires observed predictor values from the fitted levels.")
  }
  if(allow_missing) x[is.na(x)] <- levels[1L]
  data[[variable]] <- factor(x,levels=levels,ordered=ordered)
  data
}
