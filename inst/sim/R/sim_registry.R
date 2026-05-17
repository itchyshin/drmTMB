phase18_seed_table <- function(n_cells, n_rep, master_seed = 20260517L) {
  assert_positive_whole_number(n_cells, "n_cells")
  assert_positive_whole_number(n_rep, "n_rep")
  assert_positive_whole_number(master_seed, "master_seed")

  n_total <- n_cells * n_rep
  old_seed <- if (
    exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  ) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit(
    {
      if (is.null(old_seed)) {
        rm(list = ".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      }
    },
    add = TRUE
  )

  set.seed(master_seed)
  data.frame(
    cell_index = rep(seq_len(n_cells), each = n_rep),
    replicate = rep(seq_len(n_rep), times = n_cells),
    seed = sample.int(.Machine$integer.max, n_total),
    stringsAsFactors = FALSE
  )
}

phase18_cell_registry <- function(
  surface,
  conditions,
  n_rep,
  master_seed = 20260517L
) {
  if (!is.character(surface) || length(surface) != 1L || !nzchar(surface)) {
    stop("`surface` must be one non-empty character string.", call. = FALSE)
  }
  if (!is.data.frame(conditions) || nrow(conditions) == 0L) {
    stop("`conditions` must be a non-empty data frame.", call. = FALSE)
  }

  cells <- data.frame(
    cell_id = sprintf("%s_%03d", surface, seq_len(nrow(conditions))),
    surface = surface,
    conditions,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  seeds <- phase18_seed_table(nrow(cells), n_rep, master_seed)
  seeds$cell_id <- cells$cell_id[seeds$cell_index]
  seeds <- seeds[c("cell_id", "cell_index", "replicate", "seed")]

  list(
    cells = cells,
    seeds = seeds,
    n_rep = n_rep,
    master_seed = master_seed
  )
}

assert_positive_whole_number <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x == as.integer(x) &&
    x > 0
  if (!ok) {
    stop("`", name, "` must be one positive whole number.", call. = FALSE)
  }
  invisible(x)
}
