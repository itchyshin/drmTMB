chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(yates.oats, package = "agridat")
d <- agridat::yates.oats
d$gen <- chr_factor(d$gen)
d$block <- chr_factor(d$block)
