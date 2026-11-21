# Julia minus R at the optimum, per route and seed. usage: Rscript compare.R (from this directory)
routes <- c("animal", "relmat", "phylo", "spatial"); rows <- list(); pr <- list()
for (route in routes) for (s in 1:5) {
  tag <- sprintf("%s_s%02d", route, s)
  jl <- read.csv(file.path("julia", paste0(tag, "_ll.csv")), colClasses = c(ll = "character"))
  rl <- read.csv(file.path("r", paste0(tag, "_ll.csv")), colClasses = c(ll = "character"))
  j <- read.csv(file.path("julia", paste0(tag, ".csv"))); r <- read.csv(file.path("r", paste0(tag, ".csv")))
  stopifnot(nrow(j) == nrow(r)); dif <- j$est - r$est
  rows[[tag]] <- data.frame(route = route, seed = s, both_converged = identical(jl$converged, "true") && rl$convergence == 0,
    r_pdHess = rl$pdHess, ll_julia = as.numeric(jl$ll), ll_R = as.numeric(rl$ll), ll_diff = as.numeric(jl$ll) - as.numeric(rl$ll),
    max_abs_coef_diff = max(abs(dif)), max_coef_diff_r_se = max(abs(dif / r$se)), max_se_rel_diff = max(abs(j$se / r$se - 1)),
    min_log_sd_R = min(r$est[4:5]), julia_sec = as.numeric(jl$seconds), r_sec = rl$seconds)
  pr[[tag]] <- data.frame(route = route, seed = s, r_name = r$name, julia_est = j$est, r_est = r$est, diff = dif, julia_se = j$se, r_se = r$se)
}
raw <- do.call(rbind, rows); rownames(raw) <- NULL; write.csv(raw, "raw_per_seed.csv", row.names = FALSE)
write.csv(do.call(rbind, pr), "raw_per_parameter.csv", row.names = FALSE)
summ <- do.call(rbind, lapply(split(raw, factor(raw$route, levels = routes)), function(x) data.frame(route = x$route[1], seeds = nrow(x),
  both_converged = sum(x$both_converged), r_pdHess = sum(x$r_pdHess %in% TRUE), worst_abs_ll_diff = max(abs(x$ll_diff)),
  worst_abs_coef_diff = max(x$max_abs_coef_diff), worst_coef_diff_r_se = max(x$max_coef_diff_r_se), worst_se_rel_diff = max(x$max_se_rel_diff),
  min_log_sd_R = min(x$min_log_sd_R))))
rownames(summ) <- NULL; write.csv(summ, "summary.csv", row.names = FALSE); print(summ, digits = 3)
