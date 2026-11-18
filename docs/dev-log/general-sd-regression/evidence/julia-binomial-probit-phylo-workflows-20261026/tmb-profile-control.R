options(width = 120)
devtools::load_all('.', quiet = TRUE)
set.seed(202610251)
n_tip <- 36L
n_each <- 30L
tree <- ape::rcoal(n_tip)
tree$tip.label <- paste0('probit_species_', seq_len(n_tip))
height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
tree$edge.length <- tree$edge.length / height * 2.5
covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
z_species <- as.numeric(scale(stats::rnorm(n_tip)))
names(z_species) <- tree$tip.label
alpha <- c('(Intercept)' = log(0.4), z = 0.5)
tau <- exp(alpha[[1L]] + alpha[[2L]] * z_species)
field <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_tip))
group <- rep(seq_len(n_tip), each = n_each)
x <- stats::rnorm(length(group))
eta <- 0.15 + 0.3 * x + tau[group] * field[group]
y <- stats::rbinom(length(group), size = 1L, prob = stats::pnorm(eta))
data <- data.frame(y, x,
  species = factor(tree$tip.label[group], levels = tree$tip.label),
  z = z_species[group])
form <- bf(y ~ x + phylo(1 | species, tree = tree),
          sd(species, level = 'phylogenetic') ~ z)
fit <- drmTMB(form, family = stats::binomial(link = 'probit'), data = data,
              engine = 'tmb', control = drm_control(se = FALSE))
cat('tmb_converged=', is_converged(fit), '\n', sep = '')
cat('sd_coef=', paste(names(coef(fit, 'sd_phylo(species)')),
    signif(coef(fit, 'sd_phylo(species)'), 6), collapse = ';'), '\n', sep = '')
targets <- profile_targets(fit)$parm
cat('profile_targets=', paste(targets, collapse = ','), '\n', sep = '')
target <- targets[grepl('^fixef:sd_phylo\\(species\\):z$', targets)][1L]
cat('target=', target, '\n', sep = '')
t0 <- proc.time()[['elapsed']]
result <- tryCatch(confint(fit, parm = target, method = 'profile', level = 0.80),
  error = function(e) { cat('profile_error=', conditionMessage(e), '\n', sep = ''); NULL })
cat('profile_elapsed_seconds=', proc.time()[['elapsed']] - t0, '\n', sep = '')
if (!is.null(result)) print(result)
