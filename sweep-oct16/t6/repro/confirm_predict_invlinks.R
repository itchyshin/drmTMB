# Standalone confirmation of t6 predict-scale mismatches (drmTMB pin ca3ddefa5).
# Run: Rscript confirm_predict_invlinks.R
suppressPackageStartupMessages(library(drmTMB))
root <- Sys.getenv("T6_ROOT", unset = "/workspace/sweep-oct16/t6")

read_cell <- function(cell) {
  d <- read.csv(file.path(root, "data", paste0(cell, ".csv")), stringsAsFactors = FALSE)
  d$f <- factor(d$f, levels = c("a", "b", "c"))
  d$g <- factor(d$g)
  d
}
nd <- data.frame(x = c(-0.5, 0, 0.5), f = factor(c("a", "b", "c"), levels = c("a", "b", "c")))

# 1. lognormal: type=response equals type=link (identity on log-Y)
dat <- read_cell("lognormal_fe")
fit <- drmTMB(bf(y ~ x + f, sigma ~ 1), family = lognormal(), data = dat)
pr <- predict(fit, newdata = nd, type = "response")
pl <- predict(fit, newdata = nd, type = "link")
cat("lognormal mu response:", paste(round(pr, 6), collapse = " "), "\n")
cat("lognormal mu link:    ", paste(round(pl, 6), collapse = " "), "\n")
cat("identical response==link:", isTRUE(all.equal(pr, pl)), "\n")

# 2. student nu: logm2 = 2+exp(eta)
dat <- read_cell("student_fe")
fit <- drmTMB(bf(y ~ x + f, sigma ~ 1, nu ~ 1), family = student(), data = dat)
pp <- predict_parameters(fit, newdata = nd, dpar = "nu")
nu_r <- pp$estimate[pp$type == "response"]
nu_l <- predict(fit, newdata = nd, dpar = "nu", type = "link")
cat("student nu response:", unique(round(nu_r, 6)), "\n")
cat("student nu link:    ", unique(round(nu_l, 6)), "\n")
cat("2+exp(link):        ", unique(round(2 + exp(nu_l), 6)), "\n")

# 3. skew_normal nu: identity
dat <- read_cell("skew_normal_fe")
fit <- drmTMB(bf(y ~ x + f, sigma ~ 1, nu ~ 1), family = skew_normal(), data = dat)
nu_r <- predict(fit, newdata = nd, dpar = "nu", type = "response")
nu_l <- predict(fit, newdata = nd, dpar = "nu", type = "link")
cat("skew_normal nu response:", unique(round(nu_r, 6)), "\n")
cat("skew_normal nu link:    ", unique(round(nu_l, 6)), "\n")

# 4. zero_one_beta mu: logit
dat <- read_cell("zero_one_beta_fe")
fit <- drmTMB(bf(y ~ x + f, sigma ~ 1, zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = dat)
mu_r <- predict(fit, newdata = nd, type = "response")
mu_l <- predict(fit, newdata = nd, type = "link")
cat("zobeta mu response:", paste(round(mu_r, 6), collapse = " "), "\n")
cat("zobeta mu link:    ", paste(round(mu_l, 6), collapse = " "), "\n")
cat("plogis(link):      ", paste(round(plogis(mu_l), 6), collapse = " "), "\n")

# 5. simulate newdata + se.fit (#1536)
dat <- read_cell("gaussian_fe")
fit <- drmTMB(bf(y ~ x + f, sigma ~ 1), family = gaussian(), data = dat)
nd2 <- data.frame(x = c(0, 1), f = factor(c("a", "b"), levels = levels(dat$f)))
s <- simulate(fit, nsim = 1, seed = 1, newdata = nd2)
cat("simulate nrow:", nrow(s), "newdata nrow:", nrow(nd2), "\n")
p_se <- predict(fit, newdata = nd2, se.fit = TRUE)
cat("predict(se.fit=TRUE) is.list:", is.list(p_se), " class:", class(p_se), "\n")

cat("\n----- sessionInfo -----\n")
print(sessionInfo())
cat("drmTMB SHA expected: ca3ddefa5ea11bbfd3b765615dfbb89305d2485a\n")
