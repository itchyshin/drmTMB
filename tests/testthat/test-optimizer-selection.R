# Use source files for engine-free development, or installed functions under
# R CMD check, where the package's R source directory is not present.
optimizer_selection <- local({
  sources <- testthat::test_path("..", "..", "R", c("control.R", "drmTMB.R"))
  if (all(file.exists(sources))) {
    env <- new.env(parent = globalenv())
    for (path in sources) sys.source(path, env)
  } else {
    ns <- asNamespace("drmTMB")
    env <- new.env(parent = ns)
    # Rebind internal helpers so dispatch instrumentation stays private to this
    # fixture and never modifies the installed namespace.
    for (name in ls(ns, pattern = "^drm_")) {
      value <- get(name, ns, inherits = FALSE)
      if (is.function(value) && identical(environment(value), ns)) {
        environment(value) <- env
      }
      assign(name, value, env)
    }
  }
  env
})

selection_quadratic <- function() {
  list(
    par = c(alpha = 4, beta = -3),
    fn = function(par) sum((par - c(1, 2))^2),
    gr = function(par) 2 * (par - c(1, 2))
  )
}

selection_no_nlminb <- function(...) stop("nlminb must not run")

test_that("optimizer selection preserves the nlminb default and positional API", {
  ctl <- optimizer_selection$drm_control()
  expect_identical(ctl$optimizer_method, "nlminb")
  expect_identical(ctl$optimizer, list())
  expect_identical(tail(names(formals(optimizer_selection$drm_control)), 1L),
                   "optimizer_method")
  expect_identical(optimizer_selection$drm_control(optimizer_preset = "careful")$optimizer,
                   list(iter.max = 1000L, eval.max = 1000L))
})

test_that("direct methods validate their own controls without nlminb presets", {
  make <- optimizer_selection$drm_control
  methods <- c("BFGS", "L-BFGS-B", "Nelder-Mead", "CG")
  for (method in methods) {
    ctl <- make(optimizer_method = method)
    expect_identical(ctl$optimizer_method, method)
    expect_identical(ctl$optimizer, list(maxit = 1000L))
    expect_identical(make(optimizer_method = method, optimizer = list(maxit = 23L))$optimizer,
                     list(maxit = 23L))
    expect_error(make(optimizer_method = method, optimizer_preset = "careful"), "optimizer_preset")
    expect_error(make(optimizer_method = method, fallback_optimizer = "BFGS"), "fallback_optimizer")
    for (key in c("iter.max", "eval.max", "rel.tol", "x.tol", "lower", "upper", "typo")) {
      expect_error(make(optimizer_method = method,
                        optimizer = stats::setNames(list(1), key)), key, fixed = TRUE)
    }
    for (scale in list(0, -1, NA_real_, Inf, c(1, 2), "1")) {
      expect_error(make(optimizer_method = method, optimizer = list(fnscale = scale)), "fnscale")
    }
  }
  for (method in list("B", "bfgs", "SANN", "Brent", c("BFGS", "CG"), NA_character_, 1)) {
    expect_error(make(optimizer_method = method), "optimizer_method")
  }
  expect_error(make(optimizer_method = "L-BFGS-B", optimizer = list(reltol = 1e-8)), "reltol")
  expect_error(make(optimizer_method = "L-BFGS-B", optimizer = list(abstol = 1e-8)), "abstol")
  expect_error(make(optimizer_method = "BFGS", optimizer = list(factr = 1e7)), "factr")
  expect_error(make(optimizer_method = "CG", optimizer = list(lmm = 5L)), "lmm")
  expect_error(make(optimizer_method = "BFGS", optimizer = list(alpha = 1)), "alpha")
  expect_error(make(optimizer_method = "Nelder-Mead", optimizer = list(type = 1L)), "type")
  expect_equal(make(optimizer_method = "L-BFGS-B", optimizer = list(factr = 100, pgtol = 1e-7))$optimizer$factr, 100)
  expect_equal(make(optimizer_method = "CG", optimizer = list(type = 2L))$optimizer$type, 2L)
})

test_that("all direct methods optimize a named quadratic without calling nlminb", {
  for (method in c("BFGS", "L-BFGS-B", "Nelder-Mead", "CG")) {
    ctl <- optimizer_selection$drm_control(optimizer_method = method, newton_polish = FALSE)
    result <- optimizer_selection$drm_optimize_with_preset_retry(
      selection_quadratic(), ctl, optimizer = selection_no_nlminb
    )
    expect_equal(unname(result$opt$par), c(1, 2), tolerance = 1e-3)
    expect_named(result$opt$par, c("alpha", "beta"))
    expect_lt(result$opt$objective, 1e-6)
    expect_identical(result$opt$convergence, 0L)
    expect_true(is.null(result$opt$iterations))
    expect_named(result$opt$evaluations, c("function", "gradient"))
    expect_identical(result$selected$optimizer, method)
    expect_identical(result$attempts$optimizer, method)
    expect_identical(result$selected$control, ctl$optimizer)
    expect_identical(result$attempts$selected, TRUE)
  }
})

test_that("direct dispatch passes method and controls and omits the simplex gradient", {
  for (method in c("BFGS", "L-BFGS-B", "Nelder-Mead", "CG")) {
    obj <- selection_quadratic()
    ctl <- optimizer_selection$drm_control(optimizer_method = method, newton_polish = FALSE,
                                         optimizer = list(maxit = 3L))
    calls <- list()
    fake_optim <- function(par, fn, gr, method, control) {
      calls[[length(calls) + 1L]] <<- list(par = par, gr = gr, method = method, control = control)
      list(par = par, value = fn(par), convergence = 1L,
           message = "iteration budget exhausted", counts = c(functions = 4L))
    }
    result <- optimizer_selection$drm_optimize_with_preset_retry(
      obj, ctl, optimizer = selection_no_nlminb, fallback_fn = fake_optim
    )
    expect_length(calls, 1L)
    expect_identical(calls[[1L]]$method, method)
    expect_identical(calls[[1L]]$control, list(maxit = 3L))
    if (method == "Nelder-Mead") expect_null(calls[[1L]]$gr)
    else expect_identical(calls[[1L]]$gr, obj$gr)
    expect_identical(result$selected$convergence, 1L)
    expect_identical(result$attempts$convergence, 1L)
    expect_identical(result$selected$message, "iteration budget exhausted")
    expect_identical(result$opt$evaluations, c(functions = 4L))
    expect_identical(result$attempts$selected, TRUE)
  }
})

test_that("direct methods reuse multistart selection and propagate optimizer errors", {
  obj <- selection_quadratic()
  calls <- 0L
  fake_optim <- function(par, fn, gr, method, control) {
    calls <<- calls + 1L
    list(par = par, value = c(9, 2, 6)[[calls]], convergence = 0L,
         counts = c(functions = 1L))
  }
  ctl <- optimizer_selection$drm_control(optimizer_method = "BFGS", multi_start = 3L)
  result <- optimizer_selection$drm_optimize_with_preset_retry(
    obj, ctl, optimizer = selection_no_nlminb, fallback_fn = fake_optim
  )
  expect_identical(calls, 3L)
  expect_identical(result$opt$objective, 2)
  expect_identical(result$selected$objective, 2)
  expect_identical(result$attempts$objective, 2)
  expect_equal(result$opt$par, optimizer_selection$drm_perturbed_starts(obj$par, 3L)[[2L]])
  expect_error(optimizer_selection$drm_optimize_with_preset_retry(
    obj, ctl, optimizer = selection_no_nlminb,
    fallback_fn = function(...) stop("requested optimizer failed")
  ), "requested optimizer failed")
})

test_that("fallback metadata names the actual optim method", {
  fake_nlminb <- function(start, objective, gradient, control) {
    list(par = start, objective = objective(start), convergence = 1L, message = "failed")
  }
  result <- optimizer_selection$drm_optimize_with_preset_retry(
    selection_quadratic(), optimizer_selection$drm_control(fallback_optimizer = "BFGS"),
    optimizer = fake_nlminb, warn = FALSE
  )
  expect_identical(result$selected$optimizer, "BFGS")
  expect_identical(tail(result$attempts$optimizer, 1L), "BFGS")
  expect_named(result$opt$evaluations, c("function", "gradient"))
})


test_that("nlminb default retry budgets and raw result fields stay unchanged", {
  calls <- list()
  fake_nlminb <- function(start, objective, gradient, control) {
    calls[[length(calls) + 1L]] <<- control
    list(par = start, objective = objective(start),
         convergence = if (length(calls) == 1L) 1L else 0L,
         message = "raw nlminb message", iterations = 7L,
         evaluations = c("function" = 8L, "gradient" = 5L))
  }
  result <- optimizer_selection$drm_optimize_with_preset_retry(
    selection_quadratic(), optimizer_selection$drm_control(),
    optimizer = fake_nlminb, fallback_fn = function(...) stop("optim must not run"),
    warn = FALSE
  )
  expect_identical(calls, list(list(), list(iter.max = 1000L, eval.max = 1000L)))
  expect_identical(result$opt$iterations, 7L)
  expect_identical(result$opt$message, "raw nlminb message")
  expect_identical(result$selected$optimizer, "nlminb")
  expect_identical(result$selected$optimizer_preset, "careful")
  expect_identical(result$attempts$selected, c(FALSE, TRUE))
})

test_that("direct results preserve nonfinite objective and failure codes truthfully", {
  fake_optim <- function(par, fn, gr, method, control) {
    list(par = par, value = Inf, convergence = 52L,
         message = "abnormal termination", counts = c("function" = 1L, "gradient" = 1L))
  }
  result <- optimizer_selection$drm_optimize_with_preset_retry(
    selection_quadratic(), optimizer_selection$drm_control(optimizer_method = "L-BFGS-B"),
    optimizer = selection_no_nlminb, fallback_fn = fake_optim
  )
  expect_identical(result$opt$objective, Inf)
  expect_identical(result$selected$objective, Inf)
  expect_identical(result$attempts$objective, Inf)
  expect_identical(result$attempts$convergence, 52L)
  expect_identical(result$attempts$message, "abnormal termination")
  expect_identical(result$attempts$optimizer_preset, NA_character_)
  expect_false(result$selected$retried)
})

test_that("direct multistart honors the requested parallel plan", {
  env <- new.env(parent = optimizer_selection)
  # Bind the fit helpers to this isolated environment so instrumentation cannot
  # modify another test or the package namespace.
  for (name in c("drm_optimize_with_preset_retry", "drm_optimize_multistart",
                 "drm_multistart_plan", "drm_control", "drm_optim_adapter")) {
    fn <- optimizer_selection[[name]]
    environment(fn) <- env
    env[[name]] <- fn
  }
  plan_calls <- list()
  env$resolve_parallel_workers <- function(workers, parallel) as.integer(workers)
  env$bootstrap_parallel_plan <- function(n_boot, parallel, workers) {
    plan_calls[[length(plan_calls) + 1L]] <<- list(n_start = n_boot,
                                                parallel = parallel, workers = workers)
    list(backend = parallel, workers = workers)
  }
  worker_plans <- list()
  env$drm_parallel_lapply <- function(X, FUN, plan) {
    worker_plans[[length(worker_plans) + 1L]] <<- plan
    lapply(X, FUN)
  }
  for (backend in c("multicore", "cluster")) {
    ctl <- env$drm_control(optimizer_method = "BFGS", multi_start = 3L,
                           parallel = backend, workers = 2L)
    result <- env$drm_optimize_with_preset_retry(
      selection_quadratic(), ctl, optimizer = selection_no_nlminb
    )
    expect_equal(unname(result$opt$par), c(1, 2), tolerance = 1e-6)
  }
  expect_identical(plan_calls, list(
    list(n_start = 3L, parallel = "multicore", workers = 2L),
    list(n_start = 3L, parallel = "cluster", workers = 2L)
  ))
  expect_identical(worker_plans, list(
    list(backend = "multicore", workers = 2L),
    list(backend = "cluster", workers = 2L)
  ))
})


test_that("direct controls reject ambiguous names before forwarding to optim", {
  make <- optimizer_selection$drm_control
  expect_error(make(optimizer_method = "BFGS",
                    optimizer = list(fnscale = 1, fnscale = -1)), "unique")
  expect_error(make(optimizer_method = "BFGS",
                    optimizer = stats::setNames(list(1), NA_character_)), "named list")
})


test_that("staged-fit metrics report direct method budgets without invented iterations", {
  for (method in c("BFGS", "L-BFGS-B", "Nelder-Mead", "CG")) {
    fit <- list(
      opt = list(par = c(beta = 0), objective = 0, convergence = 1L,
                 evaluations = c("function" = 12L, "gradient" = 5L)),
      obj = list(gr = function(par) c(beta = 0)),
      sdr = list(pdHess = TRUE), df = 1, nobs = 10,
      optimizer_used = list(optimizer = method, optimizer_preset = NA_character_,
                            control = list(maxit = 7L)),
      control = list(optimizer_method = method, optimizer = list(maxit = 1000L), se = TRUE),
      optimizer_attempts = data.frame(optimizer = method, optimizer_preset = NA_character_,
                                     selected = TRUE, status = "ok")
    )
    metrics <- optimizer_selection$drm_qgt2_staged_fit_metrics(
      fit, "test", TRUE, 0.1, character(), NA_character_
    )
    expect_identical(metrics$optimizer_method, method)
    expect_identical(metrics$maxit, 7)
    expect_identical(metrics$optimizer_selected_attempt, method)
    expect_identical(metrics$iterations, NA_real_)
    expect_identical(metrics$iter_max, NA_real_)
    expect_identical(metrics$eval_max, NA_real_)
    expect_identical(metrics$budget_status, "iteration_budget_reached")
  }
  expect_identical(optimizer_selection$drm_qgt2_budget_status(
    1L, 10, 15, 10, 20
  ), "iteration_budget_reached")
  expect_identical(optimizer_selection$drm_qgt2_budget_status(
    1L, 1, 20, 10, 20
  ), "evaluation_budget_reached")
  expect_identical(optimizer_selection$drm_qgt2_budget_status(
    52L, NA_real_, 12, NA_real_, NA_real_, optimizer_method = "L-BFGS-B", maxit = 7
  ), "nonconverged_before_budget_or_unknown")
})

test_that("staged attempt summaries use the selected row instead of the last preset", {
  fit <- list(
    optimizer_attempts = data.frame(
      attempt = 1:3, optimizer = c("nlminb", "nlminb", "BFGS"),
      optimizer_preset = c("default", "careful", "fallback:BFGS"),
      selected = c(TRUE, FALSE, FALSE), status = c("ok", "ok", "ok")
    )
  )
  expect_identical(optimizer_selection$drm_qgt2_optimizer_attempts(fit)$selected, "default")
  fit$optimizer_attempts$selected <- NULL
  fit$optimizer_used <- list(attempt = 2L, optimizer = "nlminb", optimizer_preset = "careful")
  expect_identical(optimizer_selection$drm_qgt2_optimizer_attempts(fit)$selected, "careful")
  fit$optimizer_attempts <- NULL
  fit$optimizer_used <- list(optimizer = "CG", optimizer_preset = NA_character_)
  expect_identical(optimizer_selection$drm_qgt2_optimizer_attempts(fit)$selected, "CG")
})

test_that("fit warnings give optimizer-neutral recovery advice", {
  warn_text <- function(fn, opt) {
    captured <- character()
    withCallingHandlers(fn(opt), warning = function(w) {
      captured <<- c(captured, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
    paste(captured, collapse = " ")
  }
  failed <- warn_text(optimizer_selection$drm_warn_if_not_converged,
                      list(convergence = 1L, message = "iteration limit"))
  nonfinite <- warn_text(optimizer_selection$drm_warn_if_nonfinite_objective,
                         list(objective = Inf))
  expect_match(failed, "fit\\$optimizer_attempts")
  expect_false(grepl("escalates its preset ladder automatically", failed, fixed = TRUE))
  expect_false(grepl("optimizer_preset", nonfinite, fixed = TRUE))
})


test_that("staged attempt summaries keep legacy nlminb metadata unambiguous", {
  legacy <- list(
    optimizer_used = list(optimizer_preset = "careful"),
    optimizer_attempts = data.frame(optimizer_preset = "careful", selected = TRUE)
  )
  attempts <- optimizer_selection$drm_qgt2_optimizer_attempts(legacy)
  expect_identical(attempts$selected, "careful")
  expect_true(is.na(attempts$optimizer))
})
