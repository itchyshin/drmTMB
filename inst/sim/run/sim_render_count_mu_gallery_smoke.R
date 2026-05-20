phase18_render_count_mu_re_gallery_smoke <- function(
  output_dir,
  poisson_conditions = phase18_poisson_mu_re_conditions(
    n_group = 36L,
    n_per_group = 9L
  ),
  nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
    n_group = 44L,
    n_per_group = 10L
  ),
  n_rep = 1L,
  master_seed = 20260521L,
  notes = "Tiny paired count-pilot gallery smoke.",
  overwrite = FALSE,
  cores = 1L,
  backend = "none",
  template = system.file(
    "sim/reports/phase18-count-mu-gallery.Rmd",
    package = "drmTMB",
    mustWork = TRUE
  )
) {
  if (
    !is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)
  ) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  result_dir <- file.path(output_dir, "results")
  gallery_dir <- file.path(output_dir, "gallery")

  pilot <- phase18_summarise_count_mu_re_pilot(
    poisson_conditions = poisson_conditions,
    nbinom2_conditions = nbinom2_conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = cores,
    backend = backend
  )
  gallery <- phase18_render_count_mu_re_gallery(
    pilot = pilot,
    output_dir = gallery_dir,
    notes = notes,
    overwrite = overwrite,
    template = template
  )

  list(
    surface = "count_mu_random_effect_gallery_smoke",
    output_dir = output_dir,
    result_dir = result_dir,
    gallery_dir = gallery_dir,
    pilot = pilot,
    gallery = gallery
  )
}
