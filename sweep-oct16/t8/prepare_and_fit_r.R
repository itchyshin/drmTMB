#!/usr/bin/env Rscript
# sweep-oct16/t8: prepare one dataset and fit drmTMB + reference.
# Usage: Rscript prepare_and_fit_r.R <case_id>
# Writes: data/<id>.csv, fits/<id>/spec.json, fits/<id>/r.json, fits/<id>/ref.json
#         fits/<id>/prepare.R (the exact prep used)

suppressPackageStartupMessages({
  library(drmTMB)
  library(jsonlite)
})

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("need case id")
id <- args[[1]]
root <- Sys.getenv("T8_ROOT", unset = "/workspace/sweep-oct16/t8")
dir.create(file.path(root, "data"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "fits", id), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "repro"), recursive = TRUE, showWarnings = FALSE)

chr_factor <- function(x) {
  # Prefix all-digit labels so CSV.jl / StatsModels cannot parse them as
  # numeric (batch 1:10 would otherwise become a linear covariate).
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) {
    x <- paste0("g", x)
  }
  factor(x, levels = sort(unique(x)))
}

safe_se <- function(fit) {
  out <- tryCatch({
    v <- vcov(fit)
    se <- sqrt(diag(as.matrix(v)))
    as.list(se)
  }, error = function(e) {
    list(.error = conditionMessage(e))
  })
  out
}

flatten_coef <- function(fit) {
  cf <- tryCatch(coef(fit), error = function(e) NULL)
  if (is.null(cf)) return(list())
  est <- list()
  if (is.list(cf) && !is.null(names(cf))) {
    for (dpar in names(cf)) {
      v <- cf[[dpar]]
      if (is.null(v)) next
      nms <- names(v)
      if (is.null(nms)) nms <- paste0("b", seq_along(v))
      for (i in seq_along(v)) {
        est[[paste0(dpar, ":", nms[[i]])]] <- unname(as.numeric(v[[i]]))
      }
    }
  } else if (is.numeric(cf)) {
    nms <- names(cf)
    if (is.null(nms)) nms <- paste0("b", seq_along(cf))
    for (i in seq_along(cf)) est[[nms[[i]]]] <- unname(as.numeric(cf[[i]]))
  }
  est
}

extract_drm <- function(fit, engine = "drmTMB") {
  if (inherits(fit, "try-error") || inherits(fit, "error")) {
    msg <- if (inherits(fit, "try-error")) as.character(fit) else conditionMessage(fit)
    return(list(engine = engine, ok = FALSE, error = msg, logLik = NA,
                converged = FALSE, nobs = NA, coef = list(), se = list(),
                elapsed_s = NA))
  }
  ll <- tryCatch(as.numeric(logLik(fit)), error = function(e) NA_real_)
  conv <- tryCatch({
    if (exists("is_converged", mode = "function")) is_converged(fit) else NA
  }, error = function(e) NA)
  nobs <- tryCatch(nobs(fit), error = function(e) NA)
  list(
    engine = engine, ok = TRUE, error = NULL,
    logLik = ll, converged = conv, nobs = nobs,
    coef = flatten_coef(fit), se = safe_se(fit)
  )
}

extract_ref <- function(fit, engine) {
  if (inherits(fit, "try-error") || inherits(fit, "error")) {
    msg <- if (inherits(fit, "try-error")) as.character(fit) else conditionMessage(fit)
    return(list(engine = engine, ok = FALSE, error = msg, logLik = NA,
                converged = FALSE, coef = list(), se = list()))
  }
  ll <- tryCatch(as.numeric(logLik(fit)), error = function(e) NA_real_)
  conv <- tryCatch({
    if (engine == "glmmTMB") {
      isTRUE(fit$fit$convergence == 0)
    } else if (engine == "lme4") {
      isTRUE(is.null(fit@optinfo$conv$lme4$code) || identical(fit@optinfo$conv$lme4$code, 0L))
    } else TRUE
  }, error = function(e) NA)
  cf <- list()
  se <- list()
  try({
    if (engine == "glmmTMB") {
      fe <- glmmTMB::fixef(fit)
      for (blk in names(fe)) {
        v <- fe[[blk]]
        for (nm in names(v)) cf[[paste0(blk, ":", nm)]] <- unname(as.numeric(v[[nm]]))
      }
      vv <- tryCatch(sqrt(diag(vcov(fit)$cond)), error = function(e) NULL)
      if (!is.null(vv)) for (nm in names(vv)) se[[paste0("cond:", nm)]] <- unname(as.numeric(vv[[nm]]))
      vd <- tryCatch(sqrt(diag(vcov(fit)$disp)), error = function(e) NULL)
      if (!is.null(vd)) for (nm in names(vd)) se[[paste0("disp:", nm)]] <- unname(as.numeric(vd[[nm]]))
    } else if (engine == "lme4") {
      fe <- lme4::fixef(fit)
      for (nm in names(fe)) cf[[paste0("mu:", nm)]] <- unname(as.numeric(fe[[nm]]))
      vv <- tryCatch(sqrt(diag(as.matrix(vcov(fit)))), error = function(e) NULL)
      if (!is.null(vv)) for (nm in names(vv)) se[[paste0("mu:", nm)]] <- unname(as.numeric(vv[[nm]]))
    }
  }, silent = TRUE)
  list(engine = engine, ok = TRUE, error = NULL, logLik = ll, converged = conv,
       coef = cf, se = se)
}

pkg_ver <- function(pkg) {
  if (pkg %in% c("datasets", "stats")) {
    return(as.character(getRversion()))
  }
  tryCatch(as.character(utils::packageVersion(pkg)), error = function(e) NA_character_)
}

write_csv_sorted <- function(d, path) {
  # write factors as character so Julia StatsModels sorts the same way
  d2 <- d
  for (nm in names(d2)) {
    if (is.factor(d2[[nm]])) d2[[nm]] <- as.character(d2[[nm]])
  }
  utils::write.csv(d2, path, row.names = FALSE)
}

prep <- NULL
spec <- NULL

if (id == "warpbreaks") {
  data(warpbreaks, package = "datasets")
  d <- warpbreaks
  d$wool <- chr_factor(d$wool)
  d$tension <- chr_factor(d$tension)
  prep <- paste(c(
    "data(warpbreaks, package = \"datasets\")",
    "d <- warpbreaks",
    "# chr_factor(): character levels, with 'g' prefix if the labels are all digits",
    "d$wool <- chr_factor(d$wool)",
    "d$tension <- chr_factor(d$tension)"
  ), collapse = "\n")
  spec <- list(
    source = "datasets::warpbreaks", source_version = pkg_ver("datasets"),
    family_r = "gaussian", family_jl = "Gaussian",
    mu_r = "breaks ~ wool * tension", sigma_r = "~ wool",
    mu_jl = "breaks ~ 1 + wool * tension", sigma_jl = "sigma ~ 1 + wool",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(breaks ~ wool * tension, dispformula = ~ wool, family = gaussian(), data = d, REML = FALSE)"
  )
} else if (id == "ToothGrowth") {
  data(ToothGrowth, package = "datasets")
  d <- ToothGrowth
  d$supp <- chr_factor(d$supp)
  prep <- paste(c(
    "data(ToothGrowth, package = \"datasets\")",
    "d <- ToothGrowth",
    "d$supp <- chr_factor(d$supp)"
  ), collapse = "\n")
  spec <- list(
    source = "datasets::ToothGrowth", source_version = pkg_ver("datasets"),
    family_r = "gaussian", family_jl = "Gaussian",
    mu_r = "len ~ dose * supp", sigma_r = "~ supp",
    mu_jl = "len ~ 1 + dose * supp", sigma_jl = "sigma ~ 1 + supp",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(len ~ dose * supp, dispformula = ~ supp, family = gaussian(), data = d, REML = FALSE)"
  )
} else if (id == "Prestige") {
  data(Prestige, package = "carData")
  d <- subset(carData::Prestige, !is.na(type))
  d$type <- chr_factor(d$type)
  rownames(d) <- NULL
  prep <- paste(c(
    "data(Prestige, package = \"carData\")",
    "d <- subset(carData::Prestige, !is.na(type))",
    "d$type <- chr_factor(d$type)",
    "rownames(d) <- NULL"
  ), collapse = "\n")
  spec <- list(
    source = "carData::Prestige", source_version = pkg_ver("carData"),
    family_r = "gaussian", family_jl = "Gaussian",
    mu_r = "prestige ~ education + log(income) + type", sigma_r = "~ type",
    mu_jl = "prestige ~ 1 + education + logincome + type", sigma_jl = "sigma ~ 1 + type",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(prestige ~ education + log(income) + type, dispformula = ~ type, family = gaussian(), data = d, REML = FALSE)",
    extra_cols = "logincome = log(income) written for Julia"
  )
  d$logincome <- log(d$income)
} else if (id == "GasolineYield") {
  data(GasolineYield, package = "betareg")
  d <- GasolineYield
  d$batch <- chr_factor(d$batch)
  prep <- paste(c(
    "data(GasolineYield, package = \"betareg\")",
    "d <- GasolineYield",
    "d$batch <- chr_factor(d$batch)"
  ), collapse = "\n")
  spec <- list(
    source = "betareg::GasolineYield", source_version = pkg_ver("betareg"),
    family_r = "beta", family_jl = "Beta",
    mu_r = "yield ~ temp + batch", sigma_r = "~ batch",
    mu_jl = "yield ~ 1 + temp + batch", sigma_jl = "sigma ~ 1 + batch",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(yield ~ temp + batch, dispformula = ~ batch, family = glmmTMB::beta_family(), data = d)"
  )
} else if (id == "ReadingSkills") {
  data(ReadingSkills, package = "betareg")
  d <- ReadingSkills
  d$dyslexia <- chr_factor(d$dyslexia)
  prep <- paste(c(
    "data(ReadingSkills, package = \"betareg\")",
    "d <- ReadingSkills",
    "d$dyslexia <- chr_factor(d$dyslexia)"
  ), collapse = "\n")
  spec <- list(
    source = "betareg::ReadingSkills", source_version = pkg_ver("betareg"),
    family_r = "beta", family_jl = "Beta",
    mu_r = "accuracy ~ dyslexia * iq", sigma_r = "~ dyslexia",
    mu_jl = "accuracy ~ 1 + dyslexia * iq", sigma_jl = "sigma ~ 1 + dyslexia",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(accuracy ~ dyslexia * iq, dispformula = ~ dyslexia, family = glmmTMB::beta_family(), data = d)"
  )
} else if (id == "quine") {
  data(quine, package = "MASS")
  d <- MASS::quine
  for (nm in c("Eth", "Sex", "Age", "Lrn")) d[[nm]] <- chr_factor(d[[nm]])
  prep <- paste(c(
    "data(quine, package = \"MASS\")",
    "d <- MASS::quine",
    "for (nm in c(\"Eth\",\"Sex\",\"Age\",\"Lrn\")) d[[nm]] <- chr_factor(d[[nm]])"
  ), collapse = "\n")
  spec <- list(
    source = "MASS::quine", source_version = pkg_ver("MASS"),
    family_r = "nbinom2", family_jl = "NegBinomial2",
    mu_r = "Days ~ Eth + Sex + Age + Lrn", sigma_r = "~ Eth",
    mu_jl = "Days ~ 1 + Eth + Sex + Age + Lrn", sigma_jl = "sigma ~ 1 + Eth",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(Days ~ Eth + Sex + Age + Lrn, dispformula = ~ Eth, family = glmmTMB::nbinom2(), data = d)"
  )
} else if (id == "cbpp") {
  data(cbpp, package = "lme4")
  d <- lme4::cbpp
  d$herd <- chr_factor(d$herd)
  d$period <- chr_factor(d$period)
  d$fail <- d$size - d$incidence
  prep <- paste(c(
    "data(cbpp, package = \"lme4\")",
    "d <- lme4::cbpp",
    "d$herd <- chr_factor(d$herd)",
    "d$period <- chr_factor(d$period)",
    "d$fail <- d$size - d$incidence"
  ), collapse = "\n")
  spec <- list(
    source = "lme4::cbpp", source_version = pkg_ver("lme4"),
    family_r = "beta_binomial", family_jl = "BetaBinomial",
    mu_r = "cbind(incidence, fail) ~ period + (1 | herd)", sigma_r = "~ 1",
    mu_jl = "cbind(incidence, fail) ~ 1 + period + (1 | herd)", sigma_jl = "sigma ~ 1",
    has_re = TRUE, cbind_success = "incidence", cbind_fail = "fail",
    ref = "glmmTMB",
    ref_call = "glmmTMB(cbind(incidence, fail) ~ period + (1 | herd), dispformula = ~ 1, family = glmmTMB::betabinomial(), data = d)"
  )
} else if (id == "epil") {
  data(epil, package = "MASS")
  d <- MASS::epil
  d$trt <- chr_factor(d$trt)
  d$subject <- chr_factor(d$subject)
  d$V4 <- as.numeric(d$V4)
  prep <- paste(c(
    "data(epil, package = \"MASS\")",
    "d <- MASS::epil",
    "d$trt <- chr_factor(d$trt)",
    "d$subject <- chr_factor(d$subject)",
    "d$V4 <- as.numeric(d$V4)"
  ), collapse = "\n")
  spec <- list(
    source = "MASS::epil", source_version = pkg_ver("MASS"),
    family_r = "nbinom2", family_jl = "NegBinomial2",
    mu_r = "y ~ lbase + trt + lage + V4 + (1 | subject)", sigma_r = "~ 1",
    mu_jl = "y ~ 1 + lbase + trt + lage + V4 + (1 | subject)", sigma_jl = "sigma ~ 1",
    has_re = TRUE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(y ~ lbase + trt + lage + V4 + (1 | subject), family = glmmTMB::nbinom2(), data = d)"
  )
} else if (id == "Orthodont") {
  data(Orthodont, package = "nlme")
  d <- as.data.frame(nlme::Orthodont)
  d$Subject <- chr_factor(d$Subject)
  d$Sex <- chr_factor(d$Sex)
  prep <- paste(c(
    "data(Orthodont, package = \"nlme\")",
    "d <- as.data.frame(nlme::Orthodont)",
    "d$Subject <- chr_factor(d$Subject)",
    "d$Sex <- chr_factor(d$Sex)"
  ), collapse = "\n")
  spec <- list(
    source = "nlme::Orthodont", source_version = pkg_ver("nlme"),
    family_r = "gaussian", family_jl = "Gaussian",
    mu_r = "distance ~ age * Sex + (1 | Subject)", sigma_r = "~ Sex",
    mu_jl = "distance ~ 1 + age * Sex + (1 | Subject)", sigma_jl = "sigma ~ 1 + Sex",
    has_re = TRUE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(distance ~ age * Sex + (1 | Subject), dispformula = ~ Sex, family = gaussian(), data = d, REML = FALSE)"
  )
} else if (id == "yates_oats") {
  data(yates.oats, package = "agridat")
  d <- agridat::yates.oats
  d$gen <- chr_factor(d$gen)
  d$block <- chr_factor(d$block)
  prep <- paste(c(
    "data(yates.oats, package = \"agridat\")",
    "d <- agridat::yates.oats",
    "d$gen <- chr_factor(d$gen)",
    "d$block <- chr_factor(d$block)"
  ), collapse = "\n")
  spec <- list(
    source = "agridat::yates.oats", source_version = pkg_ver("agridat"),
    family_r = "gaussian", family_jl = "Gaussian",
    mu_r = "yield ~ nitro * gen + (1 | block)", sigma_r = "~ gen",
    mu_jl = "yield ~ 1 + nitro * gen + (1 | block)", sigma_jl = "sigma ~ 1 + gen",
    has_re = TRUE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(yield ~ nitro * gen + (1 | block), dispformula = ~ gen, family = gaussian(), data = d, REML = FALSE)"
  )
} else if (id == "Pastes") {
  data(Pastes, package = "lme4")
  d <- lme4::Pastes
  d$batch <- chr_factor(d$batch)
  d$cask <- chr_factor(d$cask)
  d$sample <- chr_factor(d$sample)
  prep <- paste(c(
    "data(Pastes, package = \"lme4\")",
    "d <- lme4::Pastes",
    "d$batch <- chr_factor(d$batch)",
    "d$cask <- chr_factor(d$cask)",
    "d$sample <- chr_factor(d$sample)"
  ), collapse = "\n")
  spec <- list(
    source = "lme4::Pastes", source_version = pkg_ver("lme4"),
    family_r = "gaussian", family_jl = "Gaussian",
    mu_r = "strength ~ 1 + (1 | batch) + (1 | sample)", sigma_r = "~ 1",
    mu_jl = "strength ~ 1 + (1 | batch) + (1 | sample)", sigma_jl = "sigma ~ 1",
    has_re = TRUE, cbind_success = NULL, cbind_fail = NULL,
    ref = "lme4",
    ref_call = "lme4::lmer(strength ~ 1 + (1 | batch) + (1 | sample), data = d, REML = FALSE)"
  )
} else if (id == "bacteria") {
  data(bacteria, package = "MASS")
  d <- MASS::bacteria
  d$y01 <- as.integer(d$y == "y")
  d$week <- as.numeric(d$week)
  d$trt <- chr_factor(d$trt)
  d$ID <- chr_factor(d$ID)
  prep <- paste(c(
    "data(bacteria, package = \"MASS\")",
    "d <- MASS::bacteria",
    "d$y01 <- as.integer(d$y == \"y\")",
    "d$week <- as.numeric(d$week)",
    "d$trt <- chr_factor(d$trt)",
    "d$ID <- chr_factor(d$ID)"
  ), collapse = "\n")
  spec <- list(
    source = "MASS::bacteria", source_version = pkg_ver("MASS"),
    family_r = "binomial", family_jl = "Binomial",
    mu_r = "y01 ~ week + trt + (1 | ID)", sigma_r = NULL,
    mu_jl = "y01 ~ 1 + week + trt + (1 | ID)", sigma_jl = NULL,
    has_re = TRUE, cbind_success = NULL, cbind_fail = NULL,
    ref = "lme4",
    ref_call = "lme4::glmer(y01 ~ week + trt + (1 | ID), family = binomial, data = d, nAGQ = 1)"
  )
} else if (id == "crowder_seeds") {
  data(crowder.seeds, package = "agridat")
  d <- agridat::crowder.seeds
  d$gen <- chr_factor(d$gen)
  d$extract <- chr_factor(d$extract)
  d$fail <- d$n - d$germ
  prep <- paste(c(
    "data(crowder.seeds, package = \"agridat\")",
    "d <- agridat::crowder.seeds",
    "d$gen <- chr_factor(d$gen)",
    "d$extract <- chr_factor(d$extract)",
    "d$fail <- d$n - d$germ"
  ), collapse = "\n")
  spec <- list(
    source = "agridat::crowder.seeds", source_version = pkg_ver("agridat"),
    family_r = "beta_binomial", family_jl = "BetaBinomial",
    mu_r = "cbind(germ, fail) ~ gen * extract", sigma_r = "~ 1",
    mu_jl = "cbind(germ, fail) ~ 1 + gen * extract", sigma_jl = "sigma ~ 1",
    has_re = FALSE, cbind_success = "germ", cbind_fail = "fail",
    ref = "glmmTMB",
    ref_call = "glmmTMB(cbind(germ, fail) ~ gen * extract, family = glmmTMB::betabinomial(), data = d)"
  )
} else if (id == "beall_webworms") {
  data(beall.webworms, package = "agridat")
  d <- agridat::beall.webworms
  d$spray <- chr_factor(d$spray)
  d$lead <- chr_factor(d$lead)
  prep <- paste(c(
    "data(beall.webworms, package = \"agridat\")",
    "d <- agridat::beall.webworms",
    "d$spray <- chr_factor(d$spray)",
    "d$lead <- chr_factor(d$lead)"
  ), collapse = "\n")
  spec <- list(
    source = "agridat::beall.webworms", source_version = pkg_ver("agridat"),
    family_r = "nbinom2", family_jl = "NegBinomial2",
    mu_r = "y ~ spray * lead", sigma_r = "~ spray",
    mu_jl = "y ~ 1 + spray * lead", sigma_jl = "sigma ~ 1 + spray",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(y ~ spray * lead, dispformula = ~ spray, family = glmmTMB::nbinom2(), data = d)"
  )
} else if (id == "Owls") {
  data(Owls, package = "glmmTMB")
  d <- glmmTMB::Owls
  d$FoodTreatment <- chr_factor(d$FoodTreatment)
  d$SexParent <- chr_factor(d$SexParent)
  d$Nest <- chr_factor(d$Nest)
  d$NCalls <- d$SiblingNegotiation
  prep <- paste(c(
    "data(Owls, package = \"glmmTMB\")",
    "d <- glmmTMB::Owls",
    "d$FoodTreatment <- chr_factor(d$FoodTreatment)",
    "d$SexParent <- chr_factor(d$SexParent)",
    "d$Nest <- chr_factor(d$Nest)",
    "d$NCalls <- d$SiblingNegotiation"
  ), collapse = "\n")
  spec <- list(
    source = "glmmTMB::Owls", source_version = pkg_ver("glmmTMB"),
    family_r = "nbinom2", family_jl = "NegBinomial2",
    mu_r = "NCalls ~ FoodTreatment * ArrivalTime + offset(logBroodSize)",
    sigma_r = "~ FoodTreatment",
    mu_jl = "NCalls ~ 1 + FoodTreatment * ArrivalTime + offset(logBroodSize)",
    sigma_jl = "sigma ~ 1 + FoodTreatment",
    has_re = FALSE, cbind_success = NULL, cbind_fail = NULL,
    ref = "glmmTMB",
    ref_call = "glmmTMB(NCalls ~ FoodTreatment * ArrivalTime + offset(logBroodSize), dispformula = ~ FoodTreatment, family = glmmTMB::nbinom2(), data = d)",
    zi_re_probe_r = "bf(mu = NCalls ~ FoodTreatment * ArrivalTime + offset(logBroodSize) + (1 | Nest), zi = ~ FoodTreatment), family = nbinom2()"
  )
} else {
  stop("unknown case id: ", id)
}

fam <- switch(
  spec$family_r,
  gaussian = gaussian(),
  nbinom2 = nbinom2(),
  beta = beta_family(),
  beta_binomial = beta_binomial(),
  binomial = binomial(),
  poisson = poisson(),
  Gamma = Gamma(link = "log"),
  stop("unknown family_r")
)

make_bf <- function(spec) {
  mu <- as.formula(spec$mu_r)
  if (is.null(spec$sigma_r) || !nzchar(spec$sigma_r)) {
    bf(mu = mu)
  } else {
    sig <- as.formula(spec$sigma_r)
    bf(mu = mu, sigma = sig)
  }
}

csv_path <- file.path(root, "data", paste0(id, ".csv"))
write_csv_sorted(d, csv_path)
chr_factor_src <- paste(c(
  "chr_factor <- function(x) {",
  "  x <- as.character(x)",
  "  if (length(x) && all(grepl(\"^[0-9]+$\", x))) x <- paste0(\"g\", x)",
  "  factor(x, levels = sort(unique(x)))",
  "}"
), collapse = "\n")
writeLines(paste(chr_factor_src, prep, sep = "\n"), file.path(root, "fits", id, "prepare.R"))

# small dput for issue bodies
dp <- utils::capture.output(dput(d))
if (sum(nchar(dp)) < 55000) {
  writeLines(dp, file.path(root, "fits", id, "dput.R"))
}

spec$id <- id
spec$n <- nrow(d)
spec$csv <- csv_path
spec$prepare <- prep
spec$drmTMB_sha <- "ca3ddefa5ea11bbfd3b765615dfbb89305d2485a"
spec$DRModels_sha <- "f71b2923360e9e5d4591e0d6e15a9ef9db0356d7"
spec$drmTMB_version <- as.character(utils::packageVersion("drmTMB"))
write_json(spec, file.path(root, "fits", id, "spec.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null")

# --- drmTMB fit ---
t0 <- proc.time()[["elapsed"]]
fit_r <- try(drmTMB(make_bf(spec), family = fam, data = d), silent = TRUE)
elapsed_r <- proc.time()[["elapsed"]] - t0
res_r <- extract_drm(fit_r, "drmTMB")
res_r$elapsed_s <- elapsed_r
if (isTRUE(res_r$ok)) {
  res_r$opt_convergence <- tryCatch(fit_r$opt$convergence, error = function(e) NA)
  res_r$opt_message <- tryCatch(paste(fit_r$opt$message, collapse = " "), error = function(e) NA)
}
write_json(res_r, file.path(root, "fits", id, "r.json"), auto_unbox = TRUE, pretty = TRUE, na = "null", digits = NA)
cat(sprintf("[%s] drmTMB ok=%s logLik=%s elapsed=%.1fs error=%s\n",
            id, res_r$ok, format(res_r$logLik, digits = 15), elapsed_r,
            if (is.null(res_r$error)) "NULL" else res_r$error))

# Owls ZI+RE probe (known gap #1451) — do not fail the case on it
if (id == "Owls") {
  t1 <- proc.time()[["elapsed"]]
  probe <- try(
    drmTMB(
      bf(
        mu = NCalls ~ FoodTreatment * ArrivalTime + offset(logBroodSize) + (1 | Nest),
        zi = ~ FoodTreatment
      ),
      family = nbinom2(),
      data = d
    ),
    silent = TRUE
  )
  elapsed_p <- proc.time()[["elapsed"]] - t1
  pr <- extract_drm(probe, "drmTMB-zi-re-probe")
  pr$elapsed_s <- elapsed_p
  write_json(pr, file.path(root, "fits", id, "r_zi_re_probe.json"), auto_unbox = TRUE, pretty = TRUE, na = "null", digits = NA)
  cat(sprintf("[%s] ZI+RE probe ok=%s error=%s\n", id, pr$ok,
              if (is.null(pr$error)) "NULL" else pr$error))
}

# --- reference fit ---
res_ref <- list(engine = spec$ref, ok = FALSE, error = "not run", logLik = NA)
t2 <- proc.time()[["elapsed"]]
if (identical(spec$ref, "glmmTMB")) {
  suppressPackageStartupMessages(library(glmmTMB))
  fit_ref <- try(eval(parse(text = spec$ref_call)), silent = TRUE)
  res_ref <- extract_ref(fit_ref, "glmmTMB")
} else if (identical(spec$ref, "lme4")) {
  suppressPackageStartupMessages(library(lme4))
  fit_ref <- try(eval(parse(text = spec$ref_call)), silent = TRUE)
  res_ref <- extract_ref(fit_ref, "lme4")
}
res_ref$elapsed_s <- proc.time()[["elapsed"]] - t2
write_json(res_ref, file.path(root, "fits", id, "ref.json"), auto_unbox = TRUE, pretty = TRUE, na = "null", digits = NA)
cat(sprintf("[%s] ref(%s) ok=%s logLik=%s elapsed=%.1fs error=%s\n",
            id, spec$ref, res_ref$ok, format(res_ref$logLik, digits = 15),
            res_ref$elapsed_s,
            if (is.null(res_ref$error)) "NULL" else res_ref$error))

invisible(NULL)
