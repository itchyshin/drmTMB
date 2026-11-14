# Adversarial dataset generator (red team). One source of truth for both engines.
# Writes rt/cells/<ds>/{data_<kind>_<fam>.csv, tree.nwk, coords.csv, A.csv, A_ids.csv, meta.json}
# and rt/cells.tsv (ds, route, fam).
suppressMessages(library(ape))
RT <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/rt"
set.seed(20261108)
G <- 24L; m <- 8L
ids <- sprintf("g%02d", 1:G)
fams <- c("gaussian", "poisson", "nb2", "gamma", "binomial")
kinds <- c("ord", "ordq2", "animal", "phylo", "spatial")

# ---- base kernels (24 groups) ------------------------------------------------
mk_tree <- function(n, labels) {
  t <- rcoal(n); t$tip.label <- labels; t$edge.length <- t$edge.length * 2 / max(node.depth.edgelength(t))
  t
}
tree24 <- mk_tree(G, ids)
Cphy <- vcv(tree24, corr = TRUE)[ids, ids]
coords24 <- as.matrix(expand.grid(e = 1:6, n = 1:4)); rownames(coords24) <- ids
mk_Csp <- function(co) { d <- as.matrix(dist(co)); rg <- median(d[upper.tri(d)]); exp(-d / rg) + diag(1e-6, nrow(co)) }
Csp <- mk_Csp(coords24)
R <- 0.4^abs(outer(1:G, 1:G, "-")); sc <- seq(0.7, 1.4, length.out = G)
A24 <- diag(sc) %*% R %*% diag(sc); dimnames(A24) <- list(ids, ids)
chol_t <- function(C) t(chol(C + diag(1e-9, nrow(C))))

# ---- base data per (kind, fam) ----------------------------------------------
z0g <- rep(c(-1, 1), G / 2); z1g <- round(seq(-1, 1, length.out = G)[sample.int(G)], 6)
names(z0g) <- names(z1g) <- ids
gen_base <- function(kind, fam) {
  gi <- rep(1:G, each = m); n <- length(gi)
  x <- rnorm(n)
  s0 <- exp(-0.6 + 0.4 * z0g); s1 <- exp(-0.8 + 0.3 * z1g)
  e0 <- rnorm(G); e1 <- rnorm(G)
  if (kind %in% c("animal", "phylo", "spatial")) {
    L <- chol_t(switch(kind, animal = A24, phylo = Cphy, spatial = Csp))
    e0 <- as.vector(L %*% e0)
  }
  b0 <- s0 * e0; b1 <- s1 * e1
  eta <- 0.2 + 0.3 * x + b0[gi]
  if (kind == "ordq2") eta <- eta + x * b1[gi]
  y <- switch(fam,
    gaussian = eta + rnorm(n, 0, 0.5),
    poisson  = rpois(n, exp(eta)),
    nb2      = rnbinom(n, mu = exp(eta), size = 3),
    gamma    = rgamma(n, shape = 4, rate = 4 / exp(eta)),
    binomial = rbinom(n, 1, plogis(eta)))
  data.frame(y = as.numeric(y), x = x, z = z0g[gi], z0 = z0g[gi], z1 = z1g[gi], g = ids[gi],
             stringsAsFactors = FALSE)
}
base <- list()
for (k in kinds) for (f in fams) base[[paste(k, f)]] <- gen_base(k, f)

# ---- dataset catalogue --------------------------------------------------------
# mod(d, fam, kind) -> data.frame or NULL (skip); aux = list of kernel replacements.
all_fams <- fams; cnt <- c("poisson", "nb2"); noOut <- c("gaussian", "poisson", "nb2", "gamma")
generic_routes <- function(f) c(ord = all_fams, ordq2 = all_fams) # placeholder (see cells below)
ds <- list()
add <- function(id, mod = function(d, fam, kind) d, aux = list(), routes = kinds, fam_ok = fams,
                struct_fams = c("gaussian", "poisson"), note = "") {
  ds[[id]] <<- list(id = id, mod = mod, aux = aux, routes = routes, fam_ok = fam_ok,
                    struct_fams = struct_fams, note = note)
}
rows_of <- function(d, g) which(d$g == g)

add("d00_baseline", struct_fams = fams, note = "control")
add("d01a_one_singleton_group", mod = function(d, fam, kind) { r <- rows_of(d, "g03"); d[-r[-1], ] })
add("d01b_all_singletons", mod = function(d, fam, kind) d[!duplicated(d$g), ])
add("d02_identical_y_in_group", mod = function(d, fam, kind) { r <- rows_of(d, "g02"); d$y[r] <- if (fam == "binomial") 1 else d$y[r[1]]; d })
add("d03_single_level_group", mod = function(d, fam, kind) { d$g <- "g01"; d$z <- d$z0 <- d$z0[1]; d$z1 <- d$z1[1]; d })
add("d04_separated_bernoulli", mod = function(d, fam, kind) { d$y <- as.numeric(d$x > 0); d }, fam_ok = "binomial", struct_fams = "binomial")
add("d05_zero_counts_in_group", mod = function(d, fam, kind) { d$y[rows_of(d, "g04")] <- 0; d },
    fam_ok = c("poisson", "nb2", "binomial"), struct_fams = c("poisson", "nb2", "binomial"))
add("d06a_duplicate_coords", aux = list(coords = function(co) { co["g02", ] <- co["g01", ]; co["g10", ] <- co["g09", ]; co["g17", ] <- co["g16", ]; co }),
    routes = "spatial", struct_fams = fams)
add("d06b_all_coords_identical", aux = list(coords = function(co) { co[] <- rep(c(1, 1), each = nrow(co)); co }),
    routes = "spatial", struct_fams = c("gaussian", "poisson"))
add("d07a_tree_zero_internal_branches", aux = list(tree = function(t) {
      # zero an internal edge and push its length onto the child edges: ultrametric preserved, node heights tied
      nt <- Ntip(t); ie <- which(t$edge[, 2] > nt)
      for (e in ie[seq(2, length(ie), by = 2)]) { v <- t$edge[e, 2]; L <- t$edge.length[e]; t$edge.length[e] <- 0
        ch <- which(t$edge[, 1] == v); t$edge.length[ch] <- t$edge.length[ch] + L }
      t }),
    routes = "phylo", struct_fams = fams)
add("d07b_tree_zero_terminal_branches", aux = list(tree = function(t) {
      # three cherries get zero-length terminal branches (identical tips, singular C); ultrametric preserved
      nt <- Ntip(t); done <- 0
      for (v in (nt + 1):(nt + t$Nnode)) { ch <- which(t$edge[, 1] == v)
        if (length(ch) == 2 && all(t$edge[ch, 2] <= nt) && done < 3) {
          L <- t$edge.length[ch[1]]; t$edge.length[ch] <- 0; pe <- which(t$edge[, 2] == v); t$edge.length[pe] <- t$edge.length[pe] + L; done <- done + 1 } }
      t }),
    routes = "phylo", struct_fams = fams)
add("d08a_A_near_singular_1e-9", aux = list(A = function(A) { A[2, ] <- A[1, ]; A[, 2] <- A[, 1]; A[2, 2] <- A[1, 1] + 1e-9; A }),
    routes = "animal", struct_fams = fams)
add("d08b_A_exactly_singular", aux = list(A = function(A) { A[2, ] <- A[1, ]; A[, 2] <- A[, 1]; A[2, 2] <- A[1, 1]; A }),
    routes = "animal", struct_fams = fams)
add("d09_x_constant_within_group", mod = function(d, fam, kind) { xg <- rnorm(G); d$x <- xg[match(d$g, ids)]; d })
add("d10_x_huge_1e6", mod = function(d, fam, kind) { d$x <- d$x * 1e6; d })
add("d11_x_tiny_1e-6", mod = function(d, fam, kind) { d$x <- d$x * 1e-6; d })
add("d12_sdpred_huge_1e6", mod = function(d, fam, kind) { d$z <- d$z * 1e6; d$z0 <- d$z0 * 1e6; d$z1 <- d$z1 * 1e6; d })
add("d13_sdpred_tiny_1e-6", mod = function(d, fam, kind) { d$z <- d$z * 1e-6; d$z0 <- d$z0 * 1e-6; d$z1 <- d$z1 * 1e-6; d })
add("d14_extreme_outliers", mod = function(d, fam, kind) {
      r <- c(5, 77, 150)
      d$y[r] <- switch(fam, gaussian = d$y[r] + 60, poisson = , nb2 = d$y[r] * 500 + 2000, gamma = d$y[r] * 1000, d$y[r]); d },
    fam_ok = noOut, struct_fams = c("gaussian", "poisson"))
add("d15a_missing_y_scattered", mod = function(d, fam, kind) { d$y[c(3, 20, 41, 66, 99, 150)] <- NA; d })
add("d15b_missing_y_whole_group", mod = function(d, fam, kind) { d$y[rows_of(d, "g05")] <- NA; d })
add("d16a_missing_sdpred_whole_group", mod = function(d, fam, kind) { r <- rows_of(d, "g06"); d$z[r] <- d$z0[r] <- d$z1[r] <- NA; d })
add("d16b_missing_sdpred_one_row", mod = function(d, fam, kind) { r <- rows_of(d, "g07")[2]; d$z[r] <- d$z0[r] <- d$z1[r] <- NA; d })
add("d17_unused_level_extra_kernel_members", aux = list(extra = 2L),
    note = "R: g is a factor with 2 unused levels; kernels carry 2 extra members. Julia: strings carry no unused levels, so only the kernel part applies")
add("d18_groups_missing_from_kernel", aux = list(drop = c("g23", "g24")), routes = c("animal", "phylo", "spatial"),
    struct_fams = c("gaussian", "poisson"))
add("d19_A_rownames_unsorted", aux = list(shuffle = TRUE), routes = "animal", struct_fams = c("gaussian", "poisson"))
add("d20_sdpred_varies_within_group", mod = function(d, fam, kind) { zz <- round(rnorm(nrow(d)), 4); d$z <- d$z0 <- zz; d$z1 <- rev(zz); d })
add("d21_A_unsorted_bare_matrix_positional", aux = list(shuffle = TRUE), routes = "animal", struct_fams = c("gaussian", "poisson"),
    note = "same construction as d19; Julia receives the matrix WITHOUT ids (positional contract)")
add("d07c_tree_not_ultrametric", aux = list(tree = function(t) {
      ie <- which(t$edge[, 2] > Ntip(t)); t$edge.length[ie[seq(1, length(ie), by = 2)]] <- 0; t }),
    routes = "phylo", struct_fams = c("gaussian", "poisson"))
add("d07d_tree_not_ultrametric_positive", aux = list(tree = function(t) {
      te <- which(t$edge[, 2] %in% c(3, 7, 12, 19)); t$edge.length[te] <- t$edge.length[te] + 0.7; t }),
    routes = "phylo", struct_fams = c("gaussian", "poisson"),
    note = "all branch lengths positive, tip heights differ (not ultrametric)")

# ---- write ------------------------------------------------------------------
w <- function(x, path, ...) write.table(x, path, sep = ",", row.names = FALSE, na = "NA", qmethod = "double", ...)
cells <- list()
for (s in ds) {
  dir <- file.path(RT, "cells", s$id); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  tr <- tree24; co <- coords24; A <- A24; extra <- 0L
  a <- s$aux
  if (!is.null(a$tree)) tr <- a$tree(tr)
  if (!is.null(a$coords)) co <- a$coords(co)
  if (!is.null(a$A)) A <- a$A(A)
  if (!is.null(a$extra)) {
    extra <- a$extra; ex <- sprintf("g%02d", G + seq_len(extra)); nn <- G + extra
    tr <- mk_tree(nn, c(ids, ex))
    co <- rbind(coords24, matrix(c(7, 7, 8, 8), ncol = 2, dimnames = list(ex, NULL)))
    colnames(co) <- NULL; rn <- c(ids, ex)
    Rr <- 0.4^abs(outer(1:nn, 1:nn, "-")); scc <- seq(0.7, 1.4, length.out = nn)
    A <- diag(scc) %*% Rr %*% diag(scc); dimnames(A) <- list(rn, rn)
    rownames(co) <- rn
  }
  if (!is.null(a$drop)) {
    keep <- setdiff(rownames(A), a$drop); A <- A[keep, keep]; co <- co[keep, , drop = FALSE]
    tr <- drop.tip(tr, a$drop)
  }
  if (isTRUE(a$shuffle)) { p <- sample(rownames(A)); A <- A[p, p]; co <- co[p, , drop = FALSE] }
  write.tree(tr, file.path(dir, "tree.nwk"))
  cc <- data.frame(id = rownames(co), easting = co[, 1], northing = co[, 2]); w(cc, file.path(dir, "coords.csv"))
  w(as.data.frame(A), file.path(dir, "A.csv")); writeLines(c("id", rownames(A)), file.path(dir, "A_ids.csv"))
  writeLines(sprintf('{"id":"%s","note":"%s","extra_levels":%d}', s$id, s$note, extra), file.path(dir, "meta.json"))
  for (k in kinds) for (f in fams) {
    d <- s$mod(base[[paste(k, f)]], f, k)
    if (is.null(d)) next
    w(d, file.path(dir, sprintf("data_%s_%s.csv", k, f)))
  }
  for (k in s$routes) {
    fl <- if (k %in% c("ord", "ordq2")) intersect(fams, s$fam_ok) else intersect(s$struct_fams, s$fam_ok)
    for (f in fl) cells[[length(cells) + 1]] <- data.frame(ds = s$id, route = k, fam = f)
  }
}
cells <- do.call(rbind, cells); cells$id <- sprintf("c%03d", seq_len(nrow(cells)))
write.table(cells[, c("id", "ds", "route", "fam")], file.path(RT, "cells.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
cat("cells:", nrow(cells), "\n"); print(table(cells$ds))
