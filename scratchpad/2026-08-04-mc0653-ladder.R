suppressMessages(library(drmTMB)); suppressMessages(library(testthat))
src <- readLines("tests/testthat/test-phylo-interaction.R")
# source only the helper definitions (everything before the first test_that)
first <- grep("^test_that", src)[1]
eval(parse(text = paste(src[1:(first-1)], collapse="\n")), envir = globalenv())

fit_one <- function(np, npo, ne, seed) {
  sim <- new_zi_nbinom2_sigma_phylo_interaction_data(
    seed = seed, n_plant = np, n_pollinator = npo, n_each = ne)
  t1 <- sim$plant_tree; t2 <- sim$pollinator_tree
  f <- try(drmTMB(bf(count ~ x, sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = t1, tree2 = t2), zi ~ 1),
                  family = nbinom2(), data = sim$data,
                  control = drm_control(se = TRUE)), silent = TRUE)
  if (inherits(f,"try-error")) return(data.frame(np=np,npo=npo,ne=ne,seed=seed,pairs=np*npo,n=NA,
                                                 sd_hat=NA,conv=NA,pdhess=NA,status=substr(as.character(f),1,60)))
  sd_hat <- tryCatch(unname(f$sdpars$sigma[[1]]), error=function(e) NA_real_)
  data.frame(np=np,npo=npo,ne=ne,seed=seed,pairs=np*npo,n=nrow(sim$data),
             sd_hat=sd_hat, conv=f$opt$convergence,
             pdhess=isTRUE(f$uncertainty$status=="ok"), status="ok")
}
args <- commandArgs(trailingOnly=TRUE)
grid <- eval(parse(text=args[1]))
res <- do.call(rbind, lapply(seq_len(nrow(grid)), function(i)
  fit_one(grid$np[i], grid$npo[i], grid$ne[i], grid$seed[i])))
res$truth <- 0.60; res$rel_err <- (res$sd_hat - 0.60)/0.60
print(res, row.names=FALSE, digits=4)
