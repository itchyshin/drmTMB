#!/usr/bin/env Rscript

# Reader-first smoke audit for ten article-shaped drmTMB analyses.
#
# This is deliberately a development audit, not a public tutorial and not a
# calibration study.  The fits use only exported drmTMB functions after the
# package is loaded.  A failed post-fit step is retained in the TSV so that a
# successful optimisation cannot disguise a broken reader path.

if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("This development audit needs devtools to load the checkout.", call. = FALSE)
}

devtools::load_all(quiet = TRUE)
set.seed(20260812)

status <- function(expr) {
  warnings <- character()
  value <- tryCatch(
    withCallingHandlers(
      force(expr),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  if (inherits(value, "error")) {
    return(list(ok = FALSE, value = NULL, message = conditionMessage(value), warnings = warnings))
  }
  list(ok = TRUE, value = value, message = "", warnings = warnings)
}

as_flag <- function(x) if (isTRUE(x)) "pass" else "fail"

reader_import <- function(data) {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  utils::write.csv(data, path, row.names = FALSE)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

run_workflow <- function(id, question, model, estimand, uncertainty, limitation, fit) {
  started <- proc.time()[["elapsed"]]
  fitted <- status(fit())
  if (!fitted$ok) {
    return(data.frame(
      workflow = id, question = question, exact_model = model, estimand = estimand,
      uncertainty_route = uncertainty, diagnostic_route = "check_drm()",
      report_artifact = "summary() coefficient table + fitted() response-scale vector",
      evidence_tier = "smoke only; no recovery or calibration claim",
      fit = "fail", diagnostics = "not_run", report_output = "not_run", limitation = limitation,
      seconds = round(proc.time()[["elapsed"]] - started, 2),
      fit_warnings = "", first_blocker = fitted$message, stringsAsFactors = FALSE
    ))
  }

  fit_object <- fitted$value
  diagnostic <- status(drmTMB::check_drm(fit_object))
  # summary() is the report-ready coefficient table; fitted() is a compact
  # response-scale output check that does not depend on plotting devices.
  reporting <- status({
    summary(fit_object)
    stats::fitted(fit_object)
  })

  blocker <- ""
  fit_warnings <- paste(fitted$warnings, collapse = " | ")
  if (nzchar(fit_warnings)) blocker <- paste("fit warning:", fit_warnings)
  if (!diagnostic$ok) blocker <- paste("check_drm():", diagnostic$message)
  if (!reporting$ok) blocker <- paste(c(blocker, "report output:", reporting$message), collapse = " ")
  if (!nzchar(blocker)) blocker <- "none"

  data.frame(
    workflow = id, question = question, exact_model = model, estimand = estimand,
    uncertainty_route = uncertainty, diagnostic_route = "check_drm()",
    report_artifact = "summary() coefficient table + fitted() response-scale vector",
    evidence_tier = "smoke only; no recovery or calibration claim", fit = "pass",
    diagnostics = as_flag(diagnostic$ok), report_output = as_flag(reporting$ok),
    limitation = limitation,
    seconds = round(proc.time()[["elapsed"]] - started, 2),
    fit_warnings = fit_warnings,
    first_blocker = blocker, stringsAsFactors = FALSE
  )
}

n <- 80
x <- seq(-1, 1, length.out = n)

results <- list(
  run_workflow(
    "continuous_location_scale",
    "Does growth and its residual variation differ across habitats?",
    "Gaussian: bf(growth ~ habitat + x, sigma ~ habitat)",
    "mean growth and residual SD contrast",
    "ordinary fixed-effect Wald output (not a structured-SD claim)",
    "sigma is residual SD, not a group-level SD.",
    function() {
      habitat <- factor(rep(c("forest", "grassland"), each = n / 2))
      growth <- 2 + 0.8 * x + 0.5 * (habitat == "grassland") +
        rnorm(n, sd = ifelse(habitat == "grassland", 0.8, 0.4))
      data <- reader_import(data.frame(growth, habitat, x))
      drmTMB::drmTMB(drmTMB::bf(growth ~ habitat + x, sigma ~ habitat),
        family = stats::gaussian(), data = data)
    }
  ),
  run_workflow(
    "count_with_effort",
    "Do restored sites have a higher springtail capture rate after trap effort?",
    "NB2: bf(count ~ habitat + x + offset(log(effort)), sigma ~ habitat)",
    "log count rate and NB2 extra-Poisson variation",
    "ordinary fixed-effect Wald output; no zero-inflation claim",
    "The offset makes this a rate model; sigma is NB2 dispersion, not residual SD.",
    function() {
      habitat <- factor(rep(c("degraded", "restored"), each = n / 2))
      effort <- sample(2:6, n, replace = TRUE)
      mu <- effort * exp(0.4 + 0.5 * (habitat == "restored") + 0.3 * x)
      count <- stats::rnbinom(n, mu = mu, size = 2)
      data <- reader_import(data.frame(count, habitat, x, effort))
      drmTMB::drmTMB(drmTMB::bf(count ~ habitat + x + offset(log(effort)), sigma ~ habitat),
        family = drmTMB::nbinom2(), data = data)
    }
  ),
  run_workflow(
    "denominator_proportion",
    "Does treatment change germination while trays vary beyond binomial sampling?",
    "beta-binomial: bf(cbind(germinated, failed) ~ treatment + x, sigma ~ 1)",
    "germination probability and beta-binomial dispersion",
    "ordinary fixed-effect Wald output",
    "Use counts plus trials; this is not a continuous-proportion model.",
    function() {
      treatment <- factor(rep(c("control", "warm"), each = n / 2))
      trials <- sample(12:20, n, replace = TRUE)
      p <- stats::plogis(-0.2 + 0.8 * (treatment == "warm") + 0.4 * x)
      # Deliberate tray-to-tray variation prevents this beta-binomial smoke
      # fixture from collapsing to the binomial boundary.
      p <- stats::rbeta(n, shape1 = 20 * p, shape2 = 20 * (1 - p))
      germinated <- stats::rbinom(n, trials, p)
      failed <- trials - germinated
      data <- reader_import(data.frame(germinated, failed, treatment, x))
      drmTMB::drmTMB(drmTMB::bf(cbind(germinated, failed) ~ treatment + x, sigma ~ 1),
        family = drmTMB::beta_binomial(), data = data)
    }
  ),
  run_workflow(
    "ordinal_condition",
    "Does habitat shift an ordered breeding-condition score?",
    "cumulative-logit: bf(score ~ habitat + x)",
    "fixed-effect shift in ordered-category probabilities",
    "fixed-effect output only; cutpoint profile intervals are not public on main",
    "Expected category is a plotting aid, not a continuous biological measurement.",
    function() {
      habitat <- factor(rep(c("poor", "good"), each = n / 2))
      latent <- 0.9 * (habitat == "good") + 0.5 * x + stats::rlogis(n)
      score <- ordered(c("low", "medium", "high")[findInterval(latent, c(-Inf, -0.6, 0.7, Inf))],
        levels = c("low", "medium", "high"))
      data <- reader_import(data.frame(score = as.character(score), habitat, x))
      data$score <- ordered(data$score, levels = c("low", "medium", "high"))
      drmTMB::drmTMB(drmTMB::bf(score ~ habitat + x), family = drmTMB::cumulative_logit(), data = data)
    }
  ),
  run_workflow(
    "boundary_proportion",
    "Does grazing affect plant cover when absence and saturation are real outcomes?",
    "zero-one beta: bf(cover ~ grazing, sigma ~ 1, zoi ~ grazing, coi ~ 1)",
    "unconditional cover and the interior/boundary components",
    "ordinary fixed-effect Wald output for stated components",
    "coi is conditional on a boundary outcome, not an unconditional probability.",
    function() {
      grazing <- factor(rep(c("low", "high"), each = n / 2))
      cover <- stats::rbeta(n, 2 + 0.5 * (grazing == "high"), 4)
      cover[sample.int(n, 8)] <- 0
      cover[sample.int(n, 8)] <- 1
      data <- reader_import(data.frame(cover, grazing))
      drmTMB::drmTMB(drmTMB::bf(cover ~ grazing, sigma ~ 1, zoi ~ grazing, coi ~ 1),
        family = drmTMB::zero_one_beta(), data = data)
    }
  ),
  run_workflow(
    "phylogenetic_trait",
    "Does an environmental gradient predict a trait after phylogenetic dependence?",
    "Gaussian: bf(trait ~ x_phy + phylo(1 | species, tree = tree), sigma ~ 1)",
    "fixed gradient and phylogenetically structured species deviation",
    "point estimate; read target status before reporting a phylogenetic SD interval",
    "This needs a dated, ultrametric tree and should use public diagnostics, not fit internals.",
    function() {
      if (!requireNamespace("ape", quietly = TRUE)) stop("ape is not installed")
      tree <- ape::chronos(ape::rtree(16), lambda = 1)
      species <- factor(rep(tree$tip.label, each = 3), levels = tree$tip.label)
      x_phy <- rep(seq(-1, 1, length.out = 3), 16)
      trait <- 0.6 * x_phy + rep(stats::rnorm(16, sd = 0.35), each = 3) + stats::rnorm(48, sd = 0.25)
      data <- reader_import(data.frame(trait, x_phy, species))
      drmTMB::drmTMB(drmTMB::bf(trait ~ x_phy + drmTMB::phylo(1 | species, tree = tree), sigma ~ 1),
        family = stats::gaussian(), data = data)
    }
  ),
  run_workflow(
    "spatial_site_effect",
    "Does depth predict a response after smooth coordinate-based site variation?",
    "Gaussian: bf(y ~ depth + spatial(1 | site, coords = coords), sigma ~ 1)",
    "depth effect and spatial location deviation",
    "point estimate/status-led interpretation for the spatial target",
    "Coordinates must be projected metric coordinates; this does not estimate a generic spatial range.",
    function() {
      site_levels <- paste0("s", seq_len(12))
      site <- factor(rep(site_levels, each = 4), levels = site_levels)
      coords <- cbind(seq(0, 1100, length.out = 12), rep(c(0, 300, 600), length.out = 12))
      rownames(coords) <- site_levels
      depth <- rep(seq(-1, 1, length.out = 4), 12)
      y <- 0.5 + 0.7 * depth + rep(stats::rnorm(12, sd = 0.3), each = 4) + stats::rnorm(48, sd = 0.3)
      drmTMB::drmTMB(drmTMB::bf(
        y ~ depth + drmTMB::spatial(1 | site, coords = coords), sigma ~ 1
      ), family = stats::gaussian(), data = reader_import(data.frame(y, depth, site)))
    }
  ),
  run_workflow(
    "bivariate_traits",
    "Do food and disturbance jointly change activity, boldness, and residual correlation?",
    "bivariate Gaussian: drm_formula(mu1, mu2, sigma1, sigma2, rho12)",
    "two response means, two residual scales, and residual rho12",
    "fixed-effect Wald output; rho12 coverage remains target-specific",
    "rho12 is within-observation residual correlation, not a group or phylogenetic correlation.",
    function() {
      food <- stats::runif(n, -1, 1)
      disturbance <- stats::runif(n, -1, 1)
      activity <- 0.8 * food + stats::rnorm(n, sd = 0.6)
      boldness <- -0.3 + 0.5 * food + stats::rnorm(n, sd = 0.7)
      drmTMB::drmTMB(drmTMB::drm_formula(
        mu1 = activity ~ food, mu2 = boldness ~ food,
        sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ disturbance
      ), family = c(stats::gaussian(), stats::gaussian()),
      data = reader_import(data.frame(activity, boldness, food, disturbance)))
    }
  ),
  run_workflow(
    "meta_analysis",
    "What is the pooled effect after known study sampling variances and heterogeneity?",
    "Gaussian meta-regression: bf(yi ~ 1 + meta_V(V = vi), sigma ~ 1)",
    "pooled Gaussian effect and between-study sigma (tau)",
    "ordinary model output; meta_V is supplied sampling variance",
    "This is Gaussian regression with known sampling variance, not a separate meta family.",
    function() {
      vi <- stats::runif(30, 0.03, 0.12)
      yi <- stats::rnorm(30, 0.25, sqrt(vi + 0.08))
      data <- reader_import(data.frame(yi, vi))
      drmTMB::drmTMB(drmTMB::bf(yi ~ 1 + drmTMB::meta_V(V = vi), sigma ~ 1),
        family = stats::gaussian(), data = data)
    }
  ),
  run_workflow(
    "missing_response",
    "Can a growth analysis retain rows with response values missing under the documented masking route?",
    "Gaussian response mask: bf(growth ~ temperature, sigma ~ 1) + miss_control(response = include)",
    "fixed temperature effect with response rows marginalised out",
    "ordinary fixed-effect output; missingness mechanism is not identified by this fit",
    "This is response masking, not general multiple imputation and not response-plus-mi().",
    function() {
      temperature <- seq(-1.5, 1.5, length.out = n)
      growth <- 0.5 + 0.8 * temperature + stats::rnorm(n, sd = 0.3)
      growth[c(6, 22, 49)] <- NA_real_
      data <- reader_import(data.frame(growth, temperature))
      drmTMB::drmTMB(drmTMB::bf(growth ~ temperature, sigma ~ 1), family = stats::gaussian(),
        data = data,
        missing = drmTMB::miss_control(response = "include"),
        control = drmTMB::drm_control(se = FALSE))
    }
  )
)

results <- do.call(rbind, results)
out <- file.path("docs", "dev-log", "reader-workflow-audit", "2026-08-12-reader-workflow-smoke.tsv")
utils::write.table(results, out, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
print(results, row.names = FALSE)
cat("\nWrote ", out, "\n", sep = "")
