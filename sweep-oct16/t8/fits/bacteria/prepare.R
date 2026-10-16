chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(bacteria, package = "MASS")
d <- MASS::bacteria
d$y01 <- as.integer(d$y == "y")
d$week <- as.numeric(d$week)
d$trt <- chr_factor(d$trt)
d$ID <- chr_factor(d$ID)
