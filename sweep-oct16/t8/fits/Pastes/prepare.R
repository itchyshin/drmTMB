chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(Pastes, package = "lme4")
d <- lme4::Pastes
d$batch <- chr_factor(d$batch)
d$cask <- chr_factor(d$cask)
d$sample <- chr_factor(d$sample)
