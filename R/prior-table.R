# Parse literal prior rows before model-aware target resolution.
drm_parse_prior_table <- function(x) {
  if (!is.data.frame(x) || anyDuplicated(names(x))) cli::cli_abort('prior table must have unique columns')
  required <- c('prior', 'class', 'coef')
  if (!all(required %in% names(x)) || any(!names(x) %in% c(required, 'dpar', 'group'))) cli::cli_abort('invalid prior table columns')
  if (!nrow(x) || any(!vapply(x, is.character, logical(1))) || anyNA(x)) cli::cli_abort('prior table requires nonmissing character rows')
  number <- '[+-]?(?:(?:[0-9]+(?:\\.[0-9]*)?)|(?:\\.[0-9]+))(?:[eE][+-]?[0-9]+)?'
  ws <- '[ \\t\\r\\n\\f\\v]*'
  pat <- paste0('^',ws,'(normal|ridge|gamma)',ws,'\\(',ws,'(',number,')',ws,'(?:,',ws,'(',number,')',ws,')?\\)',ws,'$')
  lapply(seq_len(nrow(x)), function(i) {
    cls <- x$class[i]; coef <- x$coef[i]
    dpar <- if ('dpar' %in% names(x)) x$dpar[i] else ''
    group <- if ('group' %in% names(x)) x$group[i] else ''
    if (!nzchar(dpar)) dpar <- 'mu'
    if (!cls %in% c('fixef','ranef_sd')) cli::cli_abort('unsupported prior class')
    m <- regmatches(x$prior[i], regexec(pat, x$prior[i], perl=TRUE))[[1L]]
    if (!length(m)) cli::cli_abort('invalid prior syntax')
    kind <- m[2L]; args <- m[3:4]; args <- args[nzchar(args)]
    if (length(args) != if (kind == 'ridge') 1L else 2L) cli::cli_abort('wrong prior arity')
    values <- suppressWarnings(as.numeric(args))
    nonzero_literal <- grepl('[1-9]', sub('[eE].*$', '', args))
    if (any(!is.finite(values)) || any(values == 0 & nonzero_literal)) cli::cli_abort('unrepresentable prior parameter')
    if (kind == 'normal') {
      precision <- 1/(values[2]^2)
      if (cls != 'fixef' || values[2] <= 0 || !is.finite(precision) || precision <= 0) cli::cli_abort('invalid normal prior')
    } else if (kind == 'ridge') {
      if (cls != 'fixef' || values[1] < 0) cli::cli_abort('invalid ridge prior')
    } else {
      rate <- values[2]/values[1]
      if (cls != 'ranef_sd' || values[1] <= 0 || values[2] <= 1 || !is.finite(rate) || rate <= 0) cli::cli_abort('invalid Gamma prior')
    }
    if (cls == 'fixef' && (nzchar(group) || coef == 'all')) cli::cli_abort('invalid fixed selector')
    list(kind=kind, class=cls, coef=coef, dpar=dpar, group=group, args=values)
  })
}

# The caller must validate the entire model before supplying eligible groups.
drm_expand_prior_table <- function(rows, groups) {
  if (anyDuplicated(groups)) cli::cli_abort('ambiguous random-intercept groups')
  out <- list(); seen <- character()
  for (row in rows) {
    if (row$class == 'fixef') { out[[length(out)+1L]] <- row; next }
    if (row$dpar != 'mu') cli::cli_abort('SD priors require dpar=mu')
    selected <- if (!nzchar(row$group)) {
      if (!nzchar(row$coef)) groups else {
        if (row$coef == '(Intercept)') cli::cli_abort('use group for (Intercept) grouping variable')
        row$coef
      }
    } else {
      if (!row$coef %in% c('', '(Intercept)', row$group)) cli::cli_abort('conflicting group and coefficient selectors')
      row$group
    }
    if (!length(selected)) cli::cli_abort('SD prior matched no random intercept')
    for (group in selected) {
      if (!group %in% groups) cli::cli_abort('unknown random-intercept group')
      if (group %in% seen) cli::cli_abort('overlapping SD prior target')
      seen <- c(seen,group); expanded <- row; expanded$group <- group; expanded$coef <- '(Intercept)'
      out[[length(out)+1L]] <- expanded
    }
  }
  out
}

drm_prior_table_specs <- function(rows, groups) {
  expanded <- drm_expand_prior_table(rows, groups)
  entries <- lapply(expanded, function(row) {
    if (row$class == 'ranef_sd') return(drm_prior_sd_gamma(dpar=row$dpar,group=row$group,shape=row$args[2],rate=row$args[2]/row$args[1]))
    coefficient <- if (nzchar(row$coef)) row$coef else 'all'
    intercept <- if (nzchar(row$coef)) NULL else 'exclude'
    if (row$kind == 'normal') return(drm_prior_normal(dpar=row$dpar,coef=coefficient,mean=row$args[1],sd=row$args[2],intercept=intercept))
    drm_prior_ridge(dpar=row$dpar,coef=coefficient,lambda=row$args[1],intercept=intercept)
  })
  do.call(drm_priors, entries)
}

# Stage 1 validates the entire model with a prior of the same active/SD class.
# Stage 2 expands selectors only against the validated model, then rechecks the
# concrete collection. The package integration must pass actual fit controls.
drm_normalize_prior_table <- function(table, formula, family, data, ...) {
  rows <- drm_parse_prior_table(table)
  sd_intent <- any(vapply(rows, function(x) x$class == 'ranef_sd', logical(1)))
  active <- any(vapply(rows, function(x) x$class == 'ranef_sd' || x$kind == 'normal' || (x$kind == 'ridge' && x$args[1] > 0), logical(1)))
  placeholder <- if (sd_intent) drm_prior_sd_gamma(group='__prior_table_pending__',shape=2,rate=1) else if (active) drm_prior_normal('mu','(Intercept)',sd=1) else drm_prior_ridge('mu','(Intercept)',lambda=0)
  validate <- drm_validate_fixed_prior_request
  validate(drm_priors(placeholder),formula,family,data,...)
  groups <- character()
  if (sd_intent) {
    entries <- formula$entries
    mu <- entries[[which(vapply(entries,function(e) identical(e$dpar,'mu'),logical(1)))]]
    terms <- extract_random_mu_terms(mu$rhs,'mu')$terms
    groups <- vapply(terms, `[[`, character(1), 'group')
  }
  specs <- drm_prior_table_specs(rows,groups)
  validate(specs,formula,family,data,...)
  attr(specs, 'input_table') <- table
  specs
}

# Freeze model-matrix identities for update; keep the source table as metadata.
drm_freeze_table_prior_specs <- function(priors, resolved) {
  fixed <- if ('class' %in% names(resolved)) resolved[resolved$class == 'fixed',,drop=FALSE] else resolved
  if (nrow(fixed) && any(fixed$coefficient == 'all')) cli::cli_abort('A coefficient literally named all cannot be selected by a prior table')
  entries <- list()
  for (p in priors) {
    if (inherits(p, 'drm_sd_prior')) {
      entries[[length(entries)+1L]] <- p
      next
    }
    selected <- fixed$dpar == p$dpar & if (p$coef == 'all') {
      fixed$reason == paste0('all; intercept ', p$intercept)
    } else fixed$coefficient == p$coef
    targets <- fixed$coefficient[selected]
    if (!length(targets)) cli::cli_abort('Prior replay target was not resolved.')
    for (target in targets) {
      entries[[length(entries)+1L]] <- if (p$kind == 'normal') {
        drm_prior_normal(p$dpar,target,mean=p$mean,sd=p$sd)
      } else drm_prior_ridge(p$dpar,target,lambda=p$precision)
    }
  }
  out <- do.call(drm_priors,entries)
  attr(out,'input_table') <- attr(priors,'input_table')
  out
}
