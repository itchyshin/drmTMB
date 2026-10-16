chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(GasolineYield, package = "betareg")
d <- GasolineYield
d$batch <- chr_factor(d$batch)
